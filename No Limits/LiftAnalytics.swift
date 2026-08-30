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
    var trainingDays: Int {
        Set(entries.map { Calendar.current.startOfDay(for: $0.date) }).count
    }
}

struct WeightRepRecord: Identifiable, Equatable {
    let weight: Double
    let reps: Int
    let setCount: Int
    let side: ExerciseSide
    let achievedAt: Date
    let loadType: ExerciseLoadType

    var id: String { "\(weight)|\(side.rawValue)" }
}

struct ExerciseProgressSnapshot {
    let bestEntry: LiftEntry?
    let heaviestEntry: LiftEntry?
    let latestEntry: LiftEntry?
    let setCount: Int
    let trainingDays: Int
    let totalVolume: Double
    let recentAverageWeight: Double
    let trendPercent: Double?
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
    private struct WeightSideKey: Hashable {
        let weight: Double
        let side: ExerciseSide
    }

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

    static func recentTrendPercent(
        entries: [LiftEntry],
        sampleSize: Int = 3
    ) -> Double? {
        let chronological = entries.sorted { $0.date < $1.date }
        guard chronological.count > 1, sampleSize > 0 else { return nil }
        let count = min(sampleSize, max(1, chronological.count / 2))
        let baseline = chronological.prefix(count).map(\.e1RM)
        let recent = chronological.suffix(count).map(\.e1RM)
        let baselineAverage = baseline.reduce(0, +) / Double(baseline.count)
        let recentAverage = recent.reduce(0, +) / Double(recent.count)
        guard baselineAverage > 0 else { return nil }
        return ((recentAverage - baselineAverage) / baselineAverage) * 100
    }

    static func snapshot(
        entries: [LiftEntry],
        bodyweight: Double
    ) -> ExerciseProgressSnapshot {
        let sorted = entries.sorted { $0.date > $1.date }
        let recent = sorted.prefix(5)
        let averageWeight = recent.isEmpty
            ? 0
            : recent.map(\.weight).reduce(0, +) / Double(recent.count)
        let loadType = sorted.first?.loadType ?? .externalWeight
        let heaviest: LiftEntry?
        if loadType == .assistance {
            heaviest = entries.min {
                $0.weight == $1.weight ? $0.reps > $1.reps : $0.weight < $1.weight
            }
        } else {
            heaviest = entries.max {
                $0.weight == $1.weight ? $0.reps < $1.reps : $0.weight < $1.weight
            }
        }

        return ExerciseProgressSnapshot(
            bestEntry: entries.max(by: { $0.e1RM < $1.e1RM }),
            heaviestEntry: heaviest,
            latestEntry: sorted.first,
            setCount: entries.count,
            trainingDays: Set(entries.map { Calendar.current.startOfDay(for: $0.date) }).count,
            totalVolume: totalVolume(entries: entries, bodyweight: bodyweight),
            recentAverageWeight: averageWeight,
            trendPercent: recentTrendPercent(entries: entries)
        )
    }

    static func weightRepRecords(entries: [LiftEntry]) -> [WeightRepRecord] {
        let groups = Dictionary(grouping: entries) {
            WeightSideKey(weight: $0.weight, side: $0.side)
        }
        let records = groups.compactMap { key, values -> WeightRepRecord? in
            guard let best = values.max(by: {
                $0.reps == $1.reps ? $0.date < $1.date : $0.reps < $1.reps
            }) else { return nil }
            return WeightRepRecord(
                weight: key.weight,
                reps: best.reps,
                setCount: values.count,
                side: key.side,
                achievedAt: best.date,
                loadType: best.loadType
            )
        }
        guard let loadType = records.first?.loadType else { return [] }
        return records.sorted { lhs, rhs in
            if lhs.weight == rhs.weight {
                return lhs.side.rawValue < rhs.side.rawValue
            }
            return loadType == .assistance
                ? lhs.weight < rhs.weight
                : lhs.weight > rhs.weight
        }
    }

    static func personalBestEntryIDs(entries: [LiftEntry]) -> Set<UUID> {
        let chronological = entries.sorted { $0.date < $1.date }
        var bestBySide: [ExerciseSide: Double] = [:]
        var recordIDs: Set<UUID> = []
        for entry in chronological {
            let previous = bestBySide[entry.side] ?? 0
            if entry.e1RM > previous {
                recordIDs.insert(entry.id)
                bestBySide[entry.side] = entry.e1RM
            }
        }
        return recordIDs
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

        try? context.save()
    }

    static func delete(_ entry: LiftEntry, context: ModelContext) {
        context.delete(entry)
        try? context.save()
        rebuild(context: context)
    }
}
