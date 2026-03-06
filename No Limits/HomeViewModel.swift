//
//  HomeViewModel.swift
//  No Limits
//
//  Created by Sukhman Singh on 3/5/26.
//

import Foundation
import SwiftData

struct MuscleRankInfo: Identifiable {
    let muscle: MuscleGroup
    let rank: Rank
    let score: Double
    let progress: Double
    var id: String { muscle.rawValue }
}

@Observable
final class HomeViewModel {

    // Overall
    var overallRank: Rank = .iron
    var overallScore: Double = 0
    var overallProgress: Double = 0

    // Per-muscle
    var muscleRanks: [MuscleGroup: Rank] = [:]
    var muscleRankList: [MuscleRankInfo] = []

    // Stats
    var streak: Int = 0
    var xp: Int = 0
    var totalLifts: Int = 0
    var todayLogged: Bool = false
    var recentLifts: [LiftEntry] = []

    func refresh(context: ModelContext) {
        guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first,
              let stats = try? context.fetch(FetchDescriptor<AppStats>()).first else { return }

        // Per-muscle ranks
        var ranks: [MuscleGroup: Rank] = [:]
        var infos: [MuscleRankInfo] = []
        var totalScore: Double = 0
        var trainedCount = 0

        for muscle in MuscleGroup.allCases {
            let best = stats.bestE1RM(for: muscle)
            let score = RankingService.calculateScore(e1RM: best, bodyweight: profile.bodyweight)
            let rank = Rank.fromScore(score)
            let prog = RankingService.progress(score: score, rank: rank)
            ranks[muscle] = rank
            infos.append(MuscleRankInfo(muscle: muscle, rank: rank, score: score, progress: prog))
            if best > 0 {
                totalScore += score
                trainedCount += 1
            }
        }

        self.muscleRanks = ranks
        self.muscleRankList = infos

        // Overall = average score of trained muscles
        let avgScore = trainedCount > 0 ? totalScore / Double(trainedCount) : 0
        self.overallRank = Rank.fromScore(avgScore)
        self.overallScore = avgScore
        self.overallProgress = RankingService.progress(score: avgScore, rank: overallRank)

        // Streak (recalculate in case days passed)
        if let lastDate = stats.lastLoggedDate {
            let cal = Calendar.current
            if cal.isDateInToday(lastDate) || cal.isDateInYesterday(lastDate) {
                self.streak = stats.streak
            } else {
                self.streak = 0
            }
        } else {
            self.streak = 0
        }

        self.xp = stats.xp
        self.totalLifts = stats.totalLifts

        // Recent lifts
        var desc = FetchDescriptor<LiftEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        desc.fetchLimit = 10
        let recent = (try? context.fetch(desc)) ?? []
        self.recentLifts = recent
        self.todayLogged = recent.contains { Calendar.current.isDateInToday($0.date) }
    }

    func relativeLabel(for entry: LiftEntry) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(entry.date) { return "Today" }
        if cal.isDateInYesterday(entry.date) { return "Yesterday" }
        let days = cal.dateComponents([.day], from: entry.date, to: .now).day ?? 0
        return "\(days)d ago"
    }
}
