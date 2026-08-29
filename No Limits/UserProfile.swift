//
//  UserProfile.swift
//  No Limits
//
//  Created by Sukhman Singh on 3/5/26.
//

import Foundation
import SwiftData

@Model
final class UserProfile {
    var experience: String
    var goal: String
    var bodyweight: Double
    var height: Double
    var createdAt: Date

    init(
        experience: String,
        goal: String,
        bodyweight: Double,
        height: Double,
        createdAt: Date = .now
    ) {
        self.experience = experience
        self.goal = goal
        self.bodyweight = bodyweight
        self.height = height
        self.createdAt = createdAt
    }
}
