import Foundation
import SwiftUI

enum ExperienceLevel: String, CaseIterable, Identifiable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .beginner: return "New to consistent lifting"
        case .intermediate: return "Comfortable with core lifts"
        case .advanced: return "Experienced and performance-focused"
        }
    }
}

enum GoalType: String, CaseIterable, Identifiable {
    case strength = "Strength"
    case muscle = "Muscle"
    case fatLoss = "Fat loss"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .strength: return "Move heavier loads"
        case .muscle: return "Build size and shape"
        case .fatLoss: return "Stay lean while lifting"
        }
    }
}

enum LiftType: String, CaseIterable, Identifiable {
    case bench = "Bench"
    case squat = "Squat"
    case deadlift = "Deadlift"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .bench: return "figure.strengthtraining.traditional"
        case .squat: return "figure.strengthtraining.functional"
        case .deadlift: return "bolt.heart"
        }
    }
}

enum RankTier: String, CaseIterable {
    case iron = "Iron"
    case bronze = "Bronze"
    case silver = "Silver"
    case gold = "Gold"
    case platinum = "Platinum"
    case diamond = "Diamond"
    case titan = "Titan"

    var gradient: LinearGradient {
        switch self {
        case .iron:
            return LinearGradient(colors: [Color.gray.opacity(0.7), Color.gray.opacity(0.45)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .bronze:
            return LinearGradient(colors: [Color(red: 0.67, green: 0.42, blue: 0.25), Color(red: 0.49, green: 0.30, blue: 0.18)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .silver:
            return LinearGradient(colors: [Color(red: 0.75, green: 0.80, blue: 0.88), Color(red: 0.56, green: 0.62, blue: 0.73)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .gold:
            return LinearGradient(colors: [Color(red: 0.98, green: 0.82, blue: 0.33), Color(red: 0.83, green: 0.58, blue: 0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .platinum:
            return LinearGradient(colors: [Color(red: 0.55, green: 0.88, blue: 0.84), Color(red: 0.33, green: 0.70, blue: 0.74)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .diamond:
            return LinearGradient(colors: [Color(red: 0.63, green: 0.85, blue: 1.0), Color(red: 0.42, green: 0.64, blue: 0.99)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .titan:
            return LinearGradient(colors: [Color(red: 1.0, green: 0.47, blue: 0.34), Color(red: 0.98, green: 0.24, blue: 0.43)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

struct HomeSnapshot {
    var rank: RankTier
    var score: Double
    var nextRankProgress: Double
    var streakDays: Int
    var xp: Int
    var todaysLift: LiftType
    var todaysWeight: Int
    var todaysReps: Int
}
