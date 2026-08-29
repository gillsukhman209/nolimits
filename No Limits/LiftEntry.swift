//
//  LiftEntry.swift
//  No Limits
//
//  Created by Sukhman Singh on 3/5/26.
//

import Foundation
import SwiftData

@Model
final class LiftEntry {
    var id: UUID
    var date: Date
    var liftType: String
    var muscleGroupRaw: String
    var weight: Double
    var reps: Int
    var e1RM: Double
    var loadTypeRaw: String?
    var sideRaw: String?
    var bodyweightAtLog: Double?

    var muscleGroup: MuscleGroup? {
        MuscleGroup(rawValue: muscleGroupRaw)
    }

    var loadType: ExerciseLoadType {
        ExerciseLoadType(rawValue: loadTypeRaw ?? "") ?? .externalWeight
    }

    var side: ExerciseSide {
        ExerciseSide(rawValue: sideRaw ?? "") ?? .both
    }

    var performanceKey: String {
        "\(liftType)|\(side.rawValue)"
    }

    init(
        date: Date = .now,
        liftType: String,
        muscleGroup: MuscleGroup,
        weight: Double,
        reps: Int,
        loadType: ExerciseLoadType = .externalWeight,
        side: ExerciseSide = .both,
        bodyweight: Double = 0
    ) {
        self.id = UUID()
        self.date = date
        self.liftType = liftType
        self.muscleGroupRaw = muscleGroup.rawValue
        self.weight = weight
        self.reps = reps
        self.loadTypeRaw = loadType.rawValue
        self.sideRaw = side.rawValue
        self.bodyweightAtLog = bodyweight > 0 ? bodyweight : nil
        self.e1RM = PerformanceService.estimatedMax(
            weight: weight,
            reps: reps,
            bodyweight: bodyweight,
            loadType: loadType
        )
    }
}
