//
//  HomeViewModel.swift
//  No Limits
//
//  Created by Sukhman Singh on 3/5/26.
//

import Foundation
import SwiftData

@Observable
final class HomeViewModel {

    var currentRank: Rank = .iron
    var score: Double = 0
    var progress: Double = 0
    var streak: Int = 0
    var xp: Int = 0
    var totalLifts: Int = 0
    var todayLogged: Bool = false
    var recentLifts: [LiftEntry] = []

    func refresh(context: ModelContext) {
        // Fetch profile
        guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first else { return }

        // Fetch stats
        guard let stats = try? context.fetch(FetchDescriptor<AppStats>()).first else { return }

        // Recalculate streak in case days have passed since last open
        let freshStreak: Int
        if let lastDate = stats.lastLoggedDate {
            let calendar = Calendar.current
            if calendar.isDateInToday(lastDate) {
                freshStreak = stats.streak
            } else if calendar.isDateInYesterday(lastDate) {
                freshStreak = stats.streak // streak still alive, hasn't logged yet today
            } else {
                freshStreak = 0 // streak broken
            }
        } else {
            freshStreak = 0
        }

        // Score from best overall e1RM
        let bestE1RM = stats.bestOverallE1RM
        let computedScore = RankingService.calculateScore(e1RM: bestE1RM, bodyweight: profile.bodyweight)
        let rank = Rank.fromScore(computedScore)

        // Today's lifts
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: .now)

        // Recent lifts (last 10, sorted newest first)
        var recentDescriptor = FetchDescriptor<LiftEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        recentDescriptor.fetchLimit = 10
        let recent = (try? context.fetch(recentDescriptor)) ?? []

        let todayEntries = recent.filter { calendar.isDateInToday($0.date) }

        // Update published state
        self.currentRank = rank
        self.score = computedScore
        self.progress = RankingService.progress(score: computedScore, rank: rank)
        self.streak = freshStreak
        self.xp = stats.xp
        self.totalLifts = stats.totalLifts
        self.todayLogged = !todayEntries.isEmpty
        self.recentLifts = recent
    }

    // MARK: - Helpers for display

    func relativeLabel(for entry: LiftEntry) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(entry.date) { return "Today" }
        if calendar.isDateInYesterday(entry.date) { return "Yesterday" }

        let days = calendar.dateComponents([.day], from: entry.date, to: .now).day ?? 0
        return "\(days)d ago"
    }
}
