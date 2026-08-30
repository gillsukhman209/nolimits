//
//  MuscleGroup.swift
//  No Limits
//
//  Created by Sukhman Singh on 3/5/26.
//

import Foundation
import SwiftData

enum MuscleGroup: String, CaseIterable, Codable, Identifiable {
    case upperChest  = "Upper Chest"
    case chest       = "Chest"
    case lats        = "Lats"
    case shoulders   = "Shoulders"
    case triceps     = "Triceps"
    case biceps      = "Biceps"
    case quads       = "Quads"
    case hamstrings  = "Hamstrings"
    case legs        = "Legs"
    case abdominals  = "Abdominals"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .upperChest, .chest: return "figure.strengthtraining.traditional"
        case .lats: return "figure.rower"
        case .shoulders: return "figure.cross.training"
        case .triceps, .biceps: return "dumbbell.fill"
        case .quads, .hamstrings, .legs: return "figure.run"
        case .abdominals: return "figure.core.training"
        }
    }
}

// MARK: - Exercise Catalog

struct Exercise: Identifiable, Equatable {
    let name: String
    let muscleGroup: MuscleGroup
    let isCustom: Bool
    let loadType: ExerciseLoadType
    let sideTracking: ExerciseSideTracking

    var id: String { name }

    init(
        name: String,
        muscleGroup: MuscleGroup,
        isCustom: Bool = false,
        loadType: ExerciseLoadType = .externalWeight,
        sideTracking: ExerciseSideTracking = .combined
    ) {
        self.name = name
        self.muscleGroup = muscleGroup
        self.isCustom = isCustom
        self.loadType = loadType
        self.sideTracking = sideTracking
    }

    static func == (lhs: Exercise, rhs: Exercise) -> Bool {
        lhs.name == rhs.name
    }
}

struct ExerciseCatalog {

    static let builtIn: [Exercise] = [
        // Upper Chest
        Exercise(name: "Incline Bench", muscleGroup: .upperChest),
        Exercise(name: "Incline Dumbbell Press", muscleGroup: .upperChest),
        Exercise(name: "Incline Fly", muscleGroup: .upperChest),

        // Chest
        Exercise(name: "Bench Press", muscleGroup: .chest),
        Exercise(name: "Dumbbell Bench", muscleGroup: .chest),
        Exercise(name: "Chest Fly", muscleGroup: .chest),
        Exercise(name: "Dips", muscleGroup: .chest),
        Exercise(
            name: "Assisted Dip",
            muscleGroup: .chest,
            loadType: .assistance
        ),

        // Lats
        Exercise(name: "Barbell Row", muscleGroup: .lats),
        Exercise(name: "Lat Pulldown", muscleGroup: .lats),
        Exercise(name: "Pull-ups", muscleGroup: .lats),
        Exercise(
            name: "Assisted Pull-up",
            muscleGroup: .lats,
            loadType: .assistance
        ),
        Exercise(
            name: "Single-Arm Lat Pulldown",
            muscleGroup: .lats,
            sideTracking: .separate
        ),
        Exercise(
            name: "Single-Arm Cable Row",
            muscleGroup: .lats,
            sideTracking: .separate
        ),
        Exercise(name: "Seated Row", muscleGroup: .lats),
        Exercise(name: "T-Bar Row", muscleGroup: .lats),

        // Shoulders
        Exercise(name: "OHP", muscleGroup: .shoulders),
        Exercise(name: "Dumbbell Shoulder Press", muscleGroup: .shoulders),
        Exercise(
            name: "Lateral Raise",
            muscleGroup: .shoulders,
            sideTracking: .separate
        ),
        Exercise(name: "Face Pull", muscleGroup: .shoulders),
        Exercise(
            name: "Front Raise",
            muscleGroup: .shoulders,
            sideTracking: .separate
        ),
        Exercise(
            name: "Single-Arm Shoulder Press",
            muscleGroup: .shoulders,
            sideTracking: .separate
        ),

        // Triceps
        Exercise(name: "Tricep Pushdown", muscleGroup: .triceps),
        Exercise(name: "Skull Crushers", muscleGroup: .triceps),
        Exercise(name: "Close-Grip Bench", muscleGroup: .triceps),
        Exercise(name: "Overhead Tricep Extension", muscleGroup: .triceps),
        Exercise(
            name: "Single-Arm Tricep Extension",
            muscleGroup: .triceps,
            sideTracking: .separate
        ),

        // Biceps
        Exercise(name: "Barbell Curl", muscleGroup: .biceps),
        Exercise(
            name: "Dumbbell Curl",
            muscleGroup: .biceps,
            sideTracking: .separate
        ),
        Exercise(
            name: "Hammer Curl",
            muscleGroup: .biceps,
            sideTracking: .separate
        ),
        Exercise(name: "Preacher Curl", muscleGroup: .biceps),
        Exercise(
            name: "Concentration Curl",
            muscleGroup: .biceps,
            sideTracking: .separate
        ),

        // Quads
        Exercise(name: "Squat", muscleGroup: .quads),
        Exercise(name: "Leg Press", muscleGroup: .quads),
        Exercise(name: "Leg Extension", muscleGroup: .quads),
        Exercise(name: "Front Squat", muscleGroup: .quads),
        Exercise(name: "Bulgarian Split Squat", muscleGroup: .quads),
        Exercise(
            name: "Single-Leg Press",
            muscleGroup: .quads,
            sideTracking: .separate
        ),
        Exercise(
            name: "Single-Leg Extension",
            muscleGroup: .quads,
            sideTracking: .separate
        ),

        // Hamstrings
        Exercise(name: "Deadlift", muscleGroup: .hamstrings),
        Exercise(name: "Romanian Deadlift", muscleGroup: .hamstrings),
        Exercise(name: "Leg Curl", muscleGroup: .hamstrings),
        Exercise(name: "Good Morning", muscleGroup: .hamstrings),
        Exercise(
            name: "Single-Leg Curl",
            muscleGroup: .hamstrings,
            sideTracking: .separate
        ),

        // Legs (calves / general)
        Exercise(name: "Calf Raise", muscleGroup: .legs),
        Exercise(name: "Seated Calf Raise", muscleGroup: .legs),
        Exercise(
            name: "Lunges",
            muscleGroup: .legs,
            sideTracking: .separate
        ),
        Exercise(
            name: "Step-ups",
            muscleGroup: .legs,
            sideTracking: .separate
        ),
        Exercise(
            name: "Single-Leg Calf Raise",
            muscleGroup: .legs,
            sideTracking: .separate
        ),

        // Abdominals
        Exercise(name: "Crunches", muscleGroup: .abdominals),
        Exercise(name: "Hanging Leg Raise", muscleGroup: .abdominals),
        Exercise(name: "Plank", muscleGroup: .abdominals),
        Exercise(name: "Cable Crunch", muscleGroup: .abdominals),
        Exercise(name: "Ab Rollout", muscleGroup: .abdominals),
    ]

    /// The old `all` property — now returns built-in only (for backward compat).
    /// Use `allExercises(context:)` to include custom exercises.
    static var all: [Exercise] { builtIn }

    static func allExercises(context: ModelContext) -> [Exercise] {
        let custom = (try? context.fetch(FetchDescriptor<CustomExercise>())) ?? []
        let customExercises = custom.compactMap { ce -> Exercise? in
            guard let muscle = ce.muscleGroup else { return nil }
            return Exercise(
                name: ce.name,
                muscleGroup: muscle,
                isCustom: true,
                loadType: ce.loadType,
                sideTracking: ce.sideTracking
            )
        }
        return builtIn + customExercises
    }

    static func grouped(context: ModelContext) -> [(MuscleGroup, [Exercise])] {
        let exercises = allExercises(context: context)
        return MuscleGroup.allCases.compactMap { group in
            let matching = exercises.filter { $0.muscleGroup == group }
            return matching.isEmpty ? nil : (group, matching)
        }
    }

    static var grouped: [(MuscleGroup, [Exercise])] {
        MuscleGroup.allCases.compactMap { group in
            let exercises = builtIn.filter { $0.muscleGroup == group }
            return exercises.isEmpty ? nil : (group, exercises)
        }
    }

    static func muscleGroup(for exerciseName: String) -> MuscleGroup? {
        builtIn.first { $0.name == exerciseName }?.muscleGroup
    }

    static func exercise(named exerciseName: String) -> Exercise? {
        builtIn.first { $0.name == exerciseName }
    }

    static func exercise(
        named exerciseName: String,
        context: ModelContext
    ) -> Exercise? {
        allExercises(context: context).first { $0.name == exerciseName }
    }
}
