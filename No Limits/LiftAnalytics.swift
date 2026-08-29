import Foundation
import SwiftData

struct ExerciseSummary: Identifiable {
    let name: String
    let muscleGroup: MuscleGroup
    let entries: [LiftEntry]
    let bestEntry: LiftEntry
    let latestEntry: LiftEntry

    var id: String { name }
    var logCount: Int { entries.count }
    var bestE1RM: Double { bestEntry.e1RM }
}

struct StrengthOverview {
    let score: Double
    let rank: Rank
    let progress: Double
    let sourceExercise: String?

    static let empty = StrengthOverview(
        score: 0,
        rank: .iron,
        progress: 0,
        sourceExercise: nil
    )
}

enum LiftAnalytics {
    static func summaries(from entries: [LiftEntry]) -> [ExerciseSummary] {
        Dictionary(grouping: entries, by: \.liftType)
            .compactMap { name, exerciseEntries in
                guard let latest = exerciseEntries.max(by: { $0.date < $1.date }),
                      let best = exerciseEntries.max(by: { $0.e1RM < $1.e1RM }) else {
                    return nil
                }
                let muscle = latest.muscleGroup
                    ?? ExerciseCatalog.muscleGroup(for: name)
                    ?? .legs
                return ExerciseSummary(
                    name: name,
                    muscleGroup: muscle,
                    entries: exerciseEntries.sorted { $0.date > $1.date },
                    bestEntry: best,
                    latestEntry: latest
                )
            }
            .sorted { lhs, rhs in
                lhs.latestEntry.date > rhs.latestEntry.date
            }
    }

    static func overview(entries: [LiftEntry], bodyweight: Double) -> StrengthOverview {
        let rankedEntries = entries.filter { ExerciseCatalog.isRanked($0.liftType) }
        guard let strongest = rankedEntries.max(by: { lhs, rhs in
            RankingService.calculateScore(e1RM: lhs.e1RM, bodyweight: bodyweight)
                < RankingService.calculateScore(e1RM: rhs.e1RM, bodyweight: bodyweight)
        }) else {
            return .empty
        }

        let score = RankingService.calculateScore(
            e1RM: strongest.e1RM,
            bodyweight: bodyweight
        )
        let rank = Rank.fromScore(score)
        return StrengthOverview(
            score: score,
            rank: rank,
            progress: RankingService.progress(score: score, rank: rank),
            sourceExercise: strongest.liftType
        )
    }

    static func exerciseScore(
        entries: [LiftEntry],
        bodyweight: Double
    ) -> StrengthOverview {
        guard let strongest = entries.max(by: { $0.e1RM < $1.e1RM }) else {
            return .empty
        }
        let score = RankingService.calculateScore(
            e1RM: strongest.e1RM,
            bodyweight: bodyweight
        )
        let rank = Rank.fromScore(score)
        return StrengthOverview(
            score: score,
            rank: rank,
            progress: RankingService.progress(score: score, rank: rank),
            sourceExercise: strongest.liftType
        )
    }

    static func totalVolume(
        entries: [LiftEntry],
        bodyweight: Double
    ) -> Double {
        entries.reduce(0) { total, entry in
            total + PerformanceService.trainingVolume(
                weight: entry.weight,
                reps: entry.reps,
                bodyweight: entry.bodyweightAtLog ?? bodyweight,
                loadType: entry.loadType
            )
        }
    }

    static func changePercent(entries: [LiftEntry]) -> Double? {
        let chronological = entries.sorted { $0.date < $1.date }
        guard let first = chronological.first,
              let last = chronological.last,
              chronological.count > 1,
              first.e1RM > 0 else {
            return nil
        }
        return ((last.e1RM - first.e1RM) / first.e1RM) * 100
    }
}

@MainActor
enum AppStatsSynchronizer {
    static func rebuild(context: ModelContext) {
        let entries = (try? context.fetch(
            FetchDescriptor<LiftEntry>(sortBy: [SortDescriptor(\.date)])
        )) ?? []
        let stats: AppStats
        if let existing = try? context.fetch(FetchDescriptor<AppStats>()).first {
            stats = existing
        } else {
            stats = AppStats()
            context.insert(stats)
        }

        stats.totalLifts = entries.count
        stats.lastLoggedDate = entries.last?.date
        stats.streak = StreakService.currentStreak(logDates: entries.map(\.date))

        for muscle in MuscleGroup.allCases {
            let best = entries
                .filter { $0.muscleGroup == muscle }
                .map(\.e1RM)
                .max() ?? 0
            stats.setBestE1RM(for: muscle, value: best)
        }

        var xp = 0
        var bestByExercise: [String: Double] = [:]
        var seenDays: Set<Date> = []
        let calendar = Calendar.current
        var previousUniqueDay: Date?

        for entry in entries {
            let key = entry.performanceKey
            let previousBest = bestByExercise[key]
            let isPR = previousBest.map { entry.e1RM > $0 } ?? false
            let day = calendar.startOfDay(for: entry.date)
            let isFirstLogOnDay = seenDays.insert(day).inserted
            let isConsecutiveDay: Bool
            if isFirstLogOnDay,
               let previousUniqueDay,
               let expectedDay = calendar.date(byAdding: .day, value: 1, to: previousUniqueDay) {
                isConsecutiveDay = calendar.isDate(expectedDay, inSameDayAs: day)
            } else {
                isConsecutiveDay = false
            }

            xp += RankingService.xp(
                isNewPersonalBest: isPR,
                extendsStreak: isConsecutiveDay
            )
            bestByExercise[key] = max(previousBest ?? 0, entry.e1RM)
            if isFirstLogOnDay {
                previousUniqueDay = day
            }
        }
        stats.xp = xp
        try? context.save()
    }

    static func delete(_ entry: LiftEntry, context: ModelContext) {
        context.delete(entry)
        try? context.save()
        rebuild(context: context)
    }
}
