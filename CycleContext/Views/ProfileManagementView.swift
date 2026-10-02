import SwiftUI

struct ProfileManagementView: View {
    @EnvironmentObject private var store: CyclePreviewStore
    @Environment(\.dismiss) private var dismiss
    @State private var isAddingProfile = false
    @State private var editingProfile: ProfilePreview?
    @State private var profilePendingDeletion: ProfilePreview?
    @State private var newProfileName = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(store.profiles) { profile in
                        VStack(alignment: .leading, spacing: 0) {
                            Button {
                                store.selectProfile(profile)
                            } label: {
                                ProfileListRow(
                                    profile: profile,
                                    isActive: profile.id == store.activeProfile.id
                                )
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Button {
                                editingProfile = profile
                            } label: {
                                Label("profile.edit.nameAndCycle", systemImage: "pencil")
                                    .font(.subheadline.weight(.semibold))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                    .padding(.leading, 50)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel(editAccessibilityLabel(for: profile))
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                profilePendingDeletion = profile
                            } label: {
                                Label("common.delete", systemImage: "trash.fill")
                            }
                            .tint(.red)
                            .disabled(store.profiles.count <= 1)
                        }
                    }
                } header: {
                    Text("profiles.people")
                } footer: {
                    Text("profiles.swipeHint")
                }

            }
            .navigationTitle(String(localized: "profiles.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        isAddingProfile = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityLabel(Text("profile.add.title"))
                }
            }
            .sheet(isPresented: $isAddingProfile) {
                AddProfileView(newProfileName: $newProfileName) { lastPeriodStart, cycleLength, periodLength in
                    store.addProfile(
                        named: newProfileName,
                        lastPeriodStart: lastPeriodStart,
                        cycleLength: cycleLength,
                        periodLength: periodLength
                    )
                    newProfileName = ""
                }
            }
            .sheet(item: $editingProfile) { profile in
                ProfileEditView(profile: profile)
            }
            .alert(item: $profilePendingDeletion) { profile in
                Alert(
                    title: Text(deletionTitle(for: profile)),
                    message: Text("profile.delete.message"),
                    primaryButton: .destructive(Text("profile.delete.action")) {
                        store.deleteProfile(profile)
                    },
                    secondaryButton: .cancel(Text("common.cancel"))
                )
            }
        }
    }

    private func deletionTitle(for profile: ProfilePreview) -> String {
        String(
            format: String(localized: "profile.delete.title.format"),
            locale: .current,
            profile.displayName
        )
    }

    private func editAccessibilityLabel(for profile: ProfilePreview) -> String {
        String(
            format: String(localized: "profile.edit.action.format"),
            locale: .current,
            profile.displayName
        )
    }
}

private struct ProfileListRow: View {
    var profile: ProfilePreview
    var isActive: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(profile.phase.tint.opacity(0.16))
                Image(systemName: profile.avatarIcon)
                    .font(.headline)
                    .foregroundStyle(profile.phase.tint)
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 3) {
                Text(profile.displayName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.blue)
            }
        }
        .contentShape(Rectangle())
    }

    private var statusText: String {
        if profile.usesExampleTiming {
            return String(
                format: String(localized: "profile.demo.status.format"),
                locale: .current,
                profile.cycleLength,
                profile.periodLength
            )
        }

        return String(
            format: String(localized: "profile.cycleStatus.format"),
            locale: .current,
            profile.phase.localizedTitle,
            profile.cycleDay,
            profile.cycleLength
        )
    }
}

private struct AddProfileView: View {
    @Binding var newProfileName: String
    var onSave: (Date?, Int, Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var periodStartChoice: PeriodStartChoice = .today
    @State private var selectedDate = Date()
    @State private var cycleLength = 28
    @State private var periodLength = 5
    @State private var isStandardInfoExpanded = false

    var body: some View {
        NavigationStack {
            Form {
                Section("profile.section.person") {
                    TextField("profile.name.placeholder", text: $newProfileName)
                        .textInputAutocapitalization(.words)
                }

                Section("profile.section.cycle") {
                    Picker("periodStart.question", selection: $periodStartChoice) {
                        ForEach(PeriodStartChoice.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }

                    if periodStartChoice == .chooseDate {
                        DatePicker(
                            "periodStart.date",
                            selection: $selectedDate,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                    }

                    Picker("profile.cycleLength.label", selection: $cycleLength) {
                        ForEach(21...45, id: \.self) { value in
                            Text(dayCount(value)).tag(value)
                        }
                    }
                    .pickerStyle(.navigationLink)

                    Label(
                        cycleLength == 28
                            ? CycleValueSource.generalDefault.localizedTitle
                            : CycleValueSource.userProvided.localizedTitle,
                        systemImage: "tag"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Picker("profile.periodLength.label", selection: $periodLength) {
                        ForEach(1...min(10, cycleLength), id: \.self) { value in
                            Text(dayCount(value)).tag(value)
                        }
                    }
                    .pickerStyle(.navigationLink)

                    Label(
                        periodLength == 5
                            ? CycleValueSource.generalDefault.localizedTitle
                            : CycleValueSource.userProvided.localizedTitle,
                        systemImage: "tag"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    DisclosureGroup(isExpanded: $isStandardInfoExpanded) {
                        Text("profile.standardValues.explanation")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 6)
                    } label: {
                        Label("profile.standardValues.title", systemImage: "info.circle")
                    }
                }

                Section {
                    Text("profile.privacyHint")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(String(localized: "profile.add.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") {
                        newProfileName = ""
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") {
                        onSave(resolvedPeriodStart, cycleLength, periodLength)
                        dismiss()
                    }
                    .disabled(newProfileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func dayCount(_ value: Int) -> String {
        String(
            format: String(localized: "common.days.format"),
            locale: .current,
            value
        )
    }

    private var resolvedPeriodStart: Date? {
        switch periodStartChoice {
        case .today:
            return Date()
        case .yesterday:
            return Calendar.current.date(byAdding: .day, value: -1, to: Date())
        case .chooseDate:
            return selectedDate
        case .notKnown:
            return nil
        }
    }
}

struct ProfileEditView: View {
    @EnvironmentObject private var store: CyclePreviewStore
    @Environment(\.dismiss) private var dismiss
    @State private var draft: ProfilePreview
    @State private var isConfirmingPeriod = false
    @State private var isCorrectingCycle = false
    @State private var isStandardInfoExpanded = false
    @State private var isCorrectionExpanded = false

    private let avatarIcons = [
        "person.fill",
        "heart.fill",
        "sparkles",
        "moon.fill",
        "sun.max.fill",
        "leaf.fill"
    ]

    init(profile: ProfilePreview) {
        _draft = State(initialValue: profile)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("profile.section.person") {
                    TextField("profile.name.placeholder", text: $draft.displayName)
                        .textInputAutocapitalization(.words)
                }

                Section("profile.icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                        ForEach(avatarIcons, id: \.self) { icon in
                            Button {
                                draft.avatarIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title3)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .foregroundStyle(draft.avatarIcon == icon ? .white : draft.phase.tint)
                                    .background(draft.avatarIcon == icon ? draft.phase.tint : draft.phase.tint.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("profile.section.cycle") {
                    Picker("profile.cycleLength.label", selection: $draft.cycleLength) {
                        ForEach(21...45, id: \.self) { value in
                            Text(dayCount(value)).tag(value)
                        }
                    }
                    .pickerStyle(.navigationLink)

                    valueSourceRow(source: displayedCycleLengthSource)

                    Picker("profile.periodLength.label", selection: $draft.periodLength) {
                        ForEach(1...min(10, draft.cycleLength), id: \.self) { value in
                            Text(dayCount(value)).tag(value)
                        }
                    }
                    .pickerStyle(.navigationLink)

                    valueSourceRow(source: displayedPeriodLengthSource)

                    DisclosureGroup(isExpanded: $isStandardInfoExpanded) {
                        Text("profile.standardValues.explanation")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 6)
                    } label: {
                        Label("profile.standardValues.title", systemImage: "info.circle")
                    }
                }

                Section("periodStart.section.title") {
                    if let confirmedStart = draft.latestConfirmedPeriodStart {
                        LabeledContent(
                            "periodStart.latestConfirmed",
                            value: confirmedStart.formatted(date: .abbreviated, time: .omitted)
                        )
                        valueSourceRow(source: .userProvided)
                    } else {
                        LabeledContent("periodStart.latestConfirmed", value: String(localized: "periodStart.notKnown"))
                        Text("periodStart.exampleTimingHint")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        isConfirmingPeriod = true
                    } label: {
                        Label("periodStart.action", systemImage: "drop.fill")
                    }
                }

                Section {
                    DisclosureGroup(isExpanded: $isCorrectionExpanded) {
                        Text("cycleCorrection.optionalExplanation")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 6)

                        Button {
                            isCorrectingCycle = true
                        } label: {
                            Label("cycleCorrection.title", systemImage: "calendar.badge.clock")
                        }
                        .padding(.top, 4)
                    } label: {
                        Text("cycleCorrection.moreCorrections")
                    }
                }
            }
            .navigationTitle(String(
                format: String(localized: "profile.edit.title.format"),
                locale: .current,
                draft.displayName
            ))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") {
                        persistDraft()
                        dismiss()
                    }
                    .disabled(draft.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .sheet(isPresented: $isConfirmingPeriod) {
                PeriodStartEditorView(profileName: draft.displayName) { date in
                    guard let date else { return }
                    persistDraft()
                    guard let currentProfile else { return }
                    store.confirmPeriodStart(for: currentProfile, on: date)
                    refreshDraft()
                }
            }
            .sheet(isPresented: $isCorrectingCycle) {
                CycleCorrectionView(profile: draft) { phase, dayInPhase, cycleLength in
                    persistDraft()
                    if let currentProfile {
                        store.updateCycleStatus(
                            for: currentProfile,
                            phase: phase,
                            dayInPhase: dayInPhase,
                            cycleLength: cycleLength
                        )
                        refreshDraft()
                    }
                }
            }
        }
    }

    private var currentProfile: ProfilePreview? {
        store.profiles.first(where: { $0.id == draft.id })
    }

    private var displayedCycleLengthSource: CycleValueSource {
        guard let currentProfile, currentProfile.cycleLength == draft.cycleLength else {
            return draft.cycleLength == 28 ? .generalDefault : .userProvided
        }
        return currentProfile.cycleLengthSource
    }

    private var displayedPeriodLengthSource: CycleValueSource {
        guard let currentProfile, currentProfile.periodLength == draft.periodLength else {
            return draft.periodLength == 5 ? .generalDefault : .userProvided
        }
        return currentProfile.periodLengthSource
    }

    private func valueSourceRow(source: CycleValueSource) -> some View {
        Label(source.localizedTitle, systemImage: "tag")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private func dayCount(_ value: Int) -> String {
        String(
            format: String(localized: "common.days.format"),
            locale: .current,
            value
        )
    }

    private func persistDraft() {
        draft.cycleLengthSource = displayedCycleLengthSource
        draft.periodLengthSource = displayedPeriodLengthSource
        store.saveProfile(draft)
        refreshDraft()
    }

    private func refreshDraft() {
        guard let updatedProfile = store.profiles.first(where: { $0.id == draft.id }) else { return }
        draft = updatedProfile
    }
}

private enum PeriodStartChoice: String, CaseIterable, Identifiable {
    case today
    case yesterday
    case chooseDate
    case notKnown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: return String(localized: "periodStart.choice.today")
        case .yesterday: return String(localized: "periodStart.choice.yesterday")
        case .chooseDate: return String(localized: "periodStart.choice.chooseDate")
        case .notKnown: return String(localized: "periodStart.choice.notKnown")
        }
    }
}

struct PeriodStartEditorView: View {
    var profileName: String
    var onSave: (Date?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var choice: PeriodStartChoice = .today
    @State private var selectedDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("entry.section.person") {
                    LabeledContent("entry.profile", value: profileName)
                }

                Section("periodStart.question") {
                    Picker("periodStart.selection", selection: $choice) {
                        ForEach(PeriodStartChoice.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.inline)

                    if choice == .chooseDate {
                        DatePicker(
                            "periodStart.date",
                            selection: $selectedDate,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                    }
                }

                Section {
                    Text("periodStart.explanation")
                        .foregroundStyle(.secondary)
                    Text("periodStart.consentHint")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(String(localized: "periodStart.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(choice == .notKnown
                        ? String(localized: "common.done")
                        : String(localized: "common.save")) {
                        onSave(resolvedDate)
                        dismiss()
                    }
                }
            }
        }
    }

    private var resolvedDate: Date? {
        switch choice {
        case .today:
            return Date()
        case .yesterday:
            return Calendar.current.date(byAdding: .day, value: -1, to: Date())
        case .chooseDate:
            return selectedDate
        case .notKnown:
            return nil
        }
    }
}

struct ProfileManagementView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileManagementView()
            .cyclePreviewEnvironment()
    }
}
