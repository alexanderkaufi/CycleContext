import Foundation

struct ReviewRequestPolicy {
    private enum Key {
        static let activeDayIdentifiers = "cyclecontext.review.activeDayIdentifiers"
        static let lastRequestAttempt = "cyclecontext.review.lastRequestAttempt"
    }

    private let minimumActiveDayCount = 3
    private let minimumDaysBetweenRequests = 14
    private let defaults: UserDefaults
    private let calendar: Calendar
    private let isRunningForPreviews: Bool

    init(
        defaults: UserDefaults = .standard,
        calendar: Calendar = .autoupdatingCurrent,
        isRunningForPreviews: Bool = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    ) {
        self.defaults = defaults
        self.calendar = calendar
        self.isRunningForPreviews = isRunningForPreviews
    }

    func registerActiveDay(on date: Date) {
        guard !isRunningForPreviews, let identifier = dayIdentifier(for: date) else { return }

        var identifiers = Set(defaults.stringArray(forKey: Key.activeDayIdentifiers) ?? [])
        guard identifiers.count < minimumActiveDayCount else { return }

        identifiers.insert(identifier)
        defaults.set(identifiers.sorted(), forKey: Key.activeDayIdentifiers)
    }

    func shouldRequestReview(on date: Date, hasPersonalizedProfile: Bool) -> Bool {
        guard !isRunningForPreviews, hasPersonalizedProfile else { return false }

        let activeDays = Set(defaults.stringArray(forKey: Key.activeDayIdentifiers) ?? [])
        guard activeDays.count >= minimumActiveDayCount else { return false }
        guard calendar.isDateInWeekend(date) else { return false }

        if
            let lastAttempt = defaults.object(forKey: Key.lastRequestAttempt) as? Date,
            let nextAllowedDate = calendar.date(
                byAdding: .day,
                value: minimumDaysBetweenRequests,
                to: lastAttempt
            ),
            date < nextAllowedDate
        {
            return false
        }

        return true
    }

    func recordRequestAttempt(on date: Date) {
        defaults.set(date, forKey: Key.lastRequestAttempt)
    }

    private func dayIdentifier(for date: Date) -> String? {
        let components = calendar.dateComponents([.era, .year, .month, .day], from: date)
        guard
            let era = components.era,
            let year = components.year,
            let month = components.month,
            let day = components.day
        else {
            return nil
        }

        return "\(calendar.identifier)-\(era)-\(year)-\(month)-\(day)"
    }
}
