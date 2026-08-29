import Foundation

struct StreakService {
    static func updatedStreak(
        lastLoggedDate: Date?,
        currentStreak: Int,
        today: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        guard let lastLoggedDate else { return 1 }
        if calendar.isDate(lastLoggedDate, inSameDayAs: today) {
            return currentStreak
        }
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
              calendar.isDate(lastLoggedDate, inSameDayAs: yesterday) else {
            return 1
        }
        return currentStreak + 1
    }

    static func currentStreak(
        logDates: [Date],
        asOf today: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        let uniqueDays = Set(logDates.map { calendar.startOfDay(for: $0) })
        guard !uniqueDays.isEmpty else { return 0 }

        let todayStart = calendar.startOfDay(for: today)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: todayStart)!
        let anchor: Date
        if uniqueDays.contains(todayStart) {
            anchor = todayStart
        } else if uniqueDays.contains(yesterday) {
            anchor = yesterday
        } else {
            return 0
        }

        var streak = 0
        var cursor = anchor
        while uniqueDays.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }
            cursor = previous
        }
        return streak
    }
}
