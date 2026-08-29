import SwiftUI
import SwiftData

struct ProgressView: View {
    let onExerciseTap: (String, MuscleGroup) -> Void

    @Query(sort: \LiftEntry.date, order: .reverse) private var entries: [LiftEntry]
    @Query private var profiles: [UserProfile]
    @Query private var appStats: [AppStats]

    private var overview: StrengthOverview {
        LiftAnalytics.overview(
            entries: entries,
            bodyweight: profiles.first?.bodyweight ?? 0
        )
    }

    private var summaries: [ExerciseSummary] {
        LiftAnalytics.summaries(from: entries)
            .sorted { $0.bestE1RM > $1.bestE1RM }
    }

    private var insights: [ProgressInsight] {
        LiftAnalytics.insights(entries: entries)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                header
                rankHero
                compoundRanks
                statStrip
                weekCard
                if !insights.isEmpty {
                    insightCards
                }
                personalBests
            }
            .padding(.horizontal, 24)
            .padding(.top, 14)
            .padding(.bottom, 28)
        }
        .background(Color.paper)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("YOUR WORK")
                .sectionEyebrow()
            Text("IS SHOWING")
                .editorialTitle(size: 48, lineSpacing: -4)
                .foregroundStyle(Color.ink)
        }
    }

    private var rankHero: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("BEST COMPOUND RANK")
                        .font(.system(size: 11, weight: .black))
                        .tracking(2)
                        .foregroundStyle(Color.signalPaper.opacity(0.64))
                    Text(overview.rank.rawValue.uppercased())
                        .font(.system(size: 42, weight: .black))
                        .fontWidth(.compressed)
                        .foregroundStyle(Color.signalPaper)
                }

                Spacer()

                Image(systemName: overview.rank.symbolName)
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(overview.rank.color)
                    .frame(width: 58, height: 58)
                    .background(Color.signalPaper.opacity(0.10), in: Circle())
            }

            HStack(alignment: .lastTextBaseline, spacing: 5) {
                Text(String(format: "%.2f", overview.score))
                    .font(.system(size: 48, weight: .black))
                    .fontWidth(.compressed)
                Text("× BODYWEIGHT")
                    .font(.system(size: 11, weight: .black))
                    .tracking(1.3)
                    .foregroundStyle(Color.signalPaper.opacity(0.62))
            }
            .foregroundStyle(Color.signalPaper)

            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.signalPaper.opacity(0.16))
                        Capsule()
                            .fill(Color.signalOrange)
                            .frame(width: max(8, geometry.size.width * overview.progress))
                    }
                }
                .frame(height: 8)

                HStack {
                    Text(overview.sourceExercise ?? "Log a ranked lift")
                    Spacer()
                    Text(
                        overview.rank.nextRank.map {
                            "\(Int(overview.progress * 100))% to \($0.rawValue)"
                        } ?? "Top rank reached"
                    )
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.signalPaper.opacity(0.66))
            }

            Text(overview.sourceExercise.map { "Driven by your best \($0) bodyweight ratio." } ?? "Log a compound lift to establish your rank.")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.signalPaper.opacity(0.54))
        }
        .padding(22)
        .background(Color.signalInk, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var statStrip: some View {
        HStack(spacing: 10) {
            ProgressStat(
                value: "\(appStats.first?.streak ?? 0)",
                label: "DAY STREAK"
            )
            ProgressStat(
                value: "\(entries.count)",
                label: "TOTAL SETS"
            )
            ProgressStat(
                value: "\(appStats.first?.xp ?? 0)",
                label: "XP"
            )
        }
    }

    private var weekCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("LAST 7 DAYS")
                .sectionEyebrow()

            HStack {
                ForEach(lastSevenDays, id: \.self) { day in
                    let didLog = entries.contains {
                        Calendar.current.isDate($0.date, inSameDayAs: day)
                    }
                    VStack(spacing: 8) {
                        Text(day.formatted(.dateTime.weekday(.narrow)).uppercased())
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(Color.inkMuted)
                        Circle()
                            .fill(didLog ? Color.signalOrange : Color.hairline.opacity(0.45))
                            .frame(width: 30, height: 30)
                            .overlay {
                                if didLog {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .black))
                                        .foregroundStyle(Color.white)
                                }
                            }
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(
                        "\(day.formatted(date: .abbreviated, time: .omitted)), \(didLog ? "logged" : "not logged")"
                    )
                }
            }
        }
        .padding(18)
        .cardStyle(cornerRadius: 18)
    }

    private var compoundRanks: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CORE LIFT RANKS")
                .sectionEyebrow()

            ForEach(["Bench Press", "Squat", "Deadlift"], id: \.self) { name in
                let liftEntries = entries.filter { $0.liftType == name }
                let liftOverview = LiftAnalytics.exerciseScore(
                    entries: liftEntries,
                    bodyweight: profiles.first?.bodyweight ?? 0
                )

                HStack(spacing: 13) {
                    Image(systemName: ExerciseCatalog.muscleGroup(for: name)?.iconName ?? "dumbbell.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(liftEntries.isEmpty ? Color.inkMuted : Color.paper)
                        .frame(width: 40, height: 40)
                        .background(
                            liftEntries.isEmpty ? Color.hairline.opacity(0.36) : Color.ink,
                            in: Circle()
                        )

                    VStack(alignment: .leading, spacing: 1) {
                        Text(name)
                            .font(.system(size: 16, weight: .black))
                            .fontWidth(.condensed)
                            .foregroundStyle(Color.ink)
                        Text(liftEntries.isEmpty ? "No sets yet" : String(format: "%.2f× bodyweight", liftOverview.score))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.inkMuted)
                    }

                    Spacer()

                    if liftEntries.isEmpty {
                        Text("—")
                            .font(.system(size: 18, weight: .black))
                            .foregroundStyle(Color.inkFaint)
                    } else {
                        RankPill(rank: liftOverview.rank)
                    }
                }
                .padding(13)
                .cardStyle(cornerRadius: 15)
            }
        }
    }

    private var insightCards: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WHAT’S CHANGING")
                .sectionEyebrow()

            ForEach(insights) { insight in
                HStack(alignment: .top, spacing: 13) {
                    Image(systemName: insightIcon(insight.kind))
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(Color.signalOrange)
                        .frame(width: 36, height: 36)
                        .background(Color.signalOrange.opacity(0.1), in: Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text(insight.title)
                            .font(.system(size: 16, weight: .black))
                            .fontWidth(.condensed)
                            .foregroundStyle(Color.ink)
                        Text(insight.detail)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.inkMuted)
                    }
                    Spacer()
                }
                .padding(15)
                .cardStyle(cornerRadius: 16)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func insightIcon(_ kind: ProgressInsight.Kind) -> String {
        switch kind {
        case .consistency: return "calendar.badge.checkmark"
        case .improvement: return "chart.line.uptrend.xyaxis"
        case .balance: return "arrow.left.and.right"
        }
    }

    private var personalBests: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("PERSONAL BESTS")
                    .sectionEyebrow()
                Spacer()
                Text("\(summaries.count) exercises")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.inkMuted)
            }

            if summaries.isEmpty {
                Text("Personal bests appear after your first set.")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.inkMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .cardStyle(cornerRadius: 18)
            } else {
                ForEach(summaries.prefix(6)) { summary in
                    Button {
                        onExerciseTap(summary.name, summary.muscleGroup)
                    } label: {
                        HStack(spacing: 13) {
                            ExerciseIcon(muscleGroup: summary.muscleGroup, size: 44)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(summary.name)
                                    .font(.system(size: 17, weight: .black))
                                    .fontWidth(.condensed)
                                    .foregroundStyle(Color.ink)
                                Text("Estimated max \(summary.bestE1RM.formattedWeight) lb")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(Color.inkMuted)
                            }
                            Spacer()
                            Text("\(summary.bestEntry.weight.formattedWeight) × \(summary.bestEntry.reps)")
                                .font(.system(size: 18, weight: .black))
                                .fontWidth(.condensed)
                                .foregroundStyle(Color.ink)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(Color.inkFaint)
                        }
                        .padding(14)
                        .cardStyle(cornerRadius: 16)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var lastSevenDays: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return (0..<7).reversed().compactMap {
            calendar.date(byAdding: .day, value: -$0, to: today)
        }
    }
}

struct ProgressStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.system(size: 28, weight: .black))
                .fontWidth(.compressed)
                .foregroundStyle(Color.ink)
            Text(label)
                .font(.system(size: 9, weight: .black))
                .tracking(1.1)
                .foregroundStyle(Color.inkMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .cardStyle(cornerRadius: 16)
        .accessibilityElement(children: .combine)
    }
}
