//
//  CustomExercise.swift
//  No Limits
//
//  Created by Sukhman Singh on 3/6/26.
//

import Foundation
import SwiftData

@Model
final class CustomExercise {
    var id: UUID
    var name: String
    var muscleGroupRaw: String
    var loadTypeRaw: String?
    var sideTrackingRaw: String?

    var muscleGroup: MuscleGroup? {
        MuscleGroup(rawValue: muscleGroupRaw)
    }

    var loadType: ExerciseLoadType {
        ExerciseLoadType(rawValue: loadTypeRaw ?? "") ?? .externalWeight
    }

    var sideTracking: ExerciseSideTracking {
        ExerciseSideTracking(rawValue: sideTrackingRaw ?? "") ?? .combined
    }

    init(
        name: String,
        muscleGroup: MuscleGroup,
        loadType: ExerciseLoadType = .externalWeight,
        sideTracking: ExerciseSideTracking = .combined
    ) {
        self.id = UUID()
        self.name = name
        self.muscleGroupRaw = muscleGroup.rawValue
        self.loadTypeRaw = loadType.rawValue
        self.sideTrackingRaw = sideTracking.rawValue
    }
}
