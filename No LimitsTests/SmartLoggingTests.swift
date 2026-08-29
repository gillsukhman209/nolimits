import SwiftData
import XCTest
@testable import LiftoffCore

@MainActor
final class SmartLoggingTests: XCTestCase {
    func testAssistedLiftRewardsLowerAssistance() throws {
        let container = try makeContainer(bodyweight: 200)
        let context = container.mainContext
        let exercise = Exercise(
            name: "Assisted Pull-up",
            muscleGroup: .lats,
            loadType: .assistance
        )

        let first = makeViewModel(
            exercise: exercise,
            weight: "80",
            reps: "6",
            bodyweight: 200
        )
        let firstResult = try XCTUnwrap(first.saveLift(context: context))
        XCTAssertFalse(firstResult.isNewPR)

        let second = makeViewModel(
            exercise: exercise,
            weight: "40",
            reps: "6",
            bodyweight: 200
        )
        let secondResult = try XCTUnwrap(second.saveLift(context: context))
        XCTAssertTrue(secondResult.isNewPR)

        let entries = try context.fetch(FetchDescriptor<LiftEntry>())
        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(
            try XCTUnwrap(entries.map(\.e1RM).max()),
            192,
            accuracy: 0.001
        )
        XCTAssertTrue(entries.allSatisfy { $0.loadType == .assistance })
    }

    func testLeftAndRightPersonalBestsStayIndependent() throws {
        let container = try makeContainer(bodyweight: 180)
        let context = container.mainContext
        let exercise = Exercise(
            name: "Dumbbell Curl",
            muscleGroup: .biceps,
            sideTracking: .separate
        )

        let left = makeViewModel(
            exercise: exercise,
            side: .left,
            weight: "20",
            reps: "10",
            bodyweight: 180
        )
        XCTAssertFalse(try XCTUnwrap(left.saveLift(context: context)).isNewPR)

        let right = makeViewModel(
            exercise: exercise,
            side: .right,
            weight: "15",
            reps: "10",
            bodyweight: 180
        )
        XCTAssertFalse(try XCTUnwrap(right.saveLift(context: context)).isNewPR)

        let strongerLeft = makeViewModel(
            exercise: exercise,
            side: .left,
            weight: "22",
            reps: "10",
            bodyweight: 180
        )
        let result = try XCTUnwrap(strongerLeft.saveLift(context: context))
        XCTAssertTrue(result.isNewPR)
        XCTAssertEqual(result.side, .left)

        let entries = try context.fetch(FetchDescriptor<LiftEntry>())
        XCTAssertEqual(entries.filter { $0.side == .left }.count, 2)
        XCTAssertEqual(entries.filter { $0.side == .right }.count, 1)
    }

    func testLegacyEntryDefaultsToStandardCombinedTracking() {
        let entry = LiftEntry(
            liftType: "Bench Press",
            muscleGroup: .chest,
            weight: 185,
            reps: 5
        )
        entry.loadTypeRaw = nil
        entry.sideRaw = nil

        XCTAssertEqual(entry.loadType, .externalWeight)
        XCTAssertEqual(entry.side, .both)
    }

    func testCustomExercisePersistsTrackingOptions() {
        let custom = CustomExercise(
            name: "Single-Arm Machine Row",
            muscleGroup: .lats,
            loadType: .assistance,
            sideTracking: .separate
        )

        XCTAssertEqual(custom.loadType, .assistance)
        XCTAssertEqual(custom.sideTracking, .separate)
    }

    private func makeContainer(bodyweight: Double) throws -> ModelContainer {
        let schema = Schema([
            UserProfile.self,
            LiftEntry.self,
            AppStats.self,
            CustomExercise.self,
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        let container = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
        container.mainContext.insert(
            UserProfile(
                experience: "Intermediate",
                goal: "Strength",
                bodyweight: bodyweight,
                height: 70
            )
        )
        try container.mainContext.save()
        return container
    }

    private func makeViewModel(
        exercise: Exercise,
        side: ExerciseSide = .both,
        weight: String,
        reps: String,
        bodyweight: Double
    ) -> LogViewModel {
        let viewModel = LogViewModel(
            selectedExercise: exercise,
            selectedSide: side
        )
        viewModel.weight = weight
        viewModel.reps = reps
        viewModel.bodyweight = bodyweight
        return viewModel
    }
}
