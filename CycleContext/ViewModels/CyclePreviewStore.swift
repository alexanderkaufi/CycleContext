import Foundation
import SwiftUI
import Combine

private struct StoredCycleData: Codable {
    var schemaVersion: Int
    var profiles: [ProfilePreview]
    var entries: [EntryPreview]
    var activeProfileID: UUID?
}

@MainActor
final class CyclePreviewStore: ObservableObject {
    private let schemaVersion = 4
    private let legacyProfilesKey = "cyclecontext.profiles"
    private let legacyActiveProfileIDKey = "cyclecontext.activeProfileID"
    private let storageFileName = "cyclecontext-data.json"

    @Published var selectedTab: AppTab = .overview
    @Published var activeProfile: ProfilePreview
    @Published var profiles: [ProfilePreview]
    @Published var entries: [EntryPreview]

    init() {
        let defaults = Self.makeDefaultProfiles()
        profiles = defaults
        activeProfile = defaults[0]
        entries = Self.makeDemoEntries(for: defaults[0])

        loadStoredData()
        refreshProfiles(for: Date())
        for profile in profiles {
            updateEntryPhases(for: profile)
        }
        saveStoredData()
    }

    var activeEntries: [EntryPreview] {
        entries(for: activeProfile.id)
    }

    var activePersonalEntries: [EntryPreview] {
        personalEntries(for: activeProfile.id)
    }

    func addProfile(
        named name: String,
        lastPeriodStart: Date?,
        cycleLength: Int,
        periodLength: Int
    ) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let normalizedCycleLength = min(max(cycleLength, 21), 45)
        let normalizedPeriodLength = min(max(periodLength, 1), min(10, normalizedCycleLength))
        let today = startOfDay(Date())
        let normalizedStart = lastPeriodStart.map(startOfDay)
            ?? Calendar.current.date(byAdding: .day, value: -23, to: today)
            ?? today
        let initial = trimmedName.first.map { String($0).uppercased() } ?? "?"
        var profile = ProfilePreview(
            displayName: trimmedName,
            emoji: initial,
            avatarIcon: "person.fill",
            cycleDay: 1,
            cycleLength: normalizedCycleLength,
            periodLength: normalizedPeriodLength,
            phase: .menstruation,
            lastPeriodStart: normalizedStart,
            cycleLengthSource: normalizedCycleLength == 28 ? .generalDefault : .userProvided,
            periodLengthSource: normalizedPeriodLength == 5 ? .generalDefault : .userProvided,
            periodStarts: lastPeriodStart == nil ? [] : [PeriodStartEvent(date: normalizedStart)]
        )
        profile = status(for: profile, on: Date())

        profiles.append(profile)
        activeProfile = profile
        saveStoredData()
    }

    func deleteProfile(_ profile: ProfilePreview) {
        guard profiles.count > 1 else { return }

        profiles.removeAll { $0.id == profile.id }
        entries.removeAll { $0.profileID == profile.id }

        if activeProfile.id == profile.id, let nextProfile = profiles.first {
            activeProfile = nextProfile
        }

        saveStoredData()
    }

    func saveProfile(_ profile: ProfilePreview) {
        guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else { return }

        let trimmedName = profile.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let storedProfile = profiles[index]
        var updatedProfile = profile
        updatedProfile.displayName = trimmedName
        updatedProfile.emoji = profile.emoji.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? String(trimmedName.prefix(1)).uppercased()
            : String(profile.emoji.trimmingCharacters(in: .whitespacesAndNewlines).prefix(2))
        updatedProfile.cycleLength = min(max(profile.cycleLength, 21), 45)
        updatedProfile.periodLength = min(max(profile.periodLength, 1), min(10, updatedProfile.cycleLength))
        if updatedProfile.cycleLength != storedProfile.cycleLength {
            updatedProfile.cycleLengthSource = updatedProfile.cycleLength == 28 ? .generalDefault : .userProvided
        }
        if updatedProfile.periodLength != storedProfile.periodLength {
            updatedProfile.periodLengthSource = updatedProfile.periodLength == 5 ? .generalDefault : .userProvided
        }
        if let confirmedStart = updatedProfile.latestConfirmedPeriodStart {
            updatedProfile.lastPeriodStart = startOfDay(confirmedStart)
        } else {
            updatedProfile.lastPeriodStart = startOfDay(profile.lastPeriodStart)
        }
        updatedProfile.isTemplateProfile = false
        updatedProfile = status(for: updatedProfile, on: Date())

        profiles[index] = updatedProfile
        entries.removeAll { $0.profileID == profile.id && $0.isDemo }
        updateEntryPhases(for: updatedProfile)

        if activeProfile.id == updatedProfile.id {
            activeProfile = updatedProfile
        }

        saveStoredData()
    }

    func selectProfile(_ profile: ProfilePreview) {
        guard let storedProfile = profiles.first(where: { $0.id == profile.id }) else { return }
        activeProfile = status(for: storedProfile, on: Date())
        saveStoredData()
    }

    func updateCycleStatus(for profile: ProfilePreview, phase: CyclePhase, dayInPhase: Int, cycleLength: Int) {
        guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else { return }

        let normalizedCycleLength = min(max(cycleLength, 21), 45)
        let phaseLength = max(
            1,
            effectiveLength(
                for: phase,
                cycleLength: normalizedCycleLength,
                periodLength: profile.periodLength
            )
        )
        let normalizedDayInPhase = min(max(dayInPhase, 1), phaseLength)
        let cycleDay = min(
            phaseStartDay(
                for: phase,
                cycleLength: normalizedCycleLength,
                periodLength: profile.periodLength
            ) + normalizedDayInPhase - 1,
            normalizedCycleLength
        )
        let newPeriodStart = Calendar.current.date(
            byAdding: .day,
            value: -(cycleDay - 1),
            to: startOfDay(Date())
        ) ?? startOfDay(Date())

        var updatedProfile = profiles[index]
        updatedProfile.cycleLength = normalizedCycleLength
        updatedProfile.cycleLengthSource = .manualCorrection
        updatedProfile.lastPeriodStart = newPeriodStart
        updatedProfile.manualCycleOverride = ManualCycleOverride(
            referenceDate: startOfDay(Date()),
            phase: phase,
            dayInPhase: normalizedDayInPhase
        )
        updatedProfile.isTemplateProfile = false
        updatedProfile.cycleDay = cycleDay
        updatedProfile.phase = self.phase(
            for: cycleDay,
            cycleLength: normalizedCycleLength,
            periodLength: updatedProfile.periodLength
        )
        profiles[index] = updatedProfile
        entries.removeAll { $0.profileID == profile.id && $0.isDemo }
        updateEntryPhases(for: updatedProfile)

        if activeProfile.id == profile.id {
            activeProfile = updatedProfile
        }

        saveStoredData()
    }

    func confirmPeriodStart(for profile: ProfilePreview, on date: Date) {
        guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else { return }

        let normalizedDate = min(startOfDay(date), startOfDay(Date()))
        var updatedProfile = profiles[index]
        if !updatedProfile.periodStarts.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: normalizedDate) }) {
            updatedProfile.periodStarts.append(PeriodStartEvent(date: normalizedDate))
        }
        updatedProfile.periodStarts.sort { $0.date < $1.date }
        updatedProfile.manualCycleOverride = nil
        updatedProfile.isTemplateProfile = false
        syncLegacyPeriodDates(for: &updatedProfile)
        updatedProfile = status(for: updatedProfile, on: Date())

        profiles[index] = updatedProfile
        entries.removeAll { $0.profileID == profile.id && $0.isDemo }
        updateEntryPhases(for: updatedProfile)

        if activeProfile.id == profile.id {
            activeProfile = updatedProfile
        }

        saveStoredData()
    }

    func addEntry(
        title: String,
        note: String,
        date: Date,
        wellbeing: WellbeingSnapshot? = nil
    ) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedWellbeing = wellbeing?.isEmpty == false ? wellbeing : nil
        guard !trimmedTitle.isEmpty || !trimmedNote.isEmpty || normalizedWellbeing != nil else { return }

        makeProfilePersistent(activeProfile.id)
        entries.removeAll { $0.profileID == activeProfile.id && $0.isDemo }

        let normalizedDate = startOfDay(date)
        entries.append(EntryPreview(
            profileID: activeProfile.id,
            title: trimmedTitle,
            date: normalizedDate,
            note: trimmedNote,
            phase: phase(
                for: projectedCycleDay(for: activeProfile, on: normalizedDate),
                cycleLength: activeProfile.cycleLength,
                periodLength: activeProfile.periodLength
            ),
            wellbeing: normalizedWellbeing
        ))
        saveStoredData()
    }

    func saveEntry(
        _ entry: EntryPreview,
        title: String,
        note: String,
        date: Date,
        wellbeing: WellbeingSnapshot? = nil
    ) {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedWellbeing = wellbeing?.isEmpty == false ? wellbeing : nil
        guard !trimmedTitle.isEmpty || !trimmedNote.isEmpty || normalizedWellbeing != nil else { return }

        let profile = profiles.first(where: { $0.id == entry.profileID }) ?? activeProfile
        let normalizedDate = startOfDay(date)
        makeProfilePersistent(profile.id)
        entries[index].title = trimmedTitle
        entries[index].note = trimmedNote
        entries[index].date = normalizedDate
        entries[index].wellbeing = normalizedWellbeing
        entries[index].isDemo = false
        entries[index].phase = phase(
            for: projectedCycleDay(for: profile, on: normalizedDate),
            cycleLength: profile.cycleLength,
            periodLength: profile.periodLength
        )
        saveStoredData()
    }

    func deleteEntry(_ entry: EntryPreview) {
        entries.removeAll { $0.id == entry.id && $0.profileID == entry.profileID }
        saveStoredData()
    }

    func entries(for profileID: UUID) -> [EntryPreview] {
        entries
            .filter { $0.profileID == profileID }
            .sorted { $0.date > $1.date }
    }

    func entries(for profileID: UUID, on date: Date) -> [EntryPreview] {
        entries(for: profileID).filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    func personalEntries(for profileID: UUID) -> [EntryPreview] {
        entries(for: profileID).filter { !$0.isDemo }
    }

    func calendarDays(in month: Date) -> [CalendarDay] {
        guard
            let monthInterval = Calendar.current.dateInterval(of: .month, for: month),
            let dayRange = Calendar.current.range(of: .day, in: .month, for: month)
        else {
            return []
        }

        return dayRange.compactMap { dayNumber in
            guard let date = Calendar.current.date(byAdding: .day, value: dayNumber - 1, to: monthInterval.start) else {
                return nil
            }
            let day = projectedCycleDay(for: activeProfile, on: date)
            return CalendarDay(
                date: date,
                number: dayNumber,
                cycleDay: day,
                phase: phase(
                    for: day,
                    cycleLength: activeProfile.cycleLength,
                    periodLength: activeProfile.periodLength
                ),
                section: section(
                    for: day,
                    cycleLength: activeProfile.cycleLength,
                    periodLength: activeProfile.periodLength
                ),
                isToday: Calendar.current.isDateInToday(date),
                hasEntry: !entries(for: activeProfile.id, on: date).isEmpty,
                isConfirmedPeriodStart: activeProfile.periodStarts.contains {
                    Calendar.current.isDate($0.date, inSameDayAs: date)
                }
            )
        }
    }

    func observedCycleDay(for profile: ProfilePreview, on date: Date) -> Int? {
        let selectedDate = startOfDay(date)

        if
            let override = profile.manualCycleOverride,
            selectedDate >= startOfDay(override.referenceDate)
        {
            let baseDay = phaseStartDay(
                for: override.phase,
                cycleLength: profile.cycleLength,
                periodLength: profile.periodLength
            ) + max(override.dayInPhase, 1) - 1
            let difference = Calendar.current.dateComponents(
                [.day],
                from: startOfDay(override.referenceDate),
                to: selectedDate
            ).day ?? 0
            return baseDay + difference
        }

        let confirmedStart = profile.periodStarts
            .map(\.date)
            .filter { startOfDay($0) <= selectedDate }
            .max()
        guard let confirmedStart else { return nil }

        let difference = Calendar.current.dateComponents(
            [.day],
            from: startOfDay(confirmedStart),
            to: selectedDate
        ).day ?? 0
        return difference + 1
    }

    func projectedCycleDay(for profile: ProfilePreview, on date: Date) -> Int {
        let calendar = Calendar.current
        let selectedDate = startOfDay(date)
        let referenceDate: Date
        let referenceCycleDay: Int

        if let override = profile.manualCycleOverride {
            referenceDate = startOfDay(override.referenceDate)
            referenceCycleDay = phaseStartDay(
                for: override.phase,
                cycleLength: profile.cycleLength,
                periodLength: profile.periodLength
            ) + max(override.dayInPhase, 1) - 1
        } else {
            referenceDate = startOfDay(profile.lastPeriodStart)
            referenceCycleDay = 1
        }

        let difference = calendar.dateComponents([.day], from: referenceDate, to: selectedDate).day ?? 0
        let length = max(profile.cycleLength, 1)
        let offset = (((referenceCycleDay - 1 + difference) % length) + length) % length
        return offset + 1
    }

    func phase(for cycleDay: Int, cycleLength: Int, periodLength: Int = 5) -> CyclePhase {
        let normalizedCycleDay = min(max(cycleDay, 1), max(cycleLength, 1))
        let ovulationDay = max(min(periodLength + 1, cycleLength), cycleLength - 14)

        if normalizedCycleDay <= min(periodLength, cycleLength) {
            return .menstruation
        } else if normalizedCycleDay < ovulationDay {
            return .follicular
        } else if normalizedCycleDay == ovulationDay {
            return .ovulation
        } else {
            return .luteal
        }
    }

    func section(for cycleDay: Int, cycleLength: Int, periodLength: Int = 5) -> CycleSection {
        let normalizedDay = min(max(cycleDay, 1), max(cycleLength, 1))

        for section in CycleSection.allCases {
            let start = sectionStartDay(
                for: section,
                cycleLength: cycleLength,
                periodLength: periodLength
            )
            let length = effectiveLength(
                for: section,
                cycleLength: cycleLength,
                periodLength: periodLength
            )
            if length > 0, normalizedDay >= start, normalizedDay < start + length {
                return section
            }
        }

        return .premenstrual
    }

    func section(for profile: ProfilePreview) -> CycleSection {
        section(
            for: profile.cycleDay,
            cycleLength: profile.cycleLength,
            periodLength: profile.periodLength
        )
    }

    func confidence(for profile: ProfilePreview, on date: Date) -> CycleEstimateConfidence {
        if profile.usesExampleTiming {
            return .demo
        }
        if isTimingOverdue(for: profile, on: date), !isFutureDate(date) {
            return .unclear
        }
        if profile.manualCycleOverride != nil {
            return .manualCorrection
        }
        if profile.periodStarts.isEmpty {
            return profile.usesExampleTiming ? .demo : .generalOrientation
        }
        if recordedCycleLengths(for: profile).count >= 2 {
            return .personalEstimate
        }
        return .confirmedPeriod
    }

    func isTimingOverdue(for profile: ProfilePreview, on date: Date) -> Bool {
        guard !profile.usesExampleTiming, let observedDay = observedCycleDay(for: profile, on: date) else {
            return false
        }
        return observedDay > profile.cycleLength
    }

    func hasWellbeingEntry(for profile: ProfilePreview, on date: Date) -> Bool {
        personalEntries(for: profile.id).contains { entry in
            entry.wellbeing != nil && Calendar.current.isDate(entry.date, inSameDayAs: date)
        }
    }

    func sectionStartDay(for section: CycleSection, cycleLength: Int, periodLength: Int) -> Int {
        let bounds = sectionBounds(cycleLength: cycleLength, periodLength: periodLength)
        switch section {
        case .menstruation: return bounds.periodStart
        case .building: return bounds.buildingStart
        case .ovulationWindow: return bounds.ovulationWindowStart
        case .luteal: return bounds.lutealStart
        case .premenstrual: return bounds.premenstrualStart
        }
    }

    func effectiveLength(for section: CycleSection, cycleLength: Int, periodLength: Int = 5) -> Int {
        let bounds = sectionBounds(cycleLength: cycleLength, periodLength: periodLength)
        switch section {
        case .menstruation:
            return max(0, bounds.periodEnd - bounds.periodStart + 1)
        case .building:
            return max(0, bounds.buildingEnd - bounds.buildingStart + 1)
        case .ovulationWindow:
            return max(0, bounds.ovulationWindowEnd - bounds.ovulationWindowStart + 1)
        case .luteal:
            return max(0, bounds.lutealEnd - bounds.lutealStart + 1)
        case .premenstrual:
            return max(0, bounds.cycleEnd - bounds.premenstrualStart + 1)
        }
    }

    func phaseStartDay(for phase: CyclePhase, cycleLength: Int, periodLength: Int) -> Int {
        let ovulationDay = max(min(periodLength + 1, cycleLength), cycleLength - 14)
        switch phase {
        case .menstruation: return 1
        case .follicular: return min(periodLength + 1, cycleLength)
        case .ovulation: return ovulationDay
        case .luteal: return min(ovulationDay + 1, cycleLength)
        }
    }

    func effectiveLength(for phase: CyclePhase, cycleLength: Int, periodLength: Int = 5) -> Int {
        let ovulationDay = max(min(periodLength + 1, cycleLength), cycleLength - 14)
        switch phase {
        case .menstruation:
            return min(periodLength, cycleLength)
        case .follicular:
            return max(0, ovulationDay - periodLength - 1)
        case .ovulation:
            return 1
        case .luteal:
            return max(0, cycleLength - ovulationDay)
        }
    }

    private func sectionBounds(cycleLength: Int, periodLength: Int) -> (
        periodStart: Int,
        periodEnd: Int,
        buildingStart: Int,
        buildingEnd: Int,
        ovulationWindowStart: Int,
        ovulationWindowEnd: Int,
        lutealStart: Int,
        lutealEnd: Int,
        premenstrualStart: Int,
        cycleEnd: Int
    ) {
        let length = max(cycleLength, 1)
        let periodEnd = min(max(periodLength, 1), length)
        let ovulationDay = max(min(periodEnd + 1, length), length - 14)
        let ovulationWindowStart = max(periodEnd + 1, ovulationDay - 1)
        let ovulationWindowEnd = min(length, ovulationDay + 1)
        let premenstrualStart = max(ovulationWindowEnd + 1, length - 4)

        return (
            periodStart: 1,
            periodEnd: periodEnd,
            buildingStart: min(periodEnd + 1, length),
            buildingEnd: ovulationWindowStart - 1,
            ovulationWindowStart: ovulationWindowStart,
            ovulationWindowEnd: ovulationWindowEnd,
            lutealStart: min(ovulationWindowEnd + 1, length),
            lutealEnd: premenstrualStart - 1,
            premenstrualStart: min(premenstrualStart, length),
            cycleEnd: length
        )
    }

    func recordedCycleLengths(for profile: ProfilePreview) -> [Int] {
        let dates = uniqueDates(profile.periodStarts.map(\.date)).sorted()
        guard dates.count > 1 else { return [] }

        return zip(dates, dates.dropFirst()).compactMap { start, end in
            let days = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
            return (15...60).contains(days) ? days : nil
        }
    }

    private func status(for profile: ProfilePreview, on date: Date) -> ProfilePreview {
        var updatedProfile = profile
        updatedProfile.lastPeriodStart = startOfDay(profile.lastPeriodStart)
        let calculatedDay = observedCycleDay(for: updatedProfile, on: date)
            ?? projectedCycleDay(for: updatedProfile, on: date)
        updatedProfile.cycleDay = min(max(calculatedDay, 1), max(updatedProfile.cycleLength, 1))
        updatedProfile.phase = phase(
            for: updatedProfile.cycleDay,
            cycleLength: updatedProfile.cycleLength,
            periodLength: updatedProfile.periodLength
        )
        return updatedProfile
    }

    private func refreshProfiles(for date: Date) {
        profiles = profiles.map { status(for: $0, on: date) }
        if let refreshedActive = profiles.first(where: { $0.id == activeProfile.id }) {
            activeProfile = refreshedActive
        } else if let firstProfile = profiles.first {
            activeProfile = firstProfile
        }
    }

    private func updateEntryPhases(for profile: ProfilePreview) {
        for index in entries.indices where entries[index].profileID == profile.id {
            let day = projectedCycleDay(for: profile, on: entries[index].date)
            entries[index].phase = phase(
                for: day,
                cycleLength: profile.cycleLength,
                periodLength: profile.periodLength
            )
        }
    }

    private func uniqueDates(_ dates: [Date]) -> [Date] {
        var seen = Set<Date>()
        return dates.compactMap { date in
            let normalizedDate = startOfDay(date)
            return seen.insert(normalizedDate).inserted ? normalizedDate : nil
        }
    }

    private func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    private func isFutureDate(_ date: Date) -> Bool {
        startOfDay(date) > startOfDay(Date())
    }

    private func makeProfilePersistent(_ profileID: UUID) {
        guard let index = profiles.firstIndex(where: { $0.id == profileID }) else { return }
        profiles[index].isTemplateProfile = false
        if activeProfile.id == profileID {
            activeProfile = profiles[index]
        }
    }

    private func syncLegacyPeriodDates(for profile: inout ProfilePreview) {
        let dates = uniqueDates(profile.periodStarts.map(\.date)).sorted()
        guard let latest = dates.last else { return }
        profile.lastPeriodStart = latest
        profile.periodStartHistory = Array(dates.dropLast())
    }

    private var storageURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("CycleContext", isDirectory: true)
            .appendingPathComponent(storageFileName)
    }

    private func loadStoredData() {
        if
            let storageURL,
            let data = try? Data(contentsOf: storageURL),
            let storedData = try? JSONDecoder().decode(StoredCycleData.self, from: data),
            !storedData.profiles.isEmpty
        {
            profiles = storedData.profiles
            entries = storedData.entries
            activeProfile = storedData.activeProfileID
                .flatMap { id in storedData.profiles.first(where: { $0.id == id }) }
                ?? storedData.profiles[0]
            return
        }

        guard
            let legacyData = UserDefaults.standard.data(forKey: legacyProfilesKey),
            let legacyProfiles = try? JSONDecoder().decode([ProfilePreview].self, from: legacyData),
            !legacyProfiles.isEmpty
        else {
            return
        }

        profiles = legacyProfiles
        entries = []

        if
            let activeIDString = UserDefaults.standard.string(forKey: legacyActiveProfileIDKey),
            let activeID = UUID(uuidString: activeIDString),
            let legacyActiveProfile = legacyProfiles.first(where: { $0.id == activeID })
        {
            activeProfile = legacyActiveProfile
        } else {
            activeProfile = legacyProfiles[0]
        }
    }

    private func saveStoredData() {
        guard let storageURL else { return }

        do {
            let persistedProfiles = profiles.filter { !$0.isTemplateProfile }
            let persistedProfileIDs = Set(persistedProfiles.map(\.id))
            let persistedEntries = entries.filter {
                !$0.isDemo && persistedProfileIDs.contains($0.profileID)
            }
            try FileManager.default.createDirectory(
                at: storageURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(StoredCycleData(
                schemaVersion: schemaVersion,
                profiles: persistedProfiles,
                entries: persistedEntries,
                activeProfileID: persistedProfileIDs.contains(activeProfile.id) ? activeProfile.id : nil
            ))
            try data.write(to: storageURL, options: .atomic)
        } catch {
            assertionFailure("Lokale Zyklusdaten konnten nicht gespeichert werden: \(error.localizedDescription)")
        }
    }

    private static func makeDefaultProfiles() -> [ProfilePreview] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let firstStart = calendar.date(byAdding: .day, value: -23, to: today) ?? today

        return [
            ProfilePreview(
                displayName: String(localized: "profile.template.name"),
                emoji: "",
                avatarIcon: "person.fill",
                cycleDay: 24,
                cycleLength: 28,
                periodLength: 5,
                phase: .luteal,
                lastPeriodStart: firstStart,
                cycleLengthSource: .generalDefault,
                periodLengthSource: .generalDefault,
                periodStarts: [],
                isTemplateProfile: true
            )
        ]
    }

    private static func makeDemoEntries(for profile: ProfilePreview) -> [EntryPreview] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return [
            EntryPreview(
                profileID: profile.id,
                title: String(localized: "entry.demo.pms.title"),
                date: today,
                note: String(localized: "entry.demo.pms.note"),
                phase: .luteal,
                isDemo: true
            ),
            EntryPreview(
                profileID: profile.id,
                title: String(localized: "entry.demo.care.title"),
                date: calendar.date(byAdding: .day, value: -5, to: today) ?? today,
                note: String(localized: "entry.demo.care.note"),
                phase: .luteal,
                isDemo: true
            )
        ]
    }
}

enum AppTab: String, CaseIterable, Identifiable {
    case overview = "Heute"
    case cycleOverview = "Zyklus"
    case calendar = "Kalender"
    case entries = "Einträge"
    case settings = "Einstellungen"

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .overview: return String(localized: "tab.today")
        case .cycleOverview: return String(localized: "tab.cycle")
        case .calendar: return String(localized: "tab.calendar")
        case .entries: return String(localized: "tab.entries")
        case .settings: return String(localized: "tab.settings")
        }
    }

    var icon: String {
        switch self {
        case .overview: return "house.fill"
        case .cycleOverview: return "chart.pie.fill"
        case .calendar: return "calendar"
        case .entries: return "list.bullet.rectangle.fill"
        case .settings: return "gearshape.fill"
        }
    }
}
