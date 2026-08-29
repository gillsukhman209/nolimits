import XCTest
@testable import LiftoffCore

final class StreakServiceTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testCurrentStreakCountsUniqueConsecutiveDays() {
        let today = Date(timeIntervalSince1970: 1_721_865_600)
        let dates = [
            today,
            today.addingTimeInterval(-3_600),
            today.addingTimeInterval(-86_400),
            today.addingTimeInterval(-172_800),
        ]

        XCTAssertEqual(
            StreakService.currentStreak(
                logDates: dates,
                asOf: today,
                calendar: calendar
            ),
            3
        )
    }

    func testCurrentStreakAllowsYesterdayAsAnchor() {
        let today = Date(timeIntervalSince1970: 1_721_865_600)
        let yesterday = today.addingTimeInterval(-86_400)

        XCTAssertEqual(
            StreakService.currentStreak(
                logDates: [yesterday],
                asOf: today,
                calendar: calendar
            ),
            1
        )
    }

    func testCurrentStreakIsZeroAfterGap() {
        let today = Date(timeIntervalSince1970: 1_721_865_600)
        let twoDaysAgo = today.addingTimeInterval(-172_800)

        XCTAssertEqual(
            StreakService.currentStreak(
                logDates: [twoDaysAgo],
                asOf: today,
                calendar: calendar
            ),
            0
        )
    }
}
