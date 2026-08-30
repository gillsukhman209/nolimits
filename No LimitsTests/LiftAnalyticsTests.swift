import Foundation
import XCTest
@testable import LiftoffCore

final class LiftAnalyticsTests: XCTestCase {
    func testRecentTrendUsesAveragesFromEarlyAndRecentSets() {
        let entries = [100.0, 102, 104, 120, 122, 124].enumerated().map { index, weight in
            LiftEntry(
                date: Date(timeIntervalSince1970: Double(index)),
                liftType: "Bench Press",
                muscleGroup: .chest,
                weight: weight,
                reps: 5
            )
        }

        let trend = LiftAnalytics.recentTrendPercent(entries: entries)

        XCTAssertEqual(trend ?? 0, 19.6078, accuracy: 0.001)
    }

    func testWeightRepRecordsKeepBestRepsAtEachWeightAndSide() {
        let entries = [
            LiftEntry(liftType: "Curl", muscleGroup: .biceps, weight: 25, reps: 8, side: .left),
            LiftEntry(liftType: "Curl", muscleGroup: .biceps, weight: 25, reps: 10, side: .left),
            LiftEntry(liftType: "Curl", muscleGroup: .biceps, weight: 25, reps: 9, side: .right),
            LiftEntry(liftType: "Curl", muscleGroup: .biceps, weight: 30, reps: 6, side: .left),
        ]

        let records = LiftAnalytics.weightRepRecords(entries: entries)

        XCTAssertEqual(records.count, 3)
        XCTAssertEqual(records.first?.weight, 30)
        XCTAssertEqual(records.first { $0.weight == 25 && $0.side == .left }?.reps, 10)
        XCTAssertEqual(records.first { $0.weight == 25 && $0.side == .left }?.setCount, 2)
    }

    func testAssistanceRecordsSortLowerAssistanceFirst() {
        let entries = [
            LiftEntry(liftType: "Assisted Pull-up", muscleGroup: .lats, weight: 60, reps: 8, loadType: .assistance, bodyweight: 180),
            LiftEntry(liftType: "Assisted Pull-up", muscleGroup: .lats, weight: 40, reps: 6, loadType: .assistance, bodyweight: 180),
        ]

        let records = LiftAnalytics.weightRepRecords(entries: entries)

        XCTAssertEqual(records.map(\.weight), [40, 60])
    }

    func testPersonalBestIDsTrackProgressSeparatelyBySide() {
        let leftBaseline = LiftEntry(liftType: "Curl", muscleGroup: .biceps, weight: 20, reps: 8, side: .left)
        leftBaseline.date = Date(timeIntervalSince1970: 1)
        let rightBaseline = LiftEntry(liftType: "Curl", muscleGroup: .biceps, weight: 25, reps: 8, side: .right)
        rightBaseline.date = Date(timeIntervalSince1970: 2)
        let leftRecord = LiftEntry(liftType: "Curl", muscleGroup: .biceps, weight: 22.5, reps: 8, side: .left)
        leftRecord.date = Date(timeIntervalSince1970: 3)
        let leftMiss = LiftEntry(liftType: "Curl", muscleGroup: .biceps, weight: 20, reps: 8, side: .left)
        leftMiss.date = Date(timeIntervalSince1970: 4)

        let ids = LiftAnalytics.personalBestEntryIDs(
            entries: [leftMiss, leftRecord, rightBaseline, leftBaseline]
        )

        XCTAssertTrue(ids.contains(leftBaseline.id))
        XCTAssertTrue(ids.contains(rightBaseline.id))
        XCTAssertTrue(ids.contains(leftRecord.id))
        XCTAssertFalse(ids.contains(leftMiss.id))
    }

    func testTrainingReviewDatasetContainsExerciseRecordsAndAssistanceContext() {
        let assisted = LiftEntry(
            liftType: "Assisted Pull-up",
            muscleGroup: .lats,
            weight: 40,
            reps: 8,
            loadType: .assistance,
            bodyweight: 180
        )

        let dataset = TrainingReviewDataBuilder.make(
            entries: [assisted],
            bodyweight: 180
        )

        XCTAssertTrue(dataset.promptData.contains("Assisted Pull-up"))
        XCTAssertTrue(dataset.promptData.contains("40lb assist:8 reps"))
        XCTAssertTrue(dataset.promptData.contains("estimated max"))
    }

    func testTrainingReviewFallbackCallsOutImprovingExercise() {
        let baseline = LiftEntry(
            date: Date(timeIntervalSince1970: 1),
            liftType: "Squat",
            muscleGroup: .quads,
            weight: 100,
            reps: 5
        )
        let latest = LiftEntry(
            date: Date(timeIntervalSince1970: 2),
            liftType: "Squat",
            muscleGroup: .quads,
            weight: 120,
            reps: 5
        )

        let dataset = TrainingReviewDataBuilder.make(
            entries: [latest, baseline],
            bodyweight: 180,
            now: Date(timeIntervalSince1970: 3)
        )

        XCTAssertTrue(dataset.fallbackReview.contains("## Improving"))
        XCTAssertTrue(dataset.fallbackReview.contains("**Squat:** up"))
    }

    func testWeeklyAuditIncludesOnlyCurrentSevenDayWindow() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = Date(timeIntervalSince1970: 2_000_000)
        let today = LiftEntry(
            date: now,
            liftType: "Bench Press",
            muscleGroup: .chest,
            weight: 100,
            reps: 5
        )
        let sixDaysAgo = LiftEntry(
            date: calendar.date(byAdding: .day, value: -6, to: now)!,
            liftType: "Squat",
            muscleGroup: .quads,
            weight: 150,
            reps: 5
        )
        let sevenDaysAgo = LiftEntry(
            date: calendar.date(byAdding: .day, value: -7, to: now)!,
            liftType: "Barbell Row",
            muscleGroup: .lats,
            weight: 100,
            reps: 8
        )

        let audit = LiftAnalytics.weeklyTrainingAudit(
            entries: [today, sixDaysAgo, sevenDaysAgo],
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(audit.setCount, 2)
        XCTAssertEqual(audit.trainingDays, 2)
        XCTAssertEqual(audit.regionSetCounts[.push], 1)
        XCTAssertEqual(audit.regionSetCounts[.lowerBody], 1)
        XCTAssertEqual(audit.regionSetCounts[.pull], 0)
    }

    func testWeeklyAuditFlagsConcentratedMuscleAndMissingCoverage() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let entries = (0..<8).map { index in
            LiftEntry(
                date: now.addingTimeInterval(Double(-index * 60)),
                liftType: "Dumbbell Curl",
                muscleGroup: .biceps,
                weight: 25,
                reps: 10,
                side: index.isMultiple(of: 2) ? .left : .right
            )
        }

        let audit = LiftAnalytics.weeklyTrainingAudit(entries: entries, now: now)

        XCTAssertEqual(audit.muscleStats.first { $0.muscleGroup == .biceps }?.share, 1)
        XCTAssertTrue(audit.highConcentrationMuscleGroups.contains(.biceps))
        XCTAssertTrue(audit.missingMuscleGroups.contains(.quads))
        XCTAssertEqual(audit.regionSetCounts[.pull], 8)
    }

    func testTrainingReviewContainsWeeklyCoverageAndWorkloadWarnings() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let entries = (0..<8).map { index in
            LiftEntry(
                date: now.addingTimeInterval(Double(-index * 60)),
                liftType: "Bench Press",
                muscleGroup: .chest,
                weight: 100,
                reps: 8
            )
        }

        let dataset = TrainingReviewDataBuilder.make(entries: entries, bodyweight: 180, now: now)

        XCTAssertTrue(dataset.promptData.contains("COMPLETE WEEKLY AUDIT"))
        XCTAssertTrue(dataset.promptData.contains("Chest: 8 sets"))
        XCTAssertTrue(dataset.fallbackReview.contains("## Muscle coverage"))
        XCTAssertTrue(dataset.fallbackReview.contains("Potential overemphasis: Chest"))
        XCTAssertTrue(dataset.fallbackReview.contains("No direct lower-body sets"))
    }

    func testNearestChartEntrySnapsToClosestDate() {
        let first = LiftEntry(
            date: Date(timeIntervalSince1970: 100),
            liftType: "Bench Press",
            muscleGroup: .chest,
            weight: 100,
            reps: 5
        )
        let second = LiftEntry(
            date: Date(timeIntervalSince1970: 200),
            liftType: "Bench Press",
            muscleGroup: .chest,
            weight: 110,
            reps: 5
        )

        let nearest = LiftAnalytics.nearestEntry(
            to: Date(timeIntervalSince1970: 180),
            entries: [first, second]
        )

        XCTAssertEqual(nearest?.id, second.id)
    }

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
