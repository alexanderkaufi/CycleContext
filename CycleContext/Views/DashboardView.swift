import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: CyclePreviewStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isManagingProfiles = false
    @State private var isConfirmingPeriod = false
    @State private var editingProfile: ProfilePreview?
    @State private var isOrientationExpanded = false
    @State private var isExampleInfoExpanded = false
    @State private var previewDaysAhead: Int?
    @State private var isShowingRatingSupport = false

    var body: some View {
        ScreenContainer(
            title: "app.name",
            titleAccessory: dynamicTypeSize.isAccessibilitySize ? nil : AnyView(
                Button {
                    isShowingRatingSupport = true
                } label: {
                    ZStack {
                        CycleSectionRingView(
                            cycleLength: displayedProfile.cycleLength,
                            periodLength: displayedProfile.periodLength,
                            currentCycleDay: displayedProfile.cycleDay
                        )
                        Text("\(displayedProfile.cycleDay)")
                            .font(.caption2.bold())
                    }
                    .frame(width: 27.5, height: 60)
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("rating.support.open"))
                .accessibilityValue(cycleDayText(for: displayedProfile))
                .accessibilityHint(Text("rating.support.openHint"))
            ),
            actionIcon: "person.2.fill",
            action: {
                isManagingProfiles = true
            }
        ) {
            profileSwitcher
            phaseHero

            HStack(spacing: 12) {
                Button {
                    isConfirmingPeriod = true
                } label: {
                    MetricPill(
                        title: "dashboard.metric.period.title",
                        value: String(localized: "dashboard.metric.period.value"),
                        tint: displayedTint
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("periodStart.action"))
                .accessibilityHint(Text("periodStart.openHint"))

                Button {
                    let currentOffset = previewDaysAhead ?? 0
                    previewDaysAhead = currentOffset + daysUntilNextSectionChange(for: nextSectionProfile)
                } label: {
                    MetricPill(title: "dashboard.metric.nextSection", value: nextSectionDateText, tint: .blue)
                }
                .buttonStyle(.plain)
            }

            IOSCard {
                Label("dashboard.orientation.relationship", systemImage: "person.2.fill")
                    .font(.headline)
                    .foregroundStyle(.green)

                Text(everydaySummaryText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isOrientationExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 12) {
                        Label("dashboard.background.title", systemImage: "info.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(displayedTint)

                        Spacer(minLength: 8)

                        Image(systemName: isOrientationExpanded ? "chevron.down" : "chevron.right")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.primary)
                            .frame(width: 24, height: 24)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if isOrientationExpanded {
                    VStack(alignment: .leading, spacing: 16) {
                        if isDisplayedTimingOverdue {
                            Text("dashboard.overdue.orientation")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            Text(displayedContent.todayText)
                                .font(.subheadline.weight(.semibold))
                                .fixedSize(horizontal: false, vertical: true)

                            DashboardOrientationDetail(
                                title: "dashboard.orientation.body",
                                text: displayedContent.bodyText,
                                icon: "cross.case.fill",
                                tint: .blue
                            )

                            DashboardOrientationDetail(
                                title: "dashboard.orientation.experience",
                                text: displayedContent.possibleExperienceText,
                                icon: "brain.head.profile",
                                tint: .orange
                            )

                            if let medicalNote = displayedContent.medicalNote {
                                Divider()
                                Label(medicalNote, systemImage: "stethoscope")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(.top, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .sheet(isPresented: $isManagingProfiles) {
            ProfileManagementView()
        }
        .sheet(item: $editingProfile) { profile in
            ProfileEditView(profile: profile)
        }
        .sheet(isPresented: $isConfirmingPeriod) {
            PeriodStartEditorView(profileName: store.activeProfile.displayName) { date in
                guard let date else { return }
                store.confirmPeriodStart(for: store.activeProfile, on: date)
                previewDaysAhead = nil
            }
        }
        .sheet(isPresented: $isShowingRatingSupport) {
            RatingSupportView()
        }
    }

    private var profileSwitcher: some View {
        IOSCard {
            Menu {
                ForEach(store.profiles) { profile in
                    Button {
                        store.selectProfile(profile)
                        previewDaysAhead = nil
                    } label: {
                        Label(
                            profile.displayName,
                            systemImage: profile.id == store.activeProfile.id
                                ? "checkmark.circle.fill"
                                : profile.avatarIcon
                        )
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: store.activeProfile.avatarIcon)
                        .font(.headline)
                        .foregroundStyle(activeSection.tint)
                        .frame(width: 36, height: 36)
                        .background(activeSection.tint.opacity(0.14))
                        .clipShape(Circle())

                    Text(store.activeProfile.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(
                format: String(localized: "profile.selected.format"),
                locale: .current,
                store.activeProfile.displayName
            ))
            .accessibilityHint(Text("profile.selector.openHint"))


        }
    }

    private var phaseHero: some View {
        IOSCard {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    if let previewDaysAhead {
                        Label(String(
                            format: String(localized: "dashboard.preview.format"),
                            locale: .current,
                            dateText(daysAhead: previewDaysAhead)
                        ), systemImage: "forward.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    if isDisplayedTimingOverdue {
                        Label("dashboard.overdue.title", systemImage: "exclamationmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(.orange)
                        Text("dashboard.overdue.phase")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(cycleDayText(for: displayedProfile))
                            .font(.headline.bold())
                        Text("dashboard.overdue.body")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Label(displayedContent.title, systemImage: displayedSection.icon)
                            .font(.headline)
                            .foregroundStyle(displayedSection.tint)
                        Text(displayedContent.biologicalPhase)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(cycleDayText(for: displayedProfile))
                            .font(.headline.bold())
                        Text(displayedContent.shortGuide)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        if previewDaysAhead == nil && !store.activeProfile.usesExampleTiming {
                            Label(displayedConfidence.title, systemImage: displayedConfidence.icon)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if previewDaysAhead == nil && store.activeProfile.usesExampleTiming {
                        DisclosureGroup(isExpanded: $isExampleInfoExpanded) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("dashboard.example.explanation")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)

                                Button {
                                    editingProfile = store.activeProfile
                                } label: {
                                    Label("dashboard.example.adjust", systemImage: "pencil")
                                }
                                .font(.subheadline.weight(.semibold))
                            }
                            .padding(.top, 8)
                        } label: {
                            Label(exampleSummary, systemImage: "info.circle")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }

                    if previewDaysAhead != nil {
                        Button("dashboard.showToday") {
                            self.previewDaysAhead = nil
                        }
                        .font(.subheadline.weight(.semibold))
                    }
                }

                PhaseTimelineView(
                    cycleLength: displayedProfile.cycleLength,
                    periodLength: displayedProfile.periodLength,
                    currentCycleDay: displayedProfile.cycleDay,
                    showsLegend: false
                )
            }
        }
    }

    private var displayedProfile: ProfilePreview {
        guard previewDaysAhead != nil else { return store.activeProfile }
        var projectedProfile = store.activeProfile
        projectedProfile.cycleDay = store.projectedCycleDay(for: projectedProfile, on: displayedDate)
        projectedProfile.phase = store.phase(
            for: projectedProfile.cycleDay,
            cycleLength: projectedProfile.cycleLength,
            periodLength: projectedProfile.periodLength
        )
        return projectedProfile
    }

    private var nextSectionProfile: ProfilePreview {
        guard previewDaysAhead == nil, isDisplayedTimingOverdue else { return displayedProfile }
        var projectedProfile = store.activeProfile
        projectedProfile.cycleDay = store.projectedCycleDay(for: projectedProfile, on: Date())
        projectedProfile.phase = store.phase(
            for: projectedProfile.cycleDay,
            cycleLength: projectedProfile.cycleLength,
            periodLength: projectedProfile.periodLength
        )
        return projectedProfile
    }

    private var activeSection: CycleSection {
        store.section(for: store.activeProfile)
    }

    private var displayedSection: CycleSection {
        store.section(for: displayedProfile)
    }

    private var isDisplayedTimingOverdue: Bool {
        previewDaysAhead == nil && store.isTimingOverdue(for: store.activeProfile, on: Date())
    }

    private var displayedTint: Color {
        isDisplayedTimingOverdue ? .orange : displayedSection.tint
    }

    private var displayedContent: CycleSectionContent {
        CycleContentRepository.content(for: displayedSection)
    }

    private var everydaySummaryText: String {
        isDisplayedTimingOverdue
            ? String(localized: "dashboard.overdue.relationship")
            : displayedContent.partnerActionText
    }

    private var displayedConfidence: CycleEstimateConfidence {
        store.confidence(for: displayedProfile, on: displayedDate)
    }

    private var exampleSummary: String {
        return String(
            format: String(localized: "dashboard.example.summary.format"),
            locale: .current,
            store.activeProfile.cycleLength,
            store.activeProfile.periodLength
        )
    }

    private var displayedDate: Date {
        Calendar.current.date(byAdding: .day, value: previewDaysAhead ?? 0, to: Date()) ?? Date()
    }

    private var nextSectionDateText: String {
        let currentOffset = previewDaysAhead ?? 0
        let nextOffset = currentOffset + daysUntilNextSectionChange(for: nextSectionProfile)
        return String(
            format: String(localized: "dashboard.nextSectionDate.format"),
            locale: .current,
            dateText(daysAhead: nextOffset)
        )
    }

    private func daysUntilNextSectionChange(for profile: ProfilePreview) -> Int {
        let cycleLength = max(profile.cycleLength, 1)
        let currentSection = store.section(for: profile)

        for offset in 1...cycleLength {
            let zeroBasedDay = (profile.cycleDay - 1 + offset) % cycleLength
            let nextDay = zeroBasedDay + 1
            let nextSection = store.section(
                for: nextDay,
                cycleLength: cycleLength,
                periodLength: profile.periodLength
            )
            if nextSection != currentSection {
                return offset
            }
        }

        return cycleLength
    }

    private func dateText(daysAhead: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: daysAhead, to: Date()) ?? Date()
        return date.formatted(.dateTime.day().month(.wide).locale(Locale.current))
    }

    private func cycleDayText(for profile: ProfilePreview) -> String {
        if
            previewDaysAhead == nil,
            profile.id == store.activeProfile.id,
            let observedDay = store.observedCycleDay(for: store.activeProfile, on: Date()),
            observedDay > profile.cycleLength
        {
            return String(
                format: String(localized: "cycle.overdueDay.format"),
                locale: .current,
                observedDay
            )
        }

        return String(
            format: String(localized: "cycle.dayOfTotal.format"),
            locale: .current,
            profile.cycleDay,
            profile.cycleLength
        )
    }

}

private struct DashboardOrientationDetail: View {
    var title: LocalizedStringResource
    var text: String
    var icon: String
    var tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: title))
                    .font(.subheadline.weight(.semibold))
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct CycleCorrectionView: View {
    let profile: ProfilePreview
    var onSave: (CyclePhase, Int, Int) -> Void

    @EnvironmentObject private var store: CyclePreviewStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhase: CyclePhase
    @State private var dayInPhase: Int
    @State private var cycleLength: Int

    init(profile: ProfilePreview, onSave: @escaping (CyclePhase, Int, Int) -> Void) {
        self.profile = profile
        self.onSave = onSave
        _selectedPhase = State(initialValue: profile.phase)
        _cycleLength = State(initialValue: profile.cycleLength)
        _dayInPhase = State(initialValue: max(
            1,
            profile.cycleDay - Self.phaseStartDay(for: profile) + 1
        ))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("cycleCorrection.currentStatus") {
                    Picker("cycle.phase.label", selection: $selectedPhase) {
                        ForEach(CyclePhase.allCases) { phase in
                            Label(phase.correctionLabel, systemImage: phase.icon)
                                .tag(phase)
                        }
                    }
                    .onChange(of: selectedPhase) { _, newPhase in
                        dayInPhase = min(dayInPhase, maxDayInPhase(for: newPhase))
                    }

                    Stepper(value: $dayInPhase, in: 1...maxDayInPhase(for: selectedPhase)) {
                        Text(String(
                            format: String(localized: "cycleCorrection.dayInPhase.format"),
                            locale: .current,
                            dayInPhase,
                            selectedPhase.correctionLabel
                        ))
                    }

                    Stepper(value: $cycleLength, in: 21...45) {
                        Text(String(
                            format: String(localized: "profile.cycleLength.format"),
                            locale: .current,
                            cycleLength
                        ))
                    }
                }

                Section {
                    Text("cycleCorrection.explanation")
                        .foregroundStyle(.secondary)
                    Text("cycleCorrection.pmsExplanation")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(String(
                format: String(localized: "cycleCorrection.profileTitle.format"),
                locale: .current,
                profile.displayName
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
                        onSave(selectedPhase, dayInPhase, cycleLength)
                        dismiss()
                    }
                }
            }
        }
    }

    private func maxDayInPhase(for phase: CyclePhase) -> Int {
        max(
            1,
            store.effectiveLength(
                for: phase,
                cycleLength: cycleLength,
                periodLength: profile.periodLength
            )
        )
    }

    private static func phaseStartDay(for profile: ProfilePreview) -> Int {
        let ovulationDay = max(
            min(profile.periodLength + 1, profile.cycleLength),
            profile.cycleLength - 14
        )
        switch profile.phase {
        case .menstruation: return 1
        case .follicular: return min(profile.periodLength + 1, profile.cycleLength)
        case .ovulation: return ovulationDay
        case .luteal: return min(ovulationDay + 1, profile.cycleLength)
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .cyclePreviewEnvironment()
            .previewDisplayName("Dashboard")
    }
}
