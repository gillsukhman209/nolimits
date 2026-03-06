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

    // Per-muscle best e1RM
    var bestUpperChest: Double
    var bestChest: Double
    var bestLats: Double
    var bestShoulders: Double
    var bestTriceps: Double
    var bestBiceps: Double
    var bestQuads: Double
    var bestHamstrings: Double
    var bestLegs: Double
    var bestAbdominals: Double

    init() {
        self.xp = 0
        self.streak = 0
        self.lastLoggedDate = nil
        self.totalLifts = 0
        self.bestUpperChest = 0
        self.bestChest = 0
        self.bestLats = 0
        self.bestShoulders = 0
        self.bestTriceps = 0
        self.bestBiceps = 0
        self.bestQuads = 0
        self.bestHamstrings = 0
        self.bestLegs = 0
        self.bestAbdominals = 0
    }

    func bestE1RM(for muscle: MuscleGroup) -> Double {
        switch muscle {
        case .upperChest: return bestUpperChest
        case .chest:      return bestChest
        case .lats:       return bestLats
        case .shoulders:  return bestShoulders
        case .triceps:    return bestTriceps
        case .biceps:     return bestBiceps
        case .quads:      return bestQuads
        case .hamstrings: return bestHamstrings
        case .legs:       return bestLegs
        case .abdominals: return bestAbdominals
        }
    }

    func setBestE1RM(for muscle: MuscleGroup, value: Double) {
        switch muscle {
        case .upperChest: bestUpperChest = value
        case .chest:      bestChest = value
        case .lats:       bestLats = value
        case .shoulders:  bestShoulders = value
        case .triceps:    bestTriceps = value
        case .biceps:     bestBiceps = value
        case .quads:      bestQuads = value
        case .hamstrings: bestHamstrings = value
        case .legs:       bestLegs = value
        case .abdominals: bestAbdominals = value
        }
    }
}
