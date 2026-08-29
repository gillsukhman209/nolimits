import Foundation
import UserNotifications

@MainActor
enum ReminderService {
    private static let identifierPrefix = "liftoff.daily."

    static func updateSchedule(
        isEnabled: Bool,
        reminderTime: Date,
        logDates: [Date],
        requestAuthorization: Bool = false
    ) async {
        let center = UNUserNotificationCenter.current()
        if !isEnabled {
            await removeLiftoffReminders(center: center)
            return
        }

        if requestAuthorization {
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
        }

        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional else {
            await removeLiftoffReminders(center: center)
            return
        }

        await removeLiftoffReminders(center: center)

        let calendar = Calendar.current
        let now = Date.now
        let timeComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)

        for dayOffset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: now),
                  let fireDate = calendar.date(
                    bySettingHour: timeComponents.hour ?? 19,
                    minute: timeComponents.minute ?? 30,
                    second: 0,
                    of: day
                  ),
                  fireDate > now else {
                continue
            }

            let hasLog = logDates.contains {
                calendar.isDate($0, inSameDayAs: fireDate)
            }
            guard !hasLog else { continue }

            let content = UNMutableNotificationContent()
            content.body = "Log a set today to keep your streak."
            content.sound = .default

            let triggerComponents = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: fireDate
            )
            let request = UNNotificationRequest(
                identifier: identifier(for: fireDate, calendar: calendar),
                content: content,
                trigger: UNCalendarNotificationTrigger(
                    dateMatching: triggerComponents,
                    repeats: false
                )
            )
            try? await center.add(request)
        }
    }

    private static func removeLiftoffReminders(
        center: UNUserNotificationCenter
    ) async {
        let pending = await center.pendingNotificationRequests()
        let identifiers = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(identifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private static func identifier(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(identifierPrefix)\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }
}
