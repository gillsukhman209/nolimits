//
//  LogViewModel.swift
//  No Limits
//
//  Created by Sukhman Singh on 3/5/26.
//

import Foundation
import SwiftData

struct SaveResult {
    let xpEarned: Int
    let isNewPR: Bool
    let newRank: Rank
    let previousRank: Rank
    var didRankUp: Bool { newRank != previousRank }
}

@Observable
final class LogViewModel {

    // Form state
    var selectedLiftIndex = 0
    var weight = ""
    var reps = ""
    var saved = false

    let liftOptions = ["Bench", "Squat", "Deadlift", "OHP", "Barbell Row"]

    var selectedLiftName: String { liftOptions[selectedLiftIndex] }

    var canSave: Bool { !weight.isEmpty && !reps.isEmpty && !saved }

    var currentE1RM: Double {
        let w = Double(weight) ?? 0
        let r = Int(reps) ?? 0
        return RankingService.calculateE1RM(weight: w, reps: r)
    }

    // MARK: - Save

    func saveLift(context: ModelContext) -> SaveResult? {
        guard let w = Double(weight), w > 0,
              let r = Int(reps), r > 0 else { return nil }

        // Fetch profile and stats
        guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first,
              let stats = try? context.fetch(FetchDescriptor<AppStats>()).first else { return nil }

        let e1RM = RankingService.calculateE1RM(weight: w, reps: r)

        // --- Snapshot BEFORE any updates ---
        let previousBestOverall = stats.bestOverallE1RM
        let previousScore = RankingService.calculateScore(e1RM: previousBestOverall, bodyweight: profile.bodyweight)
        let previousRank = Rank.fromScore(previousScore)

        // Check PR for this specific lift
        let currentBestForLift = bestE1RM(for: selectedLiftName, stats: stats)
        let isNewPR = e1RM > currentBestForLift && currentBestForLift > 0  // not a PR on first ever lift
        let isFirstLift = stats.totalLifts == 0
        let isNewPROrFirst = e1RM > currentBestForLift  // always update best, but only flag PR if not first

        // --- Apply updates ---

        // Insert entry
        let entry = LiftEntry(liftType: selectedLiftName, weight: w, reps: r)
        context.insert(entry)

        // Update per-lift best
        if isNewPROrFirst {
            updateBestE1RM(for: selectedLiftName, value: e1RM, stats: stats)
        }

        // Update overall best
        if e1RM > stats.bestOverallE1RM {
            stats.bestOverallE1RM = e1RM
        }

        // Streak
        let newStreak = StreakService.updatedStreak(lastLoggedDate: stats.lastLoggedDate, currentStreak: stats.streak)

        // XP — count as PR if it beats a previous best (not first ever)
        let xpEarned = RankingService.calculateXP(isNewPR: isNewPR, streakDays: newStreak)

        // Update stats
        stats.xp += xpEarned
        stats.streak = newStreak
        stats.lastLoggedDate = .now
        stats.totalLifts += 1

        // --- Snapshot AFTER updates ---
        let newScore = RankingService.calculateScore(e1RM: stats.bestOverallE1RM, bodyweight: profile.bodyweight)
        let newRank = Rank.fromScore(newScore)

        try? context.save()
        saved = true

        return SaveResult(
            xpEarned: xpEarned,
            isNewPR: isNewPR || isFirstLift,
            newRank: newRank,
            previousRank: previousRank
        )
    }

    // MARK: - Helpers

    private func bestE1RM(for liftType: String, stats: AppStats) -> Double {
        switch liftType {
        case "Bench":    return stats.bestBenchE1RM
        case "Squat":    return stats.bestSquatE1RM
        case "Deadlift": return stats.bestDeadliftE1RM
        default:         return 0
        }
    }

    private func updateBestE1RM(for liftType: String, value: Double, stats: AppStats) {
        switch liftType {
        case "Bench":    stats.bestBenchE1RM = value
        case "Squat":    stats.bestSquatE1RM = value
        case "Deadlift": stats.bestDeadliftE1RM = value
        default:         break
        }
    }
}
