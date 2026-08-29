import Foundation
import XCTest
@testable import LiftoffCore

final class LiftAnalyticsTests: XCTestCase {
    func testInsightsReportWeeklyConsistencyAndImprovement() {
        let calendar = Calendar(identifier: .gregorian)
        let now = Date(timeIntervalSince1970: 2_000_000)
        let older = LiftEntry(
            date: calendar.date(byAdding: .day, value: -2, to: now)!,
            liftType: "Bench Press",
            muscleGroup: .chest,
            weight: 100,
            reps: 5
        )
        let latest = LiftEntry(
            date: now,
            liftType: "Bench Press",
            muscleGroup: .chest,
            weight: 110,
            reps: 5
        )

        let insights = LiftAnalytics.insights(
            entries: [latest, older],
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(insights.first?.kind, .consistency)
        XCTAssertTrue(insights.contains { $0.kind == .improvement })
        XCTAssertTrue(insights.first?.detail.contains("2 of the last 7 days") == true)
    }

    func testInsightsReportMeaningfulSideImbalance() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let left = LiftEntry(
            date: now,
            liftType: "Dumbbell Curl",
            muscleGroup: .biceps,
            weight: 20,
            reps: 8,
            side: .left
        )
        let right = LiftEntry(
            date: now,
            liftType: "Dumbbell Curl",
            muscleGroup: .biceps,
            weight: 25,
            reps: 8,
            side: .right
        )

        let insight = LiftAnalytics.insights(entries: [left, right], now: now)
            .first { $0.kind == .balance }

        XCTAssertNotNil(insight)
        XCTAssertTrue(insight?.detail.contains("left") == true)
    }

    func testNoInsightsWithoutEntries() {
        XCTAssertTrue(LiftAnalytics.insights(entries: []).isEmpty)
    }
}
