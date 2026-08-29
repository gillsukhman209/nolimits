import XCTest
@testable import LiftoffCore

final class PerformanceServiceTests: XCTestCase {
    func testExternalWeightUsesEpleyEstimate() {
        XCTAssertEqual(
            PerformanceService.estimatedMax(
                weight: 100,
                reps: 6,
                bodyweight: 180,
                loadType: .externalWeight
            ),
            120,
            accuracy: 0.001
        )
    }

    func testAssistanceUsesEffectiveBodyweightLoad() {
        XCTAssertEqual(
            PerformanceService.estimatedMax(
                weight: 50,
                reps: 6,
                bodyweight: 200,
                loadType: .assistance
            ),
            180,
            accuracy: 0.001
        )
    }

    func testLowerAssistanceProducesHigherPerformance() {
        let easier = PerformanceService.estimatedMax(
            weight: 80,
            reps: 8,
            bodyweight: 200,
            loadType: .assistance
        )
        let harder = PerformanceService.estimatedMax(
            weight: 40,
            reps: 8,
            bodyweight: 200,
            loadType: .assistance
        )

        XCTAssertGreaterThan(harder, easier)
    }

    func testAssistanceAtBodyweightHasNoEffectiveLoad() {
        XCTAssertEqual(
            PerformanceService.estimatedMax(
                weight: 200,
                reps: 8,
                bodyweight: 200,
                loadType: .assistance
            ),
            0
        )
    }

    func testTrainingVolumeAlsoReversesAssistance() {
        XCTAssertEqual(
            PerformanceService.trainingVolume(
                weight: 50,
                reps: 10,
                bodyweight: 200,
                loadType: .assistance
            ),
            1_500
        )
    }
}
