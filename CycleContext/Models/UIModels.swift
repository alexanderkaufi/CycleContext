import SwiftUI

enum CyclePhase: String, CaseIterable, Identifiable, Codable {
    case menstruation = "Menstruation"
    case follicular = "Follikelphase"
    case ovulation = "Eisprung"
    case luteal = "Lutealphase"

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .menstruation: return String(localized: "cycle.phase.menstruation")
        case .follicular: return String(localized: "cycle.phase.follicular")
        case .ovulation: return String(localized: "cycle.phase.ovulation")
        case .luteal: return String(localized: "cycle.phase.luteal")
        }
    }

    var tint: Color {
        switch self {
        case .menstruation: return .red
        case .follicular: return .green
        case .ovulation: return .blue
        case .luteal: return .orange
        }
    }

    var icon: String {
        switch self {
        case .menstruation: return "drop.fill"
        case .follicular: return "sparkles"
        case .ovulation: return "bolt.heart.fill"
        case .luteal: return "moon.fill"
        }
    }

    var correctionLabel: String {
        localizedTitle
    }
}

enum CycleValueSource: String, Codable {
    case demo
    case generalDefault
    case userProvided
    case personalHistory
    case manualCorrection

    var localizedTitle: String {
        switch self {
        case .demo: return String(localized: "cycle.valueSource.demo")
        case .generalDefault: return String(localized: "cycle.valueSource.generalDefault")
        case .userProvided: return String(localized: "cycle.valueSource.userProvided")
        case .personalHistory: return String(localized: "cycle.valueSource.personalHistory")
        case .manualCorrection: return String(localized: "cycle.valueSource.manualCorrection")
        }
    }
}

struct PeriodStartEvent: Identifiable, Equatable, Codable {
    var id: UUID = UUID()
    var date: Date
}

struct ManualCycleOverride: Equatable, Codable {
    var referenceDate: Date
    var phase: CyclePhase
    var dayInPhase: Int
}

struct ProfilePreview: Identifiable, Equatable, Codable {
    var id: UUID
    var displayName: String
    var emoji: String
    var avatarIcon: String
    var cycleDay: Int
    var cycleLength: Int
    var periodLength: Int
    var phase: CyclePhase
    var lastPeriodStart: Date
    var periodStartHistory: [Date]
    var cycleLengthSource: CycleValueSource
    var periodLengthSource: CycleValueSource
    var periodStarts: [PeriodStartEvent]
    var manualCycleOverride: ManualCycleOverride?
    var isTemplateProfile: Bool

    var latestConfirmedPeriodStart: Date? {
        periodStarts.map(\.date).max()
    }

    var usesExampleTiming: Bool {
        periodStarts.isEmpty && manualCycleOverride == nil
    }

    init(
        id: UUID = UUID(),
        displayName: String,
        emoji: String,
        avatarIcon: String = "person.fill",
        cycleDay: Int,
        cycleLength: Int,
        periodLength: Int = 5,
        phase: CyclePhase,
        lastPeriodStart: Date? = nil,
        periodStartHistory: [Date] = [],
        cycleLengthSource: CycleValueSource = .generalDefault,
        periodLengthSource: CycleValueSource = .generalDefault,
        periodStarts: [PeriodStartEvent] = [],
        manualCycleOverride: ManualCycleOverride? = nil,
        isTemplateProfile: Bool = false
    ) {
        self.id = id
        self.displayName = displayName
        self.emoji = emoji
        self.avatarIcon = avatarIcon
        self.cycleDay = cycleDay
        self.cycleLength = cycleLength
        self.periodLength = periodLength
        self.phase = phase
        self.lastPeriodStart = lastPeriodStart
            ?? Calendar.current.date(byAdding: .day, value: -(cycleDay - 1), to: Date())
            ?? Date()
        self.periodStartHistory = periodStartHistory
        self.cycleLengthSource = cycleLengthSource
        self.periodLengthSource = periodLengthSource
        self.periodStarts = periodStarts
        self.manualCycleOverride = manualCycleOverride
        self.isTemplateProfile = isTemplateProfile
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case displayName
        case emoji
        case avatarIcon
        case cycleDay
        case cycleLength
        case periodLength
        case phase
        case lastPeriodStart
        case periodStartHistory
        case cycleLengthSource
        case periodLengthSource
        case periodStarts
        case manualCycleOverride
        case isTemplateProfile
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        displayName = try container.decode(String.self, forKey: .displayName)
        emoji = try container.decodeIfPresent(String.self, forKey: .emoji) ?? String(displayName.prefix(1)).uppercased()
        avatarIcon = try container.decodeIfPresent(String.self, forKey: .avatarIcon) ?? "person.fill"
        cycleDay = try container.decodeIfPresent(Int.self, forKey: .cycleDay) ?? 1
        cycleLength = try container.decodeIfPresent(Int.self, forKey: .cycleLength) ?? 28
        periodLength = try container.decodeIfPresent(Int.self, forKey: .periodLength) ?? 5
        phase = try container.decodeIfPresent(CyclePhase.self, forKey: .phase) ?? .menstruation
        lastPeriodStart = try container.decodeIfPresent(Date.self, forKey: .lastPeriodStart)
            ?? Calendar.current.date(byAdding: .day, value: -(cycleDay - 1), to: Date())
            ?? Date()
        periodStartHistory = try container.decodeIfPresent([Date].self, forKey: .periodStartHistory) ?? []
        cycleLengthSource = try container.decodeIfPresent(CycleValueSource.self, forKey: .cycleLengthSource)
            ?? .userProvided
        periodLengthSource = try container.decodeIfPresent(CycleValueSource.self, forKey: .periodLengthSource)
            ?? .userProvided
        manualCycleOverride = try container.decodeIfPresent(ManualCycleOverride.self, forKey: .manualCycleOverride)
        isTemplateProfile = try container.decodeIfPresent(Bool.self, forKey: .isTemplateProfile) ?? false

        if let decodedStarts = try container.decodeIfPresent([PeriodStartEvent].self, forKey: .periodStarts) {
            periodStarts = decodedStarts
        } else {
            var seen = Set<Date>()
            periodStarts = (periodStartHistory + [lastPeriodStart]).compactMap { date in
                let normalizedDate = Calendar.current.startOfDay(for: date)
                guard seen.insert(normalizedDate).inserted else { return nil }
                return PeriodStartEvent(date: normalizedDate)
            }
        }
    }
}

struct AdviceCard: Identifiable {
    let id = UUID()
    var title: String
    var subtitle: String
    var icon: String
    var tint: Color
}

struct CalendarDay: Identifiable {
    var id: Date { date }
    var date: Date
    var number: Int
    var cycleDay: Int
    var phase: CyclePhase
    var section: CycleSection
    var isToday: Bool = false
    var hasEntry: Bool = false
    var isConfirmedPeriodStart: Bool = false
}

enum BleedingLevel: String, CaseIterable, Identifiable, Codable {
    case none
    case light
    case medium
    case heavy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: return String(localized: "entry.level.none")
        case .light: return String(localized: "entry.level.light")
        case .medium: return String(localized: "entry.level.medium")
        case .heavy: return String(localized: "entry.level.heavy")
        }
    }
}

enum PainLevel: String, CaseIterable, Identifiable, Codable {
    case none
    case mild
    case moderate
    case strong

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: return String(localized: "entry.level.none")
        case .mild: return String(localized: "entry.level.light")
        case .moderate: return String(localized: "entry.level.medium")
        case .strong: return String(localized: "entry.level.strong")
        }
    }
}

enum DailyEnergyLevel: String, CaseIterable, Identifiable, Codable {
    case low
    case medium
    case high

    var id: String { rawValue }

    var title: String {
        switch self {
        case .low: return String(localized: "entry.energy.low")
        case .medium: return String(localized: "entry.energy.medium")
        case .high: return String(localized: "entry.energy.high")
        }
    }
}

struct WellbeingSnapshot: Equatable, Codable {
    var bleeding: BleedingLevel?
    var pain: PainLevel?
    var energy: DailyEnergyLevel?
    var supportNeed: String

    var isEmpty: Bool {
        bleeding == nil
            && pain == nil
            && energy == nil
            && supportNeed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var summary: String {
        var values: [String] = []
        if let bleeding {
            values.append(String(
                format: String(localized: "entry.summary.bleeding.format"),
                locale: .current,
                bleeding.title
            ))
        }
        if let pain {
            values.append(String(
                format: String(localized: "entry.summary.pain.format"),
                locale: .current,
                pain.title
            ))
        }
        if let energy {
            values.append(String(
                format: String(localized: "entry.summary.energy.format"),
                locale: .current,
                energy.title
            ))
        }
        return values.joined(separator: " · ")
    }
}

struct EntryPreview: Identifiable, Equatable, Codable {
    var id: UUID = UUID()
    var profileID: UUID
    var title: String
    var date: Date
    var note: String
    var phase: CyclePhase
    var wellbeing: WellbeingSnapshot? = nil
    var isDemo: Bool = false

    private enum CodingKeys: String, CodingKey {
        case id
        case profileID
        case title
        case date
        case note
        case phase
        case wellbeing
        case isDemo
    }

    init(
        id: UUID = UUID(),
        profileID: UUID,
        title: String,
        date: Date,
        note: String,
        phase: CyclePhase,
        wellbeing: WellbeingSnapshot? = nil,
        isDemo: Bool = false
    ) {
        self.id = id
        self.profileID = profileID
        self.title = title
        self.date = date
        self.note = note
        self.phase = phase
        self.wellbeing = wellbeing
        self.isDemo = isDemo
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        profileID = try container.decode(UUID.self, forKey: .profileID)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
        phase = try container.decodeIfPresent(CyclePhase.self, forKey: .phase) ?? .menstruation
        wellbeing = try container.decodeIfPresent(WellbeingSnapshot.self, forKey: .wellbeing)
        isDemo = try container.decodeIfPresent(Bool.self, forKey: .isDemo) ?? false
    }
}
