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

    var muscleGroup: MuscleGroup? {
        MuscleGroup(rawValue: muscleGroupRaw)
    }

    init(name: String, muscleGroup: MuscleGroup) {
        self.id = UUID()
        self.name = name
        self.muscleGroupRaw = muscleGroup.rawValue
    }
}
