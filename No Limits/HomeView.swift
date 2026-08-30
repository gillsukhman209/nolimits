import SwiftData
import SwiftUI

struct HomeView: View {
    let onLogTap: () -> Void
    let onTimerTap: () -> Void
    let onSettingsTap: () -> Void
    let onExerciseTap: (String, MuscleGroup) -> Void
    let onQuickLog: (Exercise, ExerciseSide?) -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(sort: \LiftEntry.date, order: .reverse) private var entries: [LiftEntry]
    @Query private var stats: [AppStats]

    private var profile: UserProfile? { profiles.first }
    private var latestEntry: LiftEntry? { entries.first }
    private var appStats: AppStats? { stats.first }
    private var todayEntries: [LiftEntry] {
        entries.filter { Calendar.current.isDateInToday($0.date) }
    }
    private var todayExerciseCount: Int {
        Set(todayEntries.map(\.liftType)).count
    }
    private var todayVolume: Double {
        LiftAnalytics.totalVolume(entries: todayEntries, bodyweight: profile?.bodyweight ?? 0)
    }
    private var recentSummaries: [ExerciseSummary] {
        Array(LiftAnalytics.summaries(from: entries).prefix(4))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                topBar
                pageTitle
                trainingSnapshot
                logButton
                if let latestEntry {
                    lastSetCard(latestEntry)
                }
                if !recentSummaries.isEmpty {
                    recentExercises
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .background(Color.paper)
    }

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(Date.now.formatted(.dateTime.weekday(.wide)).uppercased())
                    .font(.system(size: 11, weight: .black))
                    .tracking(1.8)
                    .foregroundStyle(Color.signalOrange)
                Text(Date.now.formatted(.dateTime.month(.wide).day()))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.inkMuted)
            }
            Spacer()
            Button(action: onTimerTap) {
                Image(systemName: "timer")
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(Color.ink)
                    .frame(width: 42, height: 42)
                    .background(Color.hairline.opacity(0.35), in: Circle())
            }
            .accessibilityLabel("Rest timer")
            Button(action: onSettingsTap) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 35))
                    .foregroundStyle(Color.ink)
            }
            .accessibilityLabel("Settings")
        }
    }

    private var pageTitle: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(todayEntries.isEmpty ? "READY TO" : "TODAY’S")
                .sectionEyebrow()
            Text(todayEntries.isEmpty ? "TRAIN" : "TRAINING")
                .editorialTitle(size: 54, lineSpacing: -5)
                .foregroundStyle(Color.ink)
        }
    }

    private var trainingSnapshot: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(todayEntries.isEmpty ? "START FRESH" : "SESSION SO FAR")
                        .font(.system(size: 11, weight: .black))
                        .tracking(1.8)
                        .foregroundStyle(Color.signalPaper.opacity(0.62))
                    Text(todayEntries.isEmpty ? "ONE SET AT A TIME" : todaySetSummary)
                        .font(.system(size: 27, weight: .black))
                        .fontWidth(.compressed)
                        .foregroundStyle(Color.signalPaper)
                }
                Spacer()
                Image(systemName: todayEntries.isEmpty ? "dumbbell.fill" : "checkmark.circle.fill")
                    .font(.system(size: 27, weight: .black))
                    .foregroundStyle(Color.signalOrange)
            }

            HStack(spacing: 0) {
                dashboardStat(value: "\(todayEntries.count)", label: "SETS")
                divider
                dashboardStat(value: "\(todayExerciseCount)", label: "EXERCISES")
                divider
                dashboardStat(value: compactWeight(todayVolume), label: "LB WORK")
                divider
                dashboardStat(value: "\(appStats?.streak ?? 0)", label: "STREAK")
            }
        }
        .padding(20)
        .background(Color.signalInk, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(todayEntries.count) sets across \(todayExerciseCount) exercises today, \(Int(todayVolume)) pounds of work, \(appStats?.streak ?? 0) day streak"
        )
    }

    private var logButton: some View {
        Button(action: onLogTap) {
            HStack {
                Text("LOG A SET")
                    .font(.system(size: 21, weight: .black))
                    .fontWidth(.compressed)
                Spacer()
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .black))
            }
            .padding(.horizontal, 22)
            .frame(height: 60)
        }
        .buttonStyle(OrangeButtonStyle())
    }

    private func lastSetCard(_ entry: LiftEntry) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("LAST SET").sectionEyebrow()
                Spacer()
                Text(entry.date.formatted(.relative(presentation: .named)))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.inkMuted)
            }
            HStack(spacing: 14) {
                ExerciseIcon(muscleGroup: entry.muscleGroup ?? .legs, size: 50, inverted: true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.liftType)
                        .font(.system(size: 20, weight: .black))
                        .fontWidth(.condensed)
                        .foregroundStyle(Color.ink)
                    Text(lastSetDescription(entry))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.inkMuted)
                }
                Spacer()
            }
            HStack(spacing: 10) {
                secondaryAction(title: "VIEW PROGRESS", icon: "chart.xyaxis.line") {
                    guard let muscle = entry.muscleGroup else { return }
                    onExerciseTap(entry.liftType, muscle)
                }
                secondaryAction(title: "REPEAT SET", icon: "arrow.clockwise") {
                    quickLog(entry)
                }
            }
        }
        .padding(17)
        .cardStyle(cornerRadius: 19)
    }

    private var recentExercises: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RECENT EXERCISES").sectionEyebrow()
            ForEach(recentSummaries) { summary in
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
                            Text("\(summary.latestEntry.weight.formattedWeight) lb × \(summary.latestEntry.reps) · \(summary.logCount) sets")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color.inkMuted)
                        }
                        Spacer()
                        if let trend = LiftAnalytics.recentTrendPercent(entries: summary.entries) {
                            Text("\(trend >= 0 ? "+" : "")\(trend, format: .number.precision(.fractionLength(1)))%")
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(trend > 0.5 ? Color.success : Color.inkMuted)
                        }
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

    private var todaySetSummary: String {
        "\(todayEntries.count) SET\(todayEntries.count == 1 ? "" : "S") COMPLETE"
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.signalPaper.opacity(0.12))
            .frame(width: 1, height: 31)
    }

    private func dashboardStat(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 21, weight: .black))
                .fontWidth(.compressed)
                .foregroundStyle(Color.signalPaper)
                .minimumScaleFactor(0.65)
            Text(label)
                .font(.system(size: 8, weight: .black))
                .tracking(0.8)
                .foregroundStyle(Color.signalPaper.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
    }

    private func secondaryAction(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 11, weight: .black))
                .fontWidth(.condensed)
                .foregroundStyle(Color.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(Color.hairline.opacity(0.36), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func quickLog(_ entry: LiftEntry) {
        guard let exercise = ExerciseCatalog.exercise(named: entry.liftType, context: modelContext) else {
            return
        }
        onQuickLog(exercise, entry.side == .both ? nil : entry.side)
    }

    private func lastSetDescription(_ entry: LiftEntry) -> String {
        let side = entry.side == .both ? "" : "\(entry.side.rawValue) · "
        let load = entry.loadType == .assistance
            ? "\(entry.weight.formattedWeight) lb assist"
            : "\(entry.weight.formattedWeight) lb"
        return "\(side)\(load) × \(entry.reps)"
    }

    private func compactWeight(_ value: Double) -> String {
        if value >= 10_000 {
            return "\((value / 1_000).formatted(.number.precision(.fractionLength(1))))K"
        }
        return value.formatted(.number.precision(.fractionLength(0)))
    }
}

struct ExerciseIcon: View {
    let muscleGroup: MuscleGroup
    var size: CGFloat = 48
    var inverted = false

    var body: some View {
        Image(systemName: muscleGroup.iconName)
            .font(.system(size: size * 0.33, weight: .black))
            .foregroundStyle(inverted ? Color.paper : Color.ink)
            .frame(width: size, height: size)
            .background(inverted ? Color.ink : Color.hairline.opacity(0.34), in: Circle())
            .accessibilityHidden(true)
    }
}
