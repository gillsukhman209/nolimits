//
//  LogViewModel.swift
//  No Limits
//
//  Created by Sukhman Singh on 3/5/26.
//

import Foundation
import SwiftData

struct SaveResult {
    // let xpEarned: Int  // XP disabled — uncomment to re-enable
    let isNewPR: Bool
    let muscleGroup: MuscleGroup
    let newRank: Rank
    let previousRank: Rank
    var didRankUp: Bool { newRank != previousRank }
}

@Observable
final class LogViewModel {

    var selectedExercise: Exercise? = ExerciseCatalog.all.first
    var weight = ""
    var reps = ""
    var saved = false

    var canSave: Bool { !weight.isEmpty && !reps.isEmpty && !saved && selectedExercise != nil }

    var currentE1RM: Double {
        let w = Double(weight) ?? 0
        let r = Int(reps) ?? 0
        return RankingService.calculateE1RM(weight: w, reps: r)
    }

    // MARK: - Save

    func saveLift(context: ModelContext) -> SaveResult? {
        guard let exercise = selectedExercise,
              let w = Double(weight), w > 0,
              let r = Int(reps), r > 0 else { return nil }

        guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first,
              let stats = try? context.fetch(FetchDescriptor<AppStats>()).first else { return nil }

        let muscle = exercise.muscleGroup
        let e1RM = RankingService.calculateE1RM(weight: w, reps: r)

        // Snapshot BEFORE
        let previousBest = stats.bestE1RM(for: muscle)
        let previousScore = RankingService.calculateScore(e1RM: previousBest, bodyweight: profile.bodyweight)
        let previousRank = Rank.fromScore(previousScore)

        // Is this a PR?
        let isNewPR = e1RM > previousBest && previousBest > 0
        let isFirstForMuscle = previousBest == 0

        // Insert entry
        let entry = LiftEntry(liftType: exercise.name, muscleGroup: muscle, weight: w, reps: r)
        context.insert(entry)

        // Update per-muscle best
        if e1RM > previousBest {
            stats.setBestE1RM(for: muscle, value: e1RM)
        }

        // Streak
        let newStreak = StreakService.updatedStreak(lastLoggedDate: stats.lastLoggedDate, currentStreak: stats.streak)

        // XP (commented out — uncomment to re-enable XP system)
        // let xpEarned = RankingService.calculateXP(isNewPR: isNewPR || isFirstForMuscle, streakDays: newStreak)
        // stats.xp += xpEarned

        // Update stats
        stats.streak = newStreak
        stats.lastLoggedDate = .now
        stats.totalLifts += 1

        // Snapshot AFTER
        let newBest = stats.bestE1RM(for: muscle)
        let newScore = RankingService.calculateScore(e1RM: newBest, bodyweight: profile.bodyweight)
        let newRank = Rank.fromScore(newScore)

        try? context.save()
        saved = true

        return SaveResult(
            // xpEarned: xpEarned,  // XP disabled
            isNewPR: isNewPR || isFirstForMuscle,
            muscleGroup: muscle,
            newRank: newRank,
            previousRank: previousRank
        )
    }
}
