import XCTest
@testable import LiftoffCore

final class RankingServiceTests: XCTestCase {
    func testEstimatedOneRepMaxUsesEpleyFormula() {
        XCTAssertEqual(
            RankingService.calculateE1RM(weight: 225, reps: 5),
            262.5,
            accuracy: 0.001
        )
    }

    func testEstimatedOneRepMaxRejectsInvalidInputs() {
        XCTAssertEqual(RankingService.calculateE1RM(weight: 0, reps: 5), 0)
        XCTAssertEqual(RankingService.calculateE1RM(weight: 225, reps: 0), 0)
    }

    func testRankThresholdBoundaries() {
        XCTAssertEqual(Rank.fromScore(0.59), .iron)
        XCTAssertEqual(Rank.fromScore(0.60), .bronze)
        XCTAssertEqual(Rank.fromScore(0.80), .silver)
        XCTAssertEqual(Rank.fromScore(1.00), .gold)
        XCTAssertEqual(Rank.fromScore(1.20), .platinum)
        XCTAssertEqual(Rank.fromScore(1.40), .diamond)
        XCTAssertEqual(Rank.fromScore(1.60), .titan)
    }

    func testProgressWithinGoldRank() {
        XCTAssertEqual(
            RankingService.progress(score: 1.10, rank: .gold),
            0.5,
            accuracy: 0.001
        )
    }

    func testXPBonusesAreIndependent() {
        XCTAssertEqual(
            RankingService.xp(isNewPersonalBest: false, extendsStreak: false),
            10
        )
        XCTAssertEqual(
            RankingService.xp(isNewPersonalBest: true, extendsStreak: true),
            55
        )
    }
}
