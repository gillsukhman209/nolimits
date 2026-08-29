import Foundation
import XCTest
@testable import LiftoffCore

final class RestTimerMathTests: XCTestCase {
    func testRemainingSecondsRoundsUp() {
        let now = Date(timeIntervalSince1970: 1_000)
        XCTAssertEqual(
            RestTimerMath.remainingSeconds(
                endDate: now.addingTimeInterval(149.2),
                now: now
            ),
            150
        )
    }

    func testExpiredTimerReturnsZero() {
        let now = Date(timeIntervalSince1970: 1_000)
        XCTAssertEqual(
            RestTimerMath.remainingSeconds(
                endDate: now.addingTimeInterval(-1),
                now: now
            ),
            0
        )
    }

    func testProgressIsClamped() {
        XCTAssertEqual(RestTimerMath.progress(remainingSeconds: 75, durationSeconds: 150), 0.5)
        XCTAssertEqual(RestTimerMath.progress(remainingSeconds: 200, durationSeconds: 150), 1)
        XCTAssertEqual(RestTimerMath.progress(remainingSeconds: -1, durationSeconds: 150), 0)
    }

    func testFormattedTime() {
        XCTAssertEqual(RestTimerMath.formattedTime(seconds: 150), "2:30")
        XCTAssertEqual(RestTimerMath.formattedTime(seconds: 9), "0:09")
    }
}
