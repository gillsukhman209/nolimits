//
//  MuscleGroup.swift
//  No Limits
//
//  Created by Sukhman Singh on 3/5/26.
//

import Foundation

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
}

// MARK: - Exercise Catalog

struct Exercise: Identifiable {
    let name: String
    let muscleGroup: MuscleGroup
    var id: String { name }
}

struct ExerciseCatalog {

    static let all: [Exercise] = [
        // Upper Chest
        Exercise(name: "Incline Bench", muscleGroup: .upperChest),
        Exercise(name: "Incline Dumbbell Press", muscleGroup: .upperChest),
        Exercise(name: "Incline Fly", muscleGroup: .upperChest),

        // Chest
        Exercise(name: "Bench Press", muscleGroup: .chest),
        Exercise(name: "Dumbbell Bench", muscleGroup: .chest),
        Exercise(name: "Chest Fly", muscleGroup: .chest),
        Exercise(name: "Dips", muscleGroup: .chest),

        // Lats
        Exercise(name: "Barbell Row", muscleGroup: .lats),
        Exercise(name: "Lat Pulldown", muscleGroup: .lats),
        Exercise(name: "Pull-ups", muscleGroup: .lats),
        Exercise(name: "Seated Row", muscleGroup: .lats),
        Exercise(name: "T-Bar Row", muscleGroup: .lats),

        // Shoulders
        Exercise(name: "OHP", muscleGroup: .shoulders),
        Exercise(name: "Dumbbell Shoulder Press", muscleGroup: .shoulders),
        Exercise(name: "Lateral Raise", muscleGroup: .shoulders),
        Exercise(name: "Face Pull", muscleGroup: .shoulders),
        Exercise(name: "Front Raise", muscleGroup: .shoulders),

        // Triceps
        Exercise(name: "Tricep Pushdown", muscleGroup: .triceps),
        Exercise(name: "Skull Crushers", muscleGroup: .triceps),
        Exercise(name: "Close-Grip Bench", muscleGroup: .triceps),
        Exercise(name: "Overhead Tricep Extension", muscleGroup: .triceps),

        // Biceps
        Exercise(name: "Barbell Curl", muscleGroup: .biceps),
        Exercise(name: "Dumbbell Curl", muscleGroup: .biceps),
        Exercise(name: "Hammer Curl", muscleGroup: .biceps),
        Exercise(name: "Preacher Curl", muscleGroup: .biceps),

        // Quads
        Exercise(name: "Squat", muscleGroup: .quads),
        Exercise(name: "Leg Press", muscleGroup: .quads),
        Exercise(name: "Leg Extension", muscleGroup: .quads),
        Exercise(name: "Front Squat", muscleGroup: .quads),
        Exercise(name: "Bulgarian Split Squat", muscleGroup: .quads),

        // Hamstrings
        Exercise(name: "Deadlift", muscleGroup: .hamstrings),
        Exercise(name: "Romanian Deadlift", muscleGroup: .hamstrings),
        Exercise(name: "Leg Curl", muscleGroup: .hamstrings),
        Exercise(name: "Good Morning", muscleGroup: .hamstrings),

        // Legs (calves / general)
        Exercise(name: "Calf Raise", muscleGroup: .legs),
        Exercise(name: "Seated Calf Raise", muscleGroup: .legs),
        Exercise(name: "Lunges", muscleGroup: .legs),
        Exercise(name: "Step-ups", muscleGroup: .legs),

        // Abdominals
        Exercise(name: "Crunches", muscleGroup: .abdominals),
        Exercise(name: "Hanging Leg Raise", muscleGroup: .abdominals),
        Exercise(name: "Plank", muscleGroup: .abdominals),
        Exercise(name: "Cable Crunch", muscleGroup: .abdominals),
        Exercise(name: "Ab Rollout", muscleGroup: .abdominals),
    ]

    static var grouped: [(MuscleGroup, [Exercise])] {
        MuscleGroup.allCases.compactMap { group in
            let exercises = all.filter { $0.muscleGroup == group }
            return exercises.isEmpty ? nil : (group, exercises)
        }
    }

    static func muscleGroup(for exerciseName: String) -> MuscleGroup? {
        all.first { $0.name == exerciseName }?.muscleGroup
    }
}
