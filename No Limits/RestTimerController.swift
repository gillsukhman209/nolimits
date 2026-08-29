import Foundation
import Observation
import UIKit
import UserNotifications

@MainActor
@Observable
final class RestTimerController {
    private enum Keys {
        static let endDate = "liftoff.restTimer.endDate"
        static let duration = "liftoff.restTimer.activeDuration"
    }

    private static let notificationIdentifier = "liftoff.restTimer.complete"

    private(set) var endDate: Date?
    private(set) var durationSeconds: Int
    private(set) var now: Date

    private let defaults: UserDefaults
    private var ticker: Task<Void, Never>?
    private var completionFeedbackPending = false

    init(defaults: UserDefaults = .standard, now: Date = .now) {
        self.defaults = defaults
        self.now = now
        self.durationSeconds = max(defaults.integer(forKey: Keys.duration), 1)

        let storedEndDate = defaults.double(forKey: Keys.endDate)
        if storedEndDate > now.timeIntervalSince1970 {
            self.endDate = Date(timeIntervalSince1970: storedEndDate)
            completionFeedbackPending = true
            startTicker()
        } else {
            self.endDate = nil
            defaults.removeObject(forKey: Keys.endDate)
        }
    }

    var remainingSeconds: Int {
        RestTimerMath.remainingSeconds(endDate: endDate, now: now)
    }

    var progress: Double {
        RestTimerMath.progress(
            remainingSeconds: remainingSeconds,
            durationSeconds: durationSeconds
        )
    }

    var formattedRemainingTime: String {
        RestTimerMath.formattedTime(seconds: remainingSeconds)
    }

    var isRunning: Bool {
        endDate != nil && remainingSeconds > 0
    }

    func start(seconds: Int) {
        let safeDuration = max(seconds, 1)
        durationSeconds = safeDuration
        now = .now
        endDate = now.addingTimeInterval(TimeInterval(safeDuration))
        completionFeedbackPending = true
        persist()
        startTicker()
        Task { await scheduleCompletionNotification() }
    }

    func add(seconds: Int) {
        guard seconds > 0 else { return }
        now = .now
        if let endDate, remainingSeconds > 0 {
            self.endDate = endDate.addingTimeInterval(TimeInterval(seconds))
            durationSeconds += seconds
        } else {
            start(seconds: seconds)
            return
        }
        persist()
        Task { await scheduleCompletionNotification() }
    }

    func stop() {
        ticker?.cancel()
        ticker = nil
        endDate = nil
        completionFeedbackPending = false
        defaults.removeObject(forKey: Keys.endDate)
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [Self.notificationIdentifier]
        )
    }

    func refresh() {
        now = .now
        finishIfNeeded()
    }

    private func startTicker() {
        ticker?.cancel()
        ticker = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self, !Task.isCancelled else { return }
                self.now = .now
                if self.finishIfNeeded() { return }
            }
        }
    }

    @discardableResult
    private func finishIfNeeded() -> Bool {
        guard endDate != nil, remainingSeconds == 0 else { return false }
        ticker?.cancel()
        ticker = nil
        endDate = nil
        defaults.removeObject(forKey: Keys.endDate)

        if completionFeedbackPending {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        completionFeedbackPending = false
        return true
    }

    private func persist() {
        defaults.set(endDate?.timeIntervalSince1970, forKey: Keys.endDate)
        defaults.set(durationSeconds, forKey: Keys.duration)
    }

    private func scheduleCompletionNotification() async {
        guard let endDate else { return }
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional else {
            return
        }

        center.removePendingNotificationRequests(
            withIdentifiers: [Self.notificationIdentifier]
        )
        let content = UNMutableNotificationContent()
        content.title = "Rest complete"
        content.body = "You’re ready for your next set."
        content.sound = .default
        let interval = max(endDate.timeIntervalSinceNow, 1)
        let request = UNNotificationRequest(
            identifier: Self.notificationIdentifier,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(
                timeInterval: interval,
                repeats: false
            )
        )
        try? await center.add(request)
    }
}
