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

struct ProgressInsight: Identifiable, Equatable {
    enum Kind: String {
        case consistency
        case improvement
        case balance
    }

    let kind: Kind
    let title: String
    let detail: String

    var id: String { "\(kind.rawValue)|\(detail)" }
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

    static func insights(
        entries: [LiftEntry],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [ProgressInsight] {
        guard !entries.isEmpty else { return [] }
        var results: [ProgressInsight] = []

        let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: now) ?? now
        let recentDays = Set(
            entries
                .filter { $0.date >= calendar.startOfDay(for: sevenDaysAgo) }
                .map { calendar.startOfDay(for: $0.date) }
        )
        if !recentDays.isEmpty {
            results.append(
                ProgressInsight(
                    kind: .consistency,
                    title: "Weekly consistency",
                    detail: "You trained on \(recentDays.count) of the last 7 days."
                )
            )
        }

        let performanceGroups = Dictionary(grouping: entries, by: \.performanceKey)
        let strongestChange = performanceGroups.compactMap { key, values -> (String, Double)? in
            let chronological = values.sorted { $0.date < $1.date }
            guard chronological.count > 1,
                  let first = chronological.first,
                  let last = chronological.last,
                  first.e1RM > 0 else { return nil }
            let change = ((last.e1RM - first.e1RM) / first.e1RM) * 100
            let side = first.side == .both ? "" : " \(first.side.rawValue.lowercased())"
            return ("\(first.liftType)\(side)", change)
        }
        .max { abs($0.1) < abs($1.1) }

        if let strongestChange, abs(strongestChange.1) >= 0.5 {
            let direction = strongestChange.1 >= 0 ? "improved" : "changed"
            results.append(
                ProgressInsight(
                    kind: .improvement,
                    title: "Performance trend",
                    detail: "\(strongestChange.0) has \(direction) \(abs(strongestChange.1).formatted(.number.precision(.fractionLength(1))))%."
                )
            )
        }

        let sideGroups = Dictionary(grouping: entries.filter { $0.side != .both }, by: \.liftType)
        let largestImbalance = sideGroups.compactMap { name, values -> (String, ExerciseSide, Double)? in
            let left = values.filter { $0.side == .left }.map(\.e1RM).max()
            let right = values.filter { $0.side == .right }.map(\.e1RM).max()
            guard let left, let right, max(left, right) > 0 else { return nil }
            let difference = abs(left - right) / max(left, right) * 100
            let weakerSide: ExerciseSide = left < right ? .left : .right
            return (name, weakerSide, difference)
        }
        .max { $0.2 < $1.2 }

        if let imbalance = largestImbalance, imbalance.2 >= 5 {
            results.append(
                ProgressInsight(
                    kind: .balance,
                    title: "Side balance",
                    detail: "\(imbalance.0): \(imbalance.1.rawValue.lowercased()) is \(imbalance.2.formatted(.number.precision(.fractionLength(0))))% behind."
                )
            )
        }

        return Array(results.prefix(3))
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
