import SwiftUI
import SwiftData
import UIKit

struct HomeView: View {
    let onLogTap: () -> Void
    let onSettingsTap: () -> Void
    let onExerciseTap: (String, MuscleGroup) -> Void

    @Query(sort: \LiftEntry.date, order: .reverse) private var entries: [LiftEntry]
    @Query private var profiles: [UserProfile]
    @Query private var stats: [AppStats]

    private var profile: UserProfile? { profiles.first }
    private var latestEntry: LiftEntry? { entries.first }
    private var loggedToday: Bool {
        entries.contains { Calendar.current.isDateInToday($0.date) }
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    topBar
                    hero
                        .padding(.top, geometry.size.height > 720 ? 8 : 4)

                    status
                        .padding(.top, geometry.size.height > 720 ? 34 : 22)

                    Spacer(minLength: 28)

                    logButton
                    lastLiftCard
                        .padding(.top, 18)
                }
                .padding(.horizontal, 26)
                .padding(.top, 14)
                .padding(.bottom, 22)
                .frame(minHeight: geometry.size.height, alignment: .top)
            }
        }
        .background(Color.paper)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    private var topBar: some View {
        HStack(alignment: .center) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()).uppercased())
                .font(.subheadline.bold())
                .fontWidth(.condensed)
                .tracking(1.8)
                .foregroundStyle(Color.inkMuted)

            Spacer()

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

    private var hero: some View {
        Text("READY WHEN\nYOU ARE")
            .editorialTitle(size: 88, lineSpacing: -4)
            .minimumScaleFactor(0.74)
            .foregroundStyle(Color.ink)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }

    private var status: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .stroke(loggedToday ? Color.signalOrange : Color.hairline, lineWidth: 2)
                    .frame(width: 30, height: 30)

                if loggedToday {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(Color.signalOrange)
                }
            }
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(loggedToday ? "Today is logged" : "Today is not logged")
                    .displayLabel(size: 21)
                    .foregroundStyle(Color.ink)

                Text(loggedToday ? "Good work. Add another if you want." : "Log one lift. See your progress.")
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.inkMuted)
            }
        }
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
                Text("LOG A LIFT")
                    .posterLabel(size: 28)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
        }
        .buttonStyle(OrangeButtonStyle())
        .shadow(color: Color.signalOrange.opacity(0.18), radius: 12, y: 8)
        .accessibilityHint("Opens the quick lift logger")
    }

    @ViewBuilder
    private var lastLiftCard: some View {
        if let latestEntry,
           let muscleGroup = latestEntry.muscleGroup {
            Button {
                onExerciseTap(latestEntry.liftType, muscleGroup)
            } label: {
                VStack(alignment: .leading, spacing: 14) {
                    Text("LAST LIFT")
                        .sectionEyebrow()

                    HStack(spacing: 15) {
                        ExerciseIcon(muscleGroup: muscleGroup, size: 58, inverted: true)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(latestEntry.liftType)
                                .displayLabel(size: 17)
                                .foregroundStyle(Color.ink)
                                .lineLimit(1)

                            Text(lastLiftDescription(latestEntry))
                                .displayLabel(size: 34)
                                .foregroundStyle(Color.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                        }

                        Spacer(minLength: 6)

                        let exerciseOverview = LiftAnalytics.exerciseScore(
                            entries: entries.filter { $0.liftType == latestEntry.liftType },
                            bodyweight: profile?.bodyweight ?? 1
                        )
                        RankPill(rank: exerciseOverview.rank)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(Color.ink)
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle(cornerRadius: 18)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Shows history and stats for \(latestEntry.liftType)")
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("LAST LIFT")
                    .sectionEyebrow()
                Text("Your first lift will appear here.")
                    .font(.system(size: 17, weight: .bold))
                    .fontWidth(.condensed)
                    .foregroundStyle(Color.ink)
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
            .cardStyle(cornerRadius: 18)
        }
    }

    private func lastLiftDescription(_ entry: LiftEntry) -> String {
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
