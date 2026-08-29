import SwiftUI
import SwiftData
import UIKit

struct HomeView: View {
    let onLogTap: () -> Void
    let onTimerTap: () -> Void
    let onSettingsTap: () -> Void
    let onExerciseTap: (String, MuscleGroup) -> Void
    let onQuickLog: (Exercise, ExerciseSide?) -> Void

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LiftEntry.date, order: .reverse) private var entries: [LiftEntry]
    @Query private var profiles: [UserProfile]
    @Query private var stats: [AppStats]

    private var profile: UserProfile? { profiles.first }
    private var latestEntry: LiftEntry? { entries.first }
    private var appStats: AppStats? { stats.first }
    private var overview: StrengthOverview {
        LiftAnalytics.overview(
            entries: entries,
            bodyweight: profile?.bodyweight ?? 0
        )
    }
    private var todayEntries: [LiftEntry] {
        entries.filter { Calendar.current.isDateInToday($0.date) }
    }
    private var recentSummaries: [ExerciseSummary] {
        Array(LiftAnalytics.summaries(from: entries).prefix(3))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                topBar
                pageTitle
                rankSnapshot
                todayStatus
                logButton
                lastSetCard
                if !recentSummaries.isEmpty {
                    recentExercises
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 14)
            .padding(.bottom, 28)
        }
        .background(Color.paper)
    }

    private var topBar: some View {
        HStack(alignment: .center) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()).uppercased())
                .font(.subheadline.bold())
                .fontWidth(.condensed)
                .tracking(1.8)
                .foregroundStyle(Color.inkMuted)

            Spacer()

            HStack(spacing: 8) {
                Button(action: onTimerTap) {
                    Image(systemName: "timer")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.ink)
                        .frame(width: 46, height: 46)
                        .background(Color.hairline.opacity(0.42), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open rest timer")

                Button(action: onSettingsTap) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.ink)
                        .frame(width: 46, height: 46)
                        .background(Color.hairline.opacity(0.42), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open settings")
            }
        }
    }

    private var pageTitle: some View {
        HStack(alignment: .lastTextBaseline) {
            Text("TODAY")
                .editorialTitle(size: 62, lineSpacing: -4)
                .foregroundStyle(Color.ink)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Text(todayEntries.isEmpty ? "READY" : "IN PROGRESS")
                .font(.system(size: 11, weight: .black))
                .tracking(1.4)
                .foregroundStyle(todayEntries.isEmpty ? Color.inkMuted : Color.signalOrange)
        }
    }

    private var rankSnapshot: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("CURRENT RANK")
                        .font(.system(size: 10, weight: .black))
                        .tracking(1.8)
                        .foregroundStyle(Color.signalPaper.opacity(0.58))
                    Text(overview.rank.rawValue.uppercased())
                        .editorialTitle(size: 40)
                        .foregroundStyle(Color.signalPaper)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.2f×", overview.score))
                        .font(.system(size: 30, weight: .black))
                        .fontWidth(.compressed)
                        .foregroundStyle(Color.signalOrange)
                    Text("BODYWEIGHT")
                        .font(.system(size: 9, weight: .black))
                        .tracking(1.2)
                        .foregroundStyle(Color.signalPaper.opacity(0.5))
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.signalPaper.opacity(0.14))
                    Capsule()
                        .fill(Color.signalOrange)
                        .frame(width: max(8, geometry.size.width * overview.progress))
                }
            }
            .frame(height: 7)

            HStack(spacing: 0) {
                dashboardStat(value: "\(appStats?.streak ?? 0)", label: "STREAK")
                divider
                dashboardStat(value: "\(todayEntries.count)", label: "SETS TODAY")
                divider
                dashboardStat(value: "\(appStats?.xp ?? 0)", label: "XP")
            }
        }
        .padding(20)
        .background(Color.signalInk, in: RoundedRectangle(cornerRadius: 22))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Current rank \(overview.rank.rawValue), strength score \(String(format: "%.2f", overview.score)) times bodyweight, \(appStats?.streak ?? 0) day streak, \(todayEntries.count) sets today"
        )
    }

    private var todayStatus: some View {
        HStack(spacing: 12) {
            Image(systemName: todayEntries.isEmpty ? "circle" : "checkmark.circle.fill")
                .font(.system(size: 25, weight: .bold))
                .foregroundStyle(todayEntries.isEmpty ? Color.inkFaint : Color.signalOrange)

            VStack(alignment: .leading, spacing: 2) {
                Text(todayEntries.isEmpty ? "No sets logged yet" : todaySetSummary)
                    .font(.system(size: 17, weight: .black))
                    .fontWidth(.condensed)
                    .foregroundStyle(Color.ink)
                Text(todayEntries.isEmpty ? "Start with one strong set." : "Keep going when you’re ready.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.inkMuted)
            }

            Spacer()
        }
        .padding(.horizontal, 4)
        .accessibilityElement(children: .combine)
    }

    private var logButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onLogTap()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 23, weight: .black))
                Text("LOG A SET")
                    .posterLabel(size: 28)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
        }
        .buttonStyle(OrangeButtonStyle())
        .shadow(color: Color.signalOrange.opacity(0.18), radius: 12, y: 8)
        .accessibilityHint("Opens the quick set logger")
    }

    @ViewBuilder
    private var lastSetCard: some View {
        if let latestEntry,
           let muscleGroup = latestEntry.muscleGroup {
            VStack(alignment: .leading, spacing: 15) {
                Text("LAST SET")
                    .sectionEyebrow()

                HStack(spacing: 14) {
                    ExerciseIcon(muscleGroup: muscleGroup, size: 54, inverted: true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(latestEntry.liftType)
                            .displayLabel(size: 17)
                            .foregroundStyle(Color.ink)
                            .lineLimit(1)
                        Text(lastSetDescription(latestEntry))
                            .displayLabel(size: 29)
                            .foregroundStyle(Color.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }

                    Spacer(minLength: 4)

                    RankPill(
                        rank: LiftAnalytics.exerciseScore(
                            entries: entries.filter { $0.liftType == latestEntry.liftType },
                            bodyweight: profile?.bodyweight ?? 1
                        ).rank
                    )
                }

                HStack(spacing: 10) {
                    secondaryAction("VIEW HISTORY", icon: "chart.xyaxis.line") {
                        onExerciseTap(latestEntry.liftType, muscleGroup)
                    }
                    secondaryAction("REPEAT SET", icon: "arrow.clockwise") {
                        quickLog(latestEntry)
                    }
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle(cornerRadius: 18)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("LAST SET")
                    .sectionEyebrow()
                Text("Your first set will appear here.")
                    .font(.system(size: 17, weight: .bold))
                    .fontWidth(.condensed)
                    .foregroundStyle(Color.ink)
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
            .cardStyle(cornerRadius: 18)
        }
    }

    private var recentExercises: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RECENT EXERCISES")
                .sectionEyebrow()

            ForEach(recentSummaries) { summary in
                Button {
                    quickLog(summary.latestEntry)
                } label: {
                    HStack(spacing: 12) {
                        ExerciseIcon(muscleGroup: summary.muscleGroup, size: 42)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(summary.name)
                                .font(.system(size: 16, weight: .black))
                                .fontWidth(.condensed)
                                .foregroundStyle(Color.ink)
                            Text("Last: \(lastSetDescription(summary.latestEntry))")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.inkMuted)
                        }
                        Spacer()
                        Text("LOG")
                            .font(.system(size: 11, weight: .black))
                            .tracking(1)
                            .foregroundStyle(Color.signalOrange)
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(Color.signalOrange)
                    }
                    .padding(13)
                    .cardStyle(cornerRadius: 15)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Logs another set of \(summary.name)")
            }
        }
    }

    private var todaySetSummary: String {
        "\(todayEntries.count) set\(todayEntries.count == 1 ? "" : "s") logged today"
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.signalPaper.opacity(0.16))
            .frame(width: 1, height: 30)
    }

    private func dashboardStat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .black))
                .fontWidth(.compressed)
                .foregroundStyle(Color.signalPaper)
            Text(label)
                .font(.system(size: 8, weight: .black))
                .tracking(1)
                .foregroundStyle(Color.signalPaper.opacity(0.52))
        }
        .frame(maxWidth: .infinity)
    }

    private func secondaryAction(
        _ title: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 11, weight: .black))
                .fontWidth(.condensed)
                .foregroundStyle(Color.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.hairline.opacity(0.28), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func quickLog(_ entry: LiftEntry) {
        let exercise = ExerciseCatalog.exercise(named: entry.liftType, context: modelContext)
            ?? Exercise(
                name: entry.liftType,
                muscleGroup: entry.muscleGroup ?? .legs,
                loadType: entry.loadType,
                sideTracking: entry.side == .both ? .combined : .separate
            )
        onQuickLog(exercise, entry.side == .both ? nil : entry.side)
    }

    private func lastSetDescription(_ entry: LiftEntry) -> String {
        let side = entry.side == .both ? "" : "\(entry.side.shortLabel) · "
        let assist = entry.loadType == .assistance ? " assist" : ""
        return "\(side)\(entry.weight.formattedWeight) lb\(assist) × \(entry.reps)"
    }
}

struct ExerciseIcon: View {
    let muscleGroup: MuscleGroup
    var size: CGFloat = 48
    var inverted = false

    var body: some View {
        Image(systemName: muscleGroup.iconName)
            .font(.system(size: size * 0.36, weight: .bold))
            .foregroundStyle(inverted ? Color.paper : Color.ink)
            .frame(width: size, height: size)
            .background(inverted ? Color.ink : Color.hairline.opacity(0.35), in: Circle())
            .accessibilityHidden(true)
    }
}

struct RankPill: View {
    let rank: Rank

    var body: some View {
        Text(rank.rawValue.uppercased())
            .posterLabel(size: 12)
            .tracking(1)
            .foregroundStyle(Color.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(rank.color.opacity(0.28), in: Capsule())
    }
}
