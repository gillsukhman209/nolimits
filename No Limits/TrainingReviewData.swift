import Foundation

struct TrainingReviewDataset {
    let promptData: String
    let fallbackReview: String
}

enum TrainingReviewDataBuilder {
    static func make(
        entries: [LiftEntry],
        bodyweight: Double,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> TrainingReviewDataset {
        let summaries = LiftAnalytics.summaries(from: entries)
        let trainingDays = Set(entries.map { calendar.startOfDay(for: $0.date) }).count
        let recentThreshold = calendar.date(byAdding: .day, value: -27, to: now) ?? now
        let recentEntries = entries.filter { $0.date >= recentThreshold }
        let dateRange: String
        if let oldest = entries.min(by: { $0.date < $1.date })?.date,
           let newest = entries.max(by: { $0.date < $1.date })?.date {
            dateRange = "\(oldest.formatted(date: .abbreviated, time: .omitted)) to \(newest.formatted(date: .abbreviated, time: .omitted))"
        } else {
            dateRange = "No recorded dates"
        }

        var lines = [
            "TRAINING DATASET",
            "Date range: \(dateRange)",
            "Total sets: \(entries.count)",
            "Exercises: \(summaries.count)",
            "Training days: \(trainingDays)",
            "Sets in last 28 days: \(recentEntries.count)",
            "Bodyweight: \(bodyweight > 0 ? bodyweight.formattedWeight + " lb" : "not available")",
            "",
            "EXERCISE SUMMARIES",
        ]

        for summary in summaries.sorted(by: { $0.name < $1.name }) {
            let snapshot = LiftAnalytics.snapshot(entries: summary.entries, bodyweight: bodyweight)
            let trend = snapshot.trendPercent.map {
                "\($0 >= 0 ? "+" : "")\($0.formatted(.number.precision(.fractionLength(1))))%"
            } ?? "not enough data"
            let best = describe(summary.bestEntry)
            let latest = describe(summary.latestEntry)
            let records = LiftAnalytics.weightRepRecords(entries: summary.entries)
                .prefix(8)
                .map { record in
                    let side = record.side == .both ? "" : " \(record.side.shortLabel)"
                    let assist = record.loadType == .assistance ? " assist" : ""
                    return "\(record.weight.formattedWeight)lb\(assist)\(side):\(record.reps) reps"
                }
                .joined(separator: ", ")
            lines.append(
                "- \(summary.name) [\(summary.muscleGroup.rawValue)]: \(summary.logCount) sets across \(summary.trainingDays) days; trend \(trend); best \(best); latest \(latest); recent average input weight \(snapshot.recentAverageWeight.formattedWeight) lb; total work \(snapshot.totalVolume.formattedWeight) lb; rep records {\(records)}"
            )
        }

        lines.append("")
        lines.append("MOST RECENT SETS")
        for entry in entries.sorted(by: { $0.date > $1.date }).prefix(24) {
            lines.append("- \(entry.date.formatted(date: .abbreviated, time: .shortened)): \(entry.liftType), \(describe(entry)), estimated max \(entry.e1RM.formattedWeight) lb")
        }

        return TrainingReviewDataset(
            promptData: lines.joined(separator: "\n"),
            fallbackReview: fallback(
                summaries: summaries,
                entries: entries,
                recentSetCount: recentEntries.count,
                trainingDays: trainingDays
            )
        )
    }

    private static func fallback(
        summaries: [ExerciseSummary],
        entries: [LiftEntry],
        recentSetCount: Int,
        trainingDays: Int
    ) -> String {
        guard !entries.isEmpty else {
            return "## Not enough data\nLog at least two sets for an exercise to create a useful training review."
        }

        let trends = summaries.compactMap { summary -> (ExerciseSummary, Double)? in
            guard let trend = LiftAnalytics.recentTrendPercent(entries: summary.entries) else { return nil }
            return (summary, trend)
        }
        let improving = trends.filter { $0.1 > 1 }.sorted { $0.1 > $1.1 }
        let declining = trends.filter { $0.1 < -1 }.sorted { $0.1 < $1.1 }
        let stable = trends.filter { abs($0.1) <= 1 }

        var sections = [
            "## Overview",
            "You have logged **\(entries.count) sets** across **\(summaries.count) exercises** and **\(trainingDays) training days**. There are **\(recentSetCount) sets** in the last 28 days.",
        ]

        sections.append("## Improving")
        if improving.isEmpty {
            sections.append("No exercise has enough data to show a clear upward trend yet.")
        } else {
            for (summary, trend) in improving.prefix(4) {
                sections.append("- **\(summary.name):** up \(trend.formatted(.number.precision(.fractionLength(1))))% by recent estimated-max average. Best set: \(describe(summary.bestEntry)).")
            }
        }

        sections.append("## Needs attention")
        if declining.isEmpty {
            sections.append("No clear downward exercise trend appears in the current records.")
        } else {
            for (summary, trend) in declining.prefix(4) {
                sections.append("- **\(summary.name):** down \(abs(trend).formatted(.number.precision(.fractionLength(1))))%. Compare recent recovery, form, and set quality before increasing load.")
            }
        }

        if !stable.isEmpty {
            sections.append("## Holding steady")
            sections.append(stable.prefix(4).map { "**\($0.0.name)**" }.joined(separator: ", ") + " are within 1% of their earlier performance average.")
        }

        let sparse = summaries.filter { $0.logCount < 3 }
        sections.append("## Next focus")
        if let firstDecline = declining.first {
            sections.append("Review **\(firstDecline.0.name)** first. Keep the next few sets consistent in technique and rep range so the chart can confirm whether the decline is real.")
        } else if let sparseExercise = sparse.first {
            sections.append("Add a few more comparable sets for **\(sparseExercise.name)**. It currently has too little history for a reliable trend.")
        } else if let strongest = improving.first {
            sections.append("Keep the same progression pattern on **\(strongest.0.name)** while watching whether reps or working weight continue rising.")
        } else {
            sections.append("Keep logging comparable sets. More consistent rep ranges will make future trend comparisons more reliable.")
        }

        sections.append("_This review uses only recorded set data and is not medical advice._")
        return sections.joined(separator: "\n\n")
    }

    private static func describe(_ entry: LiftEntry) -> String {
        let side = entry.side == .both ? "" : " \(entry.side.shortLabel)"
        let assist = entry.loadType == .assistance ? " assistance" : ""
        return "\(entry.weight.formattedWeight) lb\(assist) × \(entry.reps)\(side)"
    }
}
