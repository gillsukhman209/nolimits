//
//  AppStats.swift
//  No Limits
//
//  Created by Sukhman Singh on 3/5/26.
//

import Foundation
import SwiftData

@Model
final class AppStats {
    var xp: Int
    var streak: Int
    var lastLoggedDate: Date?
    var totalLifts: Int
    var bestBenchE1RM: Double
    var bestSquatE1RM: Double
    var bestDeadliftE1RM: Double
    var bestOverallE1RM: Double

    init() {
        self.xp = 0
        self.streak = 0
        self.lastLoggedDate = nil
        self.totalLifts = 0
        self.bestBenchE1RM = 0
        self.bestSquatE1RM = 0
        self.bestDeadliftE1RM = 0
        self.bestOverallE1RM = 0
    }
}
