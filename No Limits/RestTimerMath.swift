import Foundation

enum RestTimerMath {
    static func remainingSeconds(endDate: Date?, now: Date) -> Int {
        guard let endDate else { return 0 }
        return max(0, Int(ceil(endDate.timeIntervalSince(now))))
    }

    static func progress(remainingSeconds: Int, durationSeconds: Int) -> Double {
        guard durationSeconds > 0 else { return 0 }
        return min(max(Double(remainingSeconds) / Double(durationSeconds), 0), 1)
    }

    static func formattedTime(seconds: Int) -> String {
        let safeSeconds = max(0, seconds)
        return String(format: "%d:%02d", safeSeconds / 60, safeSeconds % 60)
    }
}
