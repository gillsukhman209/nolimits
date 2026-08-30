import Foundation
import Observation
import SwiftData

struct SaveResult: Identifiable {
    let id = UUID()
    let exerciseName: String
    let muscleGroup: MuscleGroup
    let side: ExerciseSide
    let weight: Double
    let reps: Int
    let isNewPR: Bool
    let isFirstSet: Bool
}

@MainActor
@Observable
final class LogViewModel {
    var selectedExercise: Exercise?
    var selectedSide: ExerciseSide
    var weight: String
    var reps: String
    var bodyweight: Double
    var isSaving = false

    init(
        selectedExercise: Exercise? = nil,
        selectedSide: ExerciseSide? = nil
    ) {
        self.selectedExercise = selectedExercise
        self.selectedSide = selectedSide
            ?? (selectedExercise?.sideTracking == .separate ? .left : .both)
        self.weight = ""
        self.reps = ""
        self.bodyweight = 0
    }

    var numericWeight: Double { Double(weight) ?? 0 }
    var numericReps: Int { Int(reps) ?? 0 }

    var canSave: Bool {
        guard let exercise = selectedExercise,
              Double(weight) != nil,
              numericReps > 0,
              !isSaving else {
            return false
        }
        if exercise.sideTracking == .separate, selectedSide == .both {
            return false
        }
        switch exercise.loadType {
        case .externalWeight:
            return numericWeight > 0
        case .assistance:
            return numericWeight >= 0 && bodyweight > 0
        }
    }

    var currentE1RM: Double {
        guard let exercise = selectedExercise else { return 0 }
        return PerformanceService.estimatedMax(
            weight: numericWeight,
            reps: numericReps,
            bodyweight: bodyweight,
            loadType: exercise.loadType
        )
    }

    func adjustWeight(by amount: Double) {
        let updated = max(0, numericWeight + amount)
        weight = updated.formattedWeight
    }

    func adjustReps(by amount: Int) {
        reps = String(max(1, numericReps + amount))
    }

    func saveLift(context: ModelContext, now: Date = .now) -> SaveResult? {
        guard let exercise = selectedExercise, canSave else { return nil }
        isSaving = true

        let name = exercise.name
        let exerciseEntries = (try? context.fetch(
            FetchDescriptor<LiftEntry>(
                predicate: #Predicate<LiftEntry> { $0.liftType == name },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
        )) ?? []
        let entrySide = exercise.sideTracking == .separate ? selectedSide : .both
        let existingEntries = exerciseEntries.filter { $0.side == entrySide }
        let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first

        let previousBest = existingEntries.map(\.e1RM).max() ?? 0
        let newE1RM = currentE1RM
        let isNewPR = PerformanceService.isPersonalBest(
            candidate: newE1RM,
            previousBest: previousBest
        )
        let entry = LiftEntry(
            date: now,
            liftType: exercise.name,
            muscleGroup: exercise.muscleGroup,
            weight: numericWeight,
            reps: numericReps,
            loadType: exercise.loadType,
            side: entrySide,
            bodyweight: profile?.bodyweight ?? 0
        )
        context.insert(entry)
        try? context.save()
        AppStatsSynchronizer.rebuild(context: context)

        let result = SaveResult(
            exerciseName: exercise.name,
            muscleGroup: exercise.muscleGroup,
            side: entrySide,
            weight: numericWeight,
            reps: numericReps,
            isNewPR: isNewPR,
            isFirstSet: existingEntries.isEmpty
        )
        isSaving = false
        return result
    }
}
