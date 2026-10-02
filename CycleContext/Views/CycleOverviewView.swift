import SwiftUI

struct CycleOverviewView: View {
    @EnvironmentObject private var store: CyclePreviewStore

    private var activeProfile: ProfilePreview {
        store.activeProfile
    }

    private var activeSection: CycleSection {
        store.section(for: activeProfile)
    }

    private var activeContent: CycleSectionContent {
        CycleContentRepository.content(for: activeSection)
    }

    var body: some View {
        ScreenContainer(title: "screen.cycle.title") {
            IOSCard {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(activeSection.tint.opacity(0.16))
                        Image(systemName: activeProfile.avatarIcon)
                            .foregroundStyle(activeSection.tint)
                    }
                    .frame(width: 42, height: 42)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(activeProfile.displayName)
                            .font(.headline)
                        Text(String(
                            format: String(localized: "cycle.dayOfTotal.format"),
                            locale: .current,
                            activeProfile.cycleDay,
                            activeProfile.cycleLength
                        ))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
            }

            IOSCard {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(activeContent.title, systemImage: activeSection.icon)
                            .font(.headline)
                            .foregroundStyle(activeSection.tint)
                        Text(activeContent.biologicalPhase)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(activeContent.shortGuide)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(activeSection.tint)
                    }

                    PhaseTimelineView(
                        cycleLength: activeProfile.cycleLength,
                        periodLength: activeProfile.periodLength,
                        currentCycleDay: activeProfile.cycleDay
                    )

                }
            }

            NavigationLink {
                CycleEducationView()
            } label: {
                IOSCard {
                    HStack(spacing: 12) {
                        Image(systemName: "book.pages.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.indigo)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        VStack(alignment: .leading, spacing: 3) {
                            Text("cycle.education.open")
                                .font(.headline)
                            Text("cycle.education.open.subtitle")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 8)

                        Image(systemName: "chevron.forward")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityHint(Text("cycle.education.open.hint"))

            SectionHeader(title: "cycle.section.analysis")
            NavigationLink {
                StatisticsView(embedsInNavigationStack: false)
            } label: {
                IOSCard {
                    HStack(spacing: 12) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("cycle.statistics.open")
                                .font(.headline)
                            Text("cycle.statistics.subtitle")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.forward")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .buttonStyle(.plain)

            SectionHeader(title: "cycle.section.fiveSections")
            ForEach(CycleSection.allCases) { section in
                let length = store.effectiveLength(
                    for: section,
                    cycleLength: activeProfile.cycleLength,
                    periodLength: activeProfile.periodLength
                )
                if length > 0 {
                    CycleSectionOverviewCard(
                        section: section,
                        content: CycleContentRepository.content(for: section),
                        rangeText: rangeText(for: section, length: length),
                        isCurrent: section == activeSection
                    )
                }
            }

            IOSCard {
                Label(
                    "cycle.disclaimer",
                    systemImage: "shield.lefthalf.filled"
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func rangeText(for section: CycleSection, length: Int) -> String {
        let start = store.sectionStartDay(
            for: section,
            cycleLength: activeProfile.cycleLength,
            periodLength: activeProfile.periodLength
        )
        let end = min(activeProfile.cycleLength, start + length - 1)
        if start == end {
            return String(
                format: String(localized: "cycle.day.format"),
                locale: .current,
                start
            )
        }
        return String(
            format: String(localized: "cycle.dayRange.format"),
            locale: .current,
            start,
            end
        )
    }
}

private struct CycleSectionOverviewCard: View {
    var section: CycleSection
    var content: CycleSectionContent
    var rangeText: String
    var isCurrent: Bool

    @State private var isExpanded: Bool

    init(
        section: CycleSection,
        content: CycleSectionContent,
        rangeText: String,
        isCurrent: Bool
    ) {
        self.section = section
        self.content = content
        self.rangeText = rangeText
        self.isCurrent = isCurrent
        _isExpanded = State(initialValue: isCurrent)
    }

    var body: some View {
        IOSCard {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: section.icon)
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(section.tint)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(content.title)
                            .font(.headline)
                        if isCurrent {
                            Text("cycle.current")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .foregroundStyle(.white)
                                .background(section.tint)
                                .clipShape(Capsule())
                        }
                    }

                    Text("\(rangeText) · \(content.biologicalPhase)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Text(content.shortGuide)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(section.tint)

            DisclosureGroup(isExpanded: $isExpanded) {
                VStack(alignment: .leading, spacing: 14) {
                    CycleContentDetail(
                        title: "cycle.detail.body",
                        text: content.bodyText,
                        icon: "cross.case.fill",
                        tint: .blue
                    )
                    CycleContentDetail(
                        title: "cycle.detail.experience",
                        text: content.possibleExperienceText,
                        icon: "waveform.path.ecg",
                        tint: .orange
                    )
                    CycleContentDetail(
                        title: "cycle.detail.support",
                        text: content.partnerActionText,
                        icon: "hands.sparkles.fill",
                        tint: .green
                    )
                    CycleContentDetail(
                        title: "cycle.detail.avoid",
                        text: content.avoidText,
                        icon: "hand.raised.fill",
                        tint: .red
                    )

                    if let medicalNote = content.medicalNote {
                        Divider()
                        Label(medicalNote, systemImage: "stethoscope")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.top, 10)
            } label: {
                Text(
                    isExpanded
                        ? String(localized: "cycle.details.hide")
                        : String(localized: "cycle.details.show")
                )
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .tint(section.tint)
        }
    }
}

private struct CycleContentDetail: View {
    var title: LocalizedStringResource
    var text: String
    var icon: String
    var tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
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

struct PhaseTimelineView: View {
    @EnvironmentObject private var store: CyclePreviewStore

    var cycleLength: Int
    var periodLength: Int = 5
    var currentCycleDay: Int? = nil
    var showsLegend = true

    private let indicatorSize: CGFloat = 25
    private let barHeight: CGFloat = 20

    private var sections: [(CycleSection, Int)] {
        CycleSection.allCases.compactMap { section in
            let length = store.effectiveLength(
                for: section,
                cycleLength: cycleLength,
                periodLength: periodLength
            )
            return length > 0 ? (section, length) : nil
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            GeometryReader { proxy in
                let spacing: CGFloat = 3
                let totalSpacing = CGFloat(max(sections.count - 1, 0)) * spacing
                let usableWidth = max(0, proxy.size.width - totalSpacing)

                ZStack(alignment: .leading) {
                    HStack(spacing: spacing) {
                        ForEach(sections, id: \.0.id) { section, length in
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(section.tint)
                                .frame(
                                    width: max(
                                        3,
                                        usableWidth * CGFloat(length) / CGFloat(max(cycleLength, 1))
                                    ),
                                    height: barHeight
                                )
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .center)

                    if let currentCycleDay {
                        Circle()
                            .fill(.white)
                            .stroke(Color.primary.opacity(0.22), lineWidth: 1)
                            .frame(width: indicatorSize, height: indicatorSize)
                            .shadow(color: .black.opacity(0.92), radius: 2, y: 1)

                            //kugelinenschatten
                           /* .overlay(
                                Circle()
                                    .stroke(Color.black.opacity(0.18), lineWidth: 2)
                                    .blur(radius: 2)
                                    .offset(x: -1, y: 0)
                                    .mask(
                                        Circle().fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [.black, .clear]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                    )
                            )
                        */
                            .offset(x: indicatorOffset(in: proxy.size.width, day: currentCycleDay))
                    }
                }
            }
            .frame(height: indicatorSize)

            if showsLegend {
                ForEach(sections, id: \.0.id) { section, length in
                    HStack(spacing: 8) {
                        Image(systemName: section.icon)
                            .foregroundStyle(section.tint)
                            .frame(width: 22)
                        Text(CycleContentRepository.content(for: section).title)
                        Spacer()
                        Text(rangeText(for: section, length: length))
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)
                }
            }
        }
    }

    private func indicatorOffset(in width: CGFloat, day: Int) -> CGFloat {
        let progress = CGFloat(max(1, min(day, cycleLength)) - 1) / CGFloat(max(cycleLength - 1, 1))
        return max(0, min(width - indicatorSize, width * progress - indicatorSize / 2))
    }

    private func rangeText(for section: CycleSection, length: Int) -> String {
        let start = store.sectionStartDay(
            for: section,
            cycleLength: cycleLength,
            periodLength: periodLength
        )
        let end = min(cycleLength, start + length - 1)
        if start == end {
            return String(
                format: String(localized: "cycle.day.format"),
                locale: .current,
                start
            )
        }
        return String(
            format: String(localized: "cycle.dayRange.format"),
            locale: .current,
            start,
            end
        )
    }
}

struct CycleSectionRingView: View {
    @EnvironmentObject private var store: CyclePreviewStore

    var cycleLength: Int
    var periodLength: Int = 5
    var currentCycleDay: Int

    private let lineWidth: CGFloat = 9
    private let segmentGap: CGFloat = 0.008
    private let markerSize: CGFloat = 9

    private var sections: [(CycleSection, Int)] {
        CycleSection.allCases.compactMap { section in
            let length = store.effectiveLength(
                for: section,
                cycleLength: cycleLength,
                periodLength: periodLength
            )
            return length > 0 ? (section, length) : nil
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let markerRadius = max(0, size / 2 - markerSize / 2)
            let markerPosition = markerPosition(center: center, radius: markerRadius)

            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: lineWidth)

                ForEach(sections.indices, id: \.self) { index in
                    let section = sections[index].0
                    let start = segmentStart(at: index) + segmentGap / 2
                    let end = segmentEnd(at: index) - segmentGap / 2

                    Circle()
                        .trim(from: start, to: max(start, end))
                        .stroke(
                            section.tint,
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt)
                        )
                        .rotationEffect(.degrees(-90))
                }

                Circle()
                    .fill(.white)
                    .stroke(Color.primary.opacity(0.24), lineWidth: 1)
                    .frame(width: markerSize, height: markerSize)
                    .position(markerPosition)
                    .shadow(color: .black.opacity(0.12), radius: 1, y: 1)
            }
        }
        .accessibilityHidden(true)
    }

    private func segmentStart(at index: Int) -> CGFloat {
        let precedingDays = sections.prefix(index).reduce(0) { $0 + $1.1 }
        return CGFloat(precedingDays) / CGFloat(max(cycleLength, 1))
    }

    private func segmentEnd(at index: Int) -> CGFloat {
        let daysThroughSegment = sections.prefix(index + 1).reduce(0) { $0 + $1.1 }
        return CGFloat(daysThroughSegment) / CGFloat(max(cycleLength, 1))
    }

    private func markerPosition(center: CGPoint, radius: CGFloat) -> CGPoint {
        let day = max(1, min(currentCycleDay, max(cycleLength, 1)))
        let progress = (CGFloat(day) - 0.5) / CGFloat(max(cycleLength, 1))
        let angle = progress * 2 * .pi - .pi / 2
        return CGPoint(
            x: center.x + cos(angle) * radius,
            y: center.y + sin(angle) * radius
        )
    }
}

struct CycleOverviewView_Previews: PreviewProvider {
    static var previews: some View {
        CycleOverviewView()
            .cyclePreviewEnvironment()
    }
}
