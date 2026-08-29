import Foundation

struct RankingService {
    static func calculateE1RM(weight: Double, reps: Int) -> Double {
        guard weight > 0, reps > 0 else { return 0 }
        return weight * (1.0 + Double(reps) / 30.0)
    }

    static func calculateScore(e1RM: Double, bodyweight: Double) -> Double {
        guard bodyweight > 0 else { return 0 }
        return e1RM / bodyweight
    }

    static func progress(score: Double, rank: Rank) -> Double {
        guard rank != .titan else { return 1 }
        let range = rank.upperBound - rank.lowerBound
        guard range > 0 else { return 1 }
        return min(max((score - rank.lowerBound) / range, 0), 1)
    }

    static func xp(isNewPersonalBest: Bool, extendsStreak: Bool) -> Int {
        10 + (isNewPersonalBest ? 25 : 0) + (extendsStreak ? 20 : 0)
    }
}
