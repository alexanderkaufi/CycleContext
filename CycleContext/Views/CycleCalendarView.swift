import SwiftUI

struct CycleCalendarView: View {
    @EnvironmentObject private var store: CyclePreviewStore
    @State private var displayedMonth = Date()
    @State private var selectedDate = Date()
    @State private var isAddingEntry = false

    private let columns = Array(repeating: GridItem(.flexible(minimum: 0), spacing: 2), count: 7)

    var body: some View {
        ScreenContainer(
            title: "screen.calendar.title",
            actionIcon: "plus",
            action: { isAddingEntry = true }
        ) {
            SectionHeader(verbatimTitle: store.activeProfile.displayName)

            IOSCard {
                HStack {
                    Button {
                        moveMonth(by: -1)
                    } label: {
                        Image(systemName: "chevron.backward")
                            .frame(width: 36, height: 36)
                    }
                    .accessibilityLabel(Text("calendar.previousMonth"))

                    Spacer()

                    Text(monthTitle)
                        .font(.headline)

                    Spacer()

                    Button {
                        moveMonth(by: 1)
                    } label: {
                        Image(systemName: "chevron.forward")
                            .frame(width: 36, height: 36)
                    }
                    .accessibilityLabel(Text("calendar.nextMonth"))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Label(estimateSummary, systemImage: "calendar.badge.clock")
                        .font(.caption.weight(.semibold))
                    Text("calendar.estimate.disclaimer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                CalendarPhaseLegend()

                Divider()

                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(weekdays, id: \.self) { day in
                        Text(day)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }

                    ForEach(0..<leadingEmptyDays, id: \.self) { _ in
                        Color.clear
                            .frame(minHeight: 50)
                    }

                    ForEach(store.calendarDays(in: displayedMonth)) { day in
                        Button {
                            selectedDate = day.date
                        } label: {
                            CalendarDayCell(
                                day: day,
                                isSelected: Calendar.current.isDate(day.date, inSameDayAs: selectedDate)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(dayAccessibilityLabel(for: day))
                        .accessibilityAddTraits(
                            Calendar.current.isDate(day.date, inSameDayAs: selectedDate)
                                ? .isSelected
                                : []
                        )
                    }
                }
            }

            SectionHeader(title: "calendar.selectedDay")
            IOSCard {
                Text(selectedDateTitle)
                    .font(.subheadline.weight(.semibold))

                if selectedIsConfirmedPeriodStart {
                    Label("cycle.confidence.confirmedPeriod", systemImage: "drop.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                }

                Divider()

                AdviceRow(card: AdviceCard(
                    title: selectedDayTitle,
                    subtitle: selectedDaySubtitle,
                    icon: selectedSection.icon,
                    tint: selectedSection.tint
                ))

                if !selectedEntries.isEmpty {
                    Divider()
                    Label(entryCountText, systemImage: "list.bullet.rectangle.fill")
                    .font(.subheadline.weight(.semibold))
                }
            }
        }
        .sheet(isPresented: $isAddingEntry) {
            EntryEditorView(
                profileName: store.activeProfile.displayName,
                initialDate: selectedDate
            ) { title, note, date, wellbeing in
                store.addEntry(title: title, note: note, date: date, wellbeing: wellbeing)
            }
        }
    }

    private var selectedCycleDay: Int {
        store.projectedCycleDay(for: store.activeProfile, on: selectedDate)
    }

    private var selectedSection: CycleSection {
        store.section(
            for: selectedCycleDay,
            cycleLength: store.activeProfile.cycleLength,
            periodLength: store.activeProfile.periodLength
        )
    }

    private var selectedContent: CycleSectionContent {
        CycleContentRepository.content(for: selectedSection)
    }

    private var selectedEntries: [EntryPreview] {
        store.entries(for: store.activeProfile.id, on: selectedDate)
    }

    private var selectedIsConfirmedPeriodStart: Bool {
        store.activeProfile.periodStarts.contains {
            Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
        }
    }

    private var selectedDayTitle: String {
        String(
            format: String(localized: "calendar.dayTitle.format"),
            locale: .current,
            selectedCycleDay,
            selectedContent.title
        )
    }

    private var selectedDaySubtitle: String {
        selectedContent.partnerActionText
    }

    private var selectedDateTitle: String {
        selectedDate.formatted(
            .dateTime
                .weekday(.wide)
                .day()
                .month(.wide)
                .year()
                .locale(Locale.current)
        )
    }

    private var estimateSummary: String {
        let key = store.activeProfile.usesExampleTiming
            ? "calendar.estimate.demo.format"
            : "calendar.estimate.projected.format"

        return String(
            format: String(localized: String.LocalizationValue(key)),
            locale: .current,
            store.activeProfile.cycleLength
        )
    }

    private var monthTitle: String {
        displayedMonth.formatted(.dateTime.month(.wide).year().locale(Locale.current))
    }

    private var weekdays: [String] {
        let symbols = Calendar.current.shortStandaloneWeekdaySymbols
        let firstIndex = max(0, min(Calendar.current.firstWeekday - 1, symbols.count - 1))
        return Array(symbols[firstIndex...]) + Array(symbols[..<firstIndex])
    }

    private var entryCountText: String {
        if selectedEntries.count == 1 {
            return String(localized: "entries.count.one")
        }

        return String(
            format: String(localized: "entries.count.other.format"),
            locale: .current,
            selectedEntries.count
        )
    }

    private var leadingEmptyDays: Int {
        guard let monthStart = Calendar.current.dateInterval(of: .month, for: displayedMonth)?.start else {
            return 0
        }
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: monthStart)
        return (weekday - calendar.firstWeekday + 7) % 7
    }

    private func dayAccessibilityLabel(for day: CalendarDay) -> String {
        let sectionTitle = CycleContentRepository.content(for: day.section).title
        let cycleDescription = String(
            format: String(localized: "calendar.dayTitle.format"),
            locale: .current,
            day.cycleDay,
            sectionTitle
        )
        var components = [
            day.date.formatted(date: .complete, time: .omitted),
            cycleDescription
        ]

        if day.isToday {
            components.append(String(localized: "calendar.today"))
        }
        if day.isConfirmedPeriodStart {
            components.append(String(localized: "cycle.confidence.confirmedPeriod"))
        }
        if day.hasEntry {
            components.append(String(localized: "calendar.entryAvailable"))
        }

        return components.joined(separator: ", ")
    }

    private func moveMonth(by value: Int) {
        guard let nextMonth = Calendar.current.date(byAdding: .month, value: value, to: displayedMonth) else {
            return
        }
        displayedMonth = nextMonth
        selectedDate = Calendar.current.dateInterval(of: .month, for: nextMonth)?.start ?? nextMonth
    }
}

private struct CalendarPhaseLegend: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columns: [GridItem] {
        [
            GridItem(
                .adaptive(minimum: dynamicTypeSize.isAccessibilitySize ? 220 : 132),
                spacing: 8,
                alignment: .leading
            )
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("calendar.legend.title")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(CycleSection.allCases) { section in
                    HStack(alignment: .top, spacing: 6) {
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(section.tint)
                            .frame(width: 11, height: 11)
                            .padding(.top, 2)

                        Text(CycleContentRepository.content(for: section).title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }
}

private struct CalendarDayCell: View {
    var day: CalendarDay
    var isSelected: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(day.section.tint.opacity(isSelected ? 0.30 : 0.16))

            VStack(spacing: 3) {
                Text("\(day.number)")
                    .font(.subheadline.weight(day.isToday || isSelected ? .bold : .regular))
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    if day.isConfirmedPeriodStart {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.red)
                    }

                    if day.hasEntry {
                        Circle()
                            .fill(Color.primary.opacity(0.72))
                            .frame(width: 5, height: 5)
                    }
                }
                .frame(height: 9)
            }
            .padding(.vertical, 4)
        }
        .frame(maxWidth: .infinity, minHeight: 50)
        .overlay {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(
                    isSelected ? Color.primary : (day.isToday ? Color.blue : Color.clear),
                    lineWidth: isSelected ? 2.5 : 2
                )
        }
        .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
    }
}

struct CycleCalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CycleCalendarView()
            .cyclePreviewEnvironment()
            .previewDisplayName("Kalender")
    }
}
