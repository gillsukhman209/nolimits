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
        let audit = LiftAnalytics.weeklyTrainingAudit(entries: entries, now: now, calendar: calendar)
        let trainingDays = Set(entries.map { calendar.startOfDay(for: $0.date) }).count
        let recentThreshold = calendar.date(byAdding: .day, value: -27, to: now) ?? now
        let recentEntries = entries.filter { $0.date >= recentThreshold && $0.date <= now }
        let dateRange: String
        if let oldest = entries.min(by: { $0.date < $1.date })?.date,
           let newest = entries.max(by: { $0.date < $1.date })?.date {
            dateRange = "\(oldest.formatted(date: .abbreviated, time: .omitted)) to \(newest.formatted(date: .abbreviated, time: .omitted))"
        } else {
            dateRange = "No recorded dates"
        }

        var lines = [
            "TRAINING DATASET",
            "All-time date range: \(dateRange)",
            "All-time sets: \(entries.count)",
            "All-time exercises: \(summaries.count)",
            "All-time training days: \(trainingDays)",
            "Sets in last 28 days: \(recentEntries.count)",
            "Bodyweight: \(bodyweight > 0 ? bodyweight.formattedWeight + " lb" : "not available")",
            "",
        ]
        appendWeeklyAudit(audit, to: &lines)

        lines.append("")
        lines.append("EXERCISE SUMMARIES")
        for summary in summaries.sorted(by: { $0.name < $1.name }) {
            let snapshot = LiftAnalytics.snapshot(entries: summary.entries, bodyweight: bodyweight)
            let trend = snapshot.trendPercent.map {
                "\($0 >= 0 ? "+" : "")\($0.formatted(.number.precision(.fractionLength(1))))%"
            } ?? "not enough data"
            let records = LiftAnalytics.weightRepRecords(entries: summary.entries)
                .prefix(8)
                .map { record in
                    let side = record.side == .both ? "" : " \(record.side.shortLabel)"
                    let assist = record.loadType == .assistance ? " assist" : ""
                    return "\(record.weight.formattedWeight)lb\(assist)\(side):\(record.reps) reps"
                }
                .joined(separator: ", ")
            lines.append(
                "- \(summary.name) [primary: \(summary.muscleGroup.rawValue)]: \(summary.logCount) sets across \(summary.trainingDays) days; trend \(trend); best \(describe(summary.bestEntry)); latest \(describe(summary.latestEntry)); recent average input weight \(snapshot.recentAverageWeight.formattedWeight) lb; total work \(snapshot.totalVolume.formattedWeight) lb; rep records {\(records)}"
            )
        }

        lines.append("")
        lines.append("MOST RECENT SETS")
        for entry in entries.sorted(by: { $0.date > $1.date }).prefix(30) {
            lines.append("- \(entry.date.formatted(date: .abbreviated, time: .shortened)): \(entry.liftType), \(describe(entry)), estimated max \(entry.e1RM.formattedWeight) lb")
        }

        return TrainingReviewDataset(
            promptData: lines.joined(separator: "\n"),
            fallbackReview: fallback(
                summaries: summaries,
                entries: entries,
                audit: audit,
                recentSetCount: recentEntries.count,
                trainingDays: trainingDays
            )
        )
    }

    private static func appendWeeklyAudit(
        _ audit: WeeklyTrainingAudit,
        to lines: inout [String]
    ) {
        lines.append("LAST 7 DAYS: COMPLETE WEEKLY AUDIT")
        lines.append("Window: \(audit.startDate.formatted(date: .abbreviated, time: .omitted)) through \(audit.endDate.formatted(date: .abbreviated, time: .omitted))")
        lines.append("Weekly sets: \(setCountDescription(audit.setCount))")
        lines.append("Weekly training days: \(audit.trainingDays) of 7")
        lines.append("Coverage limitation: every exercise has one primary muscle; these are direct primary-muscle counts only. Secondary muscle work is unknown.")

        lines.append("DAY BY DAY")
        if audit.days.isEmpty {
            lines.append("- No sets logged in this seven-day window.")
        } else {
            for day in audit.days {
                let exercises = Dictionary(grouping: day.entries, by: \.liftType)
                    .map { "\($0.key): \($0.value.count) sets" }
                    .sorted()
                    .joined(separator: ", ")
                let muscles = Dictionary(grouping: day.entries) {
                    $0.muscleGroup ?? ExerciseCatalog.muscleGroup(for: $0.liftType) ?? .legs
                }
                .map { "\($0.key.rawValue): \($0.value.count)" }
                .sorted()
                .joined(separator: ", ")
                lines.append("- \(day.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())): \(setCountDescription(day.entries.count)); exercises {\(exercises)}; primary muscles {\(muscles)}")
            }
        }

        lines.append("PRIMARY MUSCLE COVERAGE")
        for stat in audit.muscleStats {
            lines.append("- \(stat.muscleGroup.rawValue): \(stat.setCount) sets, \(stat.trainingDays) days, \(percent(stat.share)) of weekly sets")
        }

        lines.append("REGIONAL DISTRIBUTION")
        for region in TrainingRegion.allCases {
            lines.append("- \(region.rawValue): \(audit.regionSetCounts[region, default: 0]) sets")
        }

        lines.append("WEEKLY FLAGS")
        lines.append("- Missing direct primary groups: \(list(audit.missingMuscleGroups))")
        lines.append("- High workload concentration: \(list(audit.highConcentrationMuscleGroups))")
        lines.append("- Concentration rule: more than 12 direct sets, or at least 6 of 8+ weekly sets and at least 35% of the week's workload. This is not proof of overtraining.")
    }

    private static func fallback(
        summaries: [ExerciseSummary],
        entries: [LiftEntry],
        audit: WeeklyTrainingAudit,
        recentSetCount: Int,
        trainingDays: Int
    ) -> String {
        guard !entries.isEmpty else {
            return "## Not enough data\nLog sets across the week to create a useful coverage and performance review."
        }

        let trends = summaries.compactMap { summary -> (ExerciseSummary, Double)? in
            guard let trend = LiftAnalytics.recentTrendPercent(entries: summary.entries) else { return nil }
            return (summary, trend)
        }
        let improving = trends.filter { $0.1 > 1 }.sorted { $0.1 > $1.1 }
        let declining = trends.filter { $0.1 < -1 }.sorted { $0.1 < $1.1 }
        let stable = trends.filter { abs($0.1) <= 1 }
        let trainedMuscles = audit.muscleStats
            .filter { $0.setCount > 0 }
            .sorted { $0.setCount > $1.setCount }

        var sections = [
            "## Weekly snapshot",
            "- **\(setCountDescription(audit.setCount))** across **\(audit.trainingDays) of the last 7 days**. Your full history contains \(setCountDescription(entries.count)), \(summaries.count) exercises, and \(trainingDays) training days.",
            "- \(setCountDescription(recentSetCount)) were logged in the last 28 days.",
        ]
        if audit.days.isEmpty {
            sections.append("- No workout was logged in the current seven-day window, so this week's muscle balance cannot be assessed yet.")
        } else {
            for day in audit.days {
                let exerciseNames = Array(Set(day.entries.map(\.liftType))).sorted().joined(separator: ", ")
                sections.append("- **\(day.date.formatted(.dateTime.weekday(.wide))):** \(setCountDescription(day.entries.count)) across \(exerciseNames).")
            }
        }

        sections.append("## Muscle coverage")
        if trainedMuscles.isEmpty {
            sections.append("- No direct primary-muscle coverage is recorded this week.")
        } else {
            for stat in trainedMuscles {
                sections.append("- **\(stat.muscleGroup.rawValue):** \(stat.setCount) direct sets across \(stat.trainingDays) day\(stat.trainingDays == 1 ? "" : "s") (\(percent(stat.share)) of weekly sets).")
            }
            sections.append("- **Missing direct coverage:** \(list(audit.missingMuscleGroups)).")
            sections.append("- Coverage uses each exercise's assigned primary muscle only; indirect work is not estimated.")
        }

        sections.append("## Improving")
        if improving.isEmpty {
            sections.append("- No exercise has enough comparable data to show a clear upward trend yet.")
        } else {
            for (summary, trend) in improving.prefix(5) {
                sections.append("- **\(summary.name):** up \(trend.formatted(.number.precision(.fractionLength(1))))% by recent estimated-max average. Best set: \(describe(summary.bestEntry)).")
            }
        }

        sections.append("## Stalled or declining")
        if declining.isEmpty && stable.isEmpty {
            sections.append("- No exercise has enough repeated data to identify a decline or plateau.")
        } else {
            for (summary, trend) in declining.prefix(5) {
                sections.append("- **\(summary.name):** down \(abs(trend).formatted(.number.precision(.fractionLength(1))))% by recent estimated-max average. Compare the logged weight and rep range before changing progression.")
            }
            if !stable.isEmpty {
                sections.append("- **Holding within 1%:** \(stable.prefix(5).map { $0.0.name }.joined(separator: ", ")).")
            }
        }

        sections.append("## Balance and workload")
        sections.append("- **Regional sets:** \(regionSummary(audit)).")
        if audit.highConcentrationMuscleGroups.isEmpty {
            sections.append("- No single primary muscle crosses the high-concentration threshold this week.")
        } else {
            for muscle in audit.highConcentrationMuscleGroups {
                guard let stat = audit.muscleStats.first(where: { $0.muscleGroup == muscle }) else { continue }
                sections.append("- **Potential overemphasis: \(muscle.rawValue)** has \(stat.setCount) direct sets, \(percent(stat.share)) of the week. This is a concentration signal, not proof of overtraining.")
            }
        }
        appendRegionalBalance(audit, to: &sections)
        appendSideBalance(entries, to: &sections)

        sections.append("## Next week focus")
        if let firstMissing = prioritizedMissingGroup(in: audit) {
            sections.append("- The clearest coverage gap is **\(firstMissing.rawValue)**: it has no direct primary sets in the last seven days. Decide whether that omission is intentional before adding more volume to already-covered areas.")
        } else if let concentrated = audit.highConcentrationMuscleGroups.first {
            sections.append("- Review whether **\(concentrated.rawValue)** needs its current share of weekly sets before increasing it again.")
        } else if let firstDecline = declining.first {
            sections.append("- Review **\(firstDecline.0.name)** first. Log comparable technique and rep ranges so the next review can tell whether the decline persists.")
        } else if let sparse = summaries.first(where: { $0.logCount < 3 }) {
            sections.append("- Add comparable history for **\(sparse.name)**; fewer than three sets is not enough for a reliable trend.")
        } else {
            sections.append("- Keep set logging consistent across the week so muscle frequency and exercise trends remain comparable.")
        }

        sections.append("_This review uses recorded set data only and is not medical advice._")
        return sections.joined(separator: "\n")
    }

    private static func appendRegionalBalance(
        _ audit: WeeklyTrainingAudit,
        to sections: inout [String]
    ) {
        guard audit.setCount > 0 else { return }
        let push = audit.regionSetCounts[.push, default: 0]
        let pull = audit.regionSetCounts[.pull, default: 0]
        let lower = audit.regionSetCounts[.lowerBody, default: 0]
        let core = audit.regionSetCounts[.core, default: 0]

        if push >= 6 && push >= max(1, pull) * 2 {
            sections.append("- Push work (\(push) sets) is at least double pull work (\(pull) sets); check whether that split matches your intent.")
        } else if pull >= 6 && pull >= max(1, push) * 2 {
            sections.append("- Pull work (\(pull) sets) is at least double push work (\(push) sets); check whether that split matches your intent.")
        }
        if lower == 0 {
            sections.append("- No direct lower-body sets were logged this week.")
        }
        if core == 0 {
            sections.append("- No direct core sets were logged this week.")
        }
    }

    private static func appendSideBalance(
        _ entries: [LiftEntry],
        to sections: inout [String]
    ) {
        let sideGroups = Dictionary(grouping: entries.filter { $0.side != .both }, by: \.liftType)
        let imbalances = sideGroups.compactMap { exercise, values -> (String, ExerciseSide, Double)? in
            guard let left = values.filter({ $0.side == .left }).map(\.e1RM).max(),
                  let right = values.filter({ $0.side == .right }).map(\.e1RM).max(),
                  max(left, right) > 0 else { return nil }
            let difference = abs(left - right) / max(left, right)
            guard difference >= 0.05 else { return nil }
            return (exercise, left < right ? .left : .right, difference)
        }
        .sorted { $0.2 > $1.2 }

        if let imbalance = imbalances.first {
            sections.append("- **Side balance:** \(imbalance.0) \(imbalance.1.rawValue.lowercased()) side is \(percent(imbalance.2)) below the other side's best estimated max.")
        }
    }

    private static func prioritizedMissingGroup(in audit: WeeklyTrainingAudit) -> MuscleGroup? {
        let priority: [MuscleGroup] = [.quads, .hamstrings, .lats, .chest, .shoulders, .abdominals, .upperChest, .triceps, .biceps, .legs]
        return priority.first { audit.missingMuscleGroups.contains($0) }
    }

    private static func regionSummary(_ audit: WeeklyTrainingAudit) -> String {
        TrainingRegion.allCases
            .map { "\($0.rawValue) \(audit.regionSetCounts[$0, default: 0])" }
            .joined(separator: ", ")
    }

    private static func list(_ muscles: [MuscleGroup]) -> String {
        muscles.isEmpty ? "none" : muscles.map(\.rawValue).joined(separator: ", ")
    }

    private static func percent(_ value: Double) -> String {
        value.formatted(.percent.precision(.fractionLength(0)))
    }

    private static func setCountDescription(_ count: Int) -> String {
        "\(count) set\(count == 1 ? "" : "s")"
    }

    private static func describe(_ entry: LiftEntry) -> String {
        let side = entry.side == .both ? "" : " \(entry.side.shortLabel)"
        let assist = entry.loadType == .assistance ? " assistance" : ""
        return "\(entry.weight.formattedWeight) lb\(assist) × \(entry.reps)\(side)"
    }
}
