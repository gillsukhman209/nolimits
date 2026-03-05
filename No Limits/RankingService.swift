//
//  RankingService.swift
//  No Limits
//
//  Created by Sukhman Singh on 3/5/26.
//

import Foundation

struct RankingService {

    // MARK: - e1RM

    /// Epley formula: weight * (1 + reps/30)
    static func calculateE1RM(weight: Double, reps: Int) -> Double {
        guard weight > 0, reps > 0 else { return 0 }
        if reps == 1 { return weight }
        return weight * (1.0 + Double(reps) / 30.0)
    }

    // MARK: - Score (normalized by bodyweight)

    static func calculateScore(e1RM: Double, bodyweight: Double) -> Double {
        guard bodyweight > 0 else { return 0 }
        return e1RM / bodyweight
    }

    // MARK: - Progress within current rank (0.0 ... 1.0)

    static func progress(score: Double, rank: Rank) -> Double {
        let range = rank.upperBound - rank.lowerBound
        guard range > 0 else { return 1.0 }
        return min(max((score - rank.lowerBound) / range, 0), 1.0)
    }

    // MARK: - XP

    static func calculateXP(isNewPR: Bool, streakDays: Int) -> Int {
        var xp = 10                           // base per log
        if isNewPR { xp += 25 }               // PR bonus
        if streakDays > 0 { xp += 20 }        // streak bonus (ongoing streak)
        return xp
    }
}
