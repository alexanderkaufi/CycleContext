import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject private var store: CyclePreviewStore
    var embedsInNavigationStack = true

    var body: some View {
        ScreenContainer(title: "screen.statistics.title", embedsInNavigationStack: embedsInNavigationStack) {
            IOSCard {
                HStack(spacing: 12) {
                    Image(systemName: store.activeProfile.avatarIcon)
                        .foregroundStyle(store.activeProfile.phase.tint)
                        .frame(width: 38, height: 38)
                        .background(store.activeProfile.phase.tint.opacity(0.14))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(store.activeProfile.displayName)
                            .font(.headline)
                        Text("statistics.profile.only")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            SectionHeader(title: "statistics.section.plannedCycle")
            IOSCard {
                ForEach(phaseShares, id: \.0.id) { phase, value in
                    VStack(alignment: .leading, spacing: 7) {
                        HStack {
                            Label(phase.localizedTitle, systemImage: phase.icon)
                                .foregroundStyle(phase.tint)
                            Spacer()
                            Text(value, format: .percent.precision(.fractionLength(0)))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }

                        ProgressView(value: value)
                            .tint(phase.tint)
                    }
                }
            }

            SectionHeader(title: "statistics.section.personalData")
            HStack(spacing: 12) {
                MetricPill(
                    title: "statistics.metric.plannedValue",
                    value: String(
                        format: String(localized: "common.days.format"),
                        locale: .current,
                        store.activeProfile.cycleLength
                    ),
                    tint: .blue
                )
                MetricPill(
                    title: "statistics.metric.entries",
                    value: store.activePersonalEntries.count.formatted(),
                    tint: .green
                )
            }

            IOSCard {
                if recordedCycleLengths.isEmpty {
                    AdviceRow(card: AdviceCard(
                        title: String(localized: "statistics.history.empty.title"),
                        subtitle: String(localized: "statistics.history.empty.body"),
                        icon: "chart.line.uptrend.xyaxis",
                        tint: .blue
                    ))
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("statistics.personalAverage", systemImage: "chart.line.uptrend.xyaxis")
                            .font(.headline)
                            .foregroundStyle(.blue)
                        Text(averageDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Text("statistics.disclaimer")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
        }
    }

    private var recordedCycleLengths: [Int] {
        store.recordedCycleLengths(for: store.activeProfile)
    }

    private var averageCycleLength: Int {
        guard !recordedCycleLengths.isEmpty else { return store.activeProfile.cycleLength }
        return Int((Double(recordedCycleLengths.reduce(0, +)) / Double(recordedCycleLengths.count)).rounded())
    }

    private var averageDescription: String {
        if recordedCycleLengths.count == 1 {
            return String(
                format: String(localized: "statistics.average.one.format"),
                locale: .current,
                averageCycleLength
            )
        }

        return String(
            format: String(localized: "statistics.average.other.format"),
            locale: .current,
            averageCycleLength,
            recordedCycleLengths.count
        )
    }

    private var phaseShares: [(CyclePhase, Double)] {
        CyclePhase.allCases.map { phase in
            let length = store.effectiveLength(
                for: phase,
                cycleLength: store.activeProfile.cycleLength,
                periodLength: store.activeProfile.periodLength
            )
            return (phase, Double(length) / Double(max(store.activeProfile.cycleLength, 1)))
        }
    }
}

struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsView()
            .cyclePreviewEnvironment()
            .previewDisplayName("Statistik")
    }
}
