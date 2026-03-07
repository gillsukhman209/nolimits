//
//  HomeView.swift
//  No Limits
//
//  Created by Sukhman Singh on 3/5/26.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    let onLogTap: () -> Void
    let onRankUp: (Rank, MuscleGroup) -> Void
    var onExerciseTap: ((String, MuscleGroup) -> Void)? = nil

    @Environment(\.modelContext) private var modelContext
    @State private var vm = HomeViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            // Gradient background
            LinearGradient.screenBg.ignoresSafeArea()

            if vm.totalLifts == 0 {
                emptyState
            } else {
                mainContent
            }

            // Floating log button
            if vm.totalLifts > 0 {
                floatingLogButton
            }
        }
        .onAppear { vm.refresh(context: modelContext) }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                // Glowing orbs
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.accentOrange.opacity(0.20), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.accentRed.opacity(0.12), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .offset(x: 30, y: -20)

                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(LinearGradient.accent)
            }

            Spacer().frame(height: 40)

            Text("Start Your Journey")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.white)

            Spacer().frame(height: 10)

            Text("Log your first lift to unlock\nyour strength rank.")
                .font(.system(size: 15))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Spacer().frame(height: 36)

            Button(action: onLogTap) {
                HStack(spacing: 10) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text("Log First Lift")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(width: 220, height: 54)
                .background(LinearGradient.accent)
                .clipShape(Capsule())
                .shadow(color: Color.accentOrange.opacity(0.4), radius: 20, y: 4)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Top bar
                topBar
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                // Hero banner
                heroBanner
                    .padding(.top, 16)
                    .padding(.horizontal, 20)

                // Quick stats row
                statsRow
                    .padding(.top, 18)
                    .padding(.horizontal, 20)

                // Body map (compact)
                bodyMapSection
                    .padding(.top, 22)
                    .padding(.horizontal, 20)

                // Muscle leaderboard
                muscleLeaderboard
                    .padding(.top, 22)
                    .padding(.horizontal, 20)

                // Recent activity
                recentSection
                    .padding(.top, 22)
                    .padding(.horizontal, 20)

                Spacer().frame(height: 110)
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textSecondary)
                Text(vm.todayLogged ? "Lift logged" : "Time to lift")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }

            Spacer()

            if vm.streak > 0 {
                HStack(spacing: 5) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.accentRed)
                    Text("\(vm.streak)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.accentRed.opacity(0.15))
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(Color.accentRed.opacity(0.25), lineWidth: 1))
            }
        }
    }

    // MARK: - Hero Banner

    private var heroBanner: some View {
        ZStack {
            // Rank-colored gradient background
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            vm.overallRank.color.opacity(0.30),
                            vm.overallRank.color.opacity(0.08),
                            Color.cardBg.opacity(0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            // Glass border
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(
                    LinearGradient(
                        colors: [vm.overallRank.color.opacity(0.40), vm.overallRank.color.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )

            VStack(spacing: 12) {
                // Rank badge
                HStack(spacing: 6) {
                    Image(systemName: vm.overallRank.symbolName)
                        .font(.system(size: 12, weight: .semibold))
                    Text(vm.overallRank.rawValue.uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .tracking(3)
                }
                .foregroundColor(vm.overallRank.color)

                // Score
                Text(String(format: "%.2f", vm.overallScore))
                    .font(.system(size: 56, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                // Progress bar
                VStack(spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.08))
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [vm.overallRank.color, vm.overallRank.color.opacity(0.6)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(geo.size.width * vm.overallProgress, 6))
                                .shadow(color: vm.overallRank.color.opacity(0.5), radius: 6)
                        }
                    }
                    .frame(height: 6)
                    .clipShape(Capsule())

                    HStack {
                        Text(vm.overallRank.rawValue)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(vm.overallRank.color.opacity(0.7))
                        Spacer()
                        if let next = vm.overallRank.nextRank {
                            Text(next.rawValue)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(next.color.opacity(0.5))
                        } else {
                            Text("MAX")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(vm.overallRank.color.opacity(0.7))
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
            .padding(.vertical, 28)
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 10) {
            statPill(
                icon: "dumbbell.fill",
                value: "\(vm.totalLifts)",
                label: "Lifts",
                color: .accentOrange
            )
            statPill(
                icon: "flame.fill",
                value: "\(vm.streak)",
                label: "Streak",
                color: .accentRed
            )
            statPill(
                icon: "arrow.up.right",
                value: "\(Int(vm.overallProgress * 100))%",
                label: "Progress",
                color: .accentGreen
            )
        }
    }

    private func statPill(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(color.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Body Map Section

    private var bodyMapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MUSCLE MAP")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.textSecondary)
                .tracking(2)
                .padding(.horizontal, 4)

            BodyMapView(muscleRanks: vm.muscleRanks)
                .frame(height: 300)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.cardBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(LinearGradient.glassEdge, lineWidth: 1)
                        )
                )
        }
    }

    // MARK: - Muscle Leaderboard

    private var muscleLeaderboard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MUSCLE RANKS")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.textSecondary)
                .tracking(2)
                .padding(.horizontal, 4)

            VStack(spacing: 6) {
                ForEach(vm.muscleRankList.sorted(by: { $0.score > $1.score })) { info in
                    muscleRow(info: info)
                }
            }
        }
    }

    private func muscleRow(info: MuscleRankInfo) -> some View {
        HStack(spacing: 12) {
            // Rank color indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(info.rank.color)
                .frame(width: 4, height: 32)

            // Muscle name
            Text(info.muscle.rawValue)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)

            Spacer()

            // Progress bar (compact)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.06))
                    Capsule()
                        .fill(info.rank.color)
                        .frame(width: max(geo.size.width * info.progress, 3))
                }
            }
            .frame(width: 50, height: 4)

            // Rank badge
            Text(info.rank.rawValue)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(info.rank.color)
                .frame(width: 62, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(info.rank.color.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(info.rank.color.opacity(0.10), lineWidth: 1)
        )
    }

    // MARK: - Recent Activity

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RECENT")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.textSecondary)
                .tracking(2)
                .padding(.horizontal, 4)

            if vm.recentLifts.isEmpty {
                Text("No lifts yet")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                ForEach(vm.recentLifts.prefix(5), id: \.id) { entry in
                    Button(action: {
                        if let muscle = entry.muscleGroup {
                            onExerciseTap?(entry.liftType, muscle)
                        }
                    }) {
                        LiftHistoryRow(
                            liftName: entry.liftType,
                            weight: Int(entry.weight),
                            reps: entry.reps,
                            label: vm.relativeLabel(for: entry),
                            muscleGroup: entry.muscleGroup
                        )
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteLift(entry)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Floating Log Button

    private var floatingLogButton: some View {
        Button(action: onLogTap) {
            HStack(spacing: 10) {
                Image(systemName: vm.todayLogged ? "pencil" : "plus")
                    .font(.system(size: 15, weight: .bold))
                Text(vm.todayLogged ? "Log Another" : "Log Lift")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
            .background(LinearGradient.accent)
            .clipShape(Capsule())
            .shadow(color: Color.accentOrange.opacity(0.4), radius: 20, y: 4)
        }
        .buttonStyle(.plain)
        .padding(.bottom, 36)
    }

    // MARK: - Delete Lift

    private func deleteLift(_ entry: LiftEntry) {
        let muscle = entry.muscleGroup
        modelContext.delete(entry)

        if let stats = try? modelContext.fetch(FetchDescriptor<AppStats>()).first {
            stats.totalLifts = max(stats.totalLifts - 1, 0)

            if let muscle = muscle {
                let muscleName = muscle.rawValue
                var desc = FetchDescriptor<LiftEntry>(
                    predicate: #Predicate<LiftEntry> { $0.muscleGroupRaw == muscleName }
                )
                desc.fetchLimit = 500
                let remaining = (try? modelContext.fetch(desc)) ?? []
                let newBest = remaining.map(\.e1RM).max() ?? 0
                stats.setBestE1RM(for: muscle, value: newBest)
            }
        }

        try? modelContext.save()
        vm.refresh(context: modelContext)
    }

    // MARK: - Greeting

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default:      return "Good evening"
        }
    }
}

// MARK: - Stat Tile

struct StatTile: View {
    let value: String
    let unit: String?
    let label: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                if let unit {
                    Text(unit)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
            }
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(color.opacity(0.12), lineWidth: 1)
        )
    }
}

// MARK: - Mini Stat Card

struct MiniStatCard: View {
    let label: String
    let value: String
    let symbolName: String
    let color: Color

    var body: some View {
        StatTile(value: value, unit: nil, label: label, color: color)
    }
}

// MARK: - Lift History Row

struct LiftHistoryRow: View {
    let liftName: String
    let weight: Int
    let reps: Int
    let label: String
    var muscleGroup: MuscleGroup? = nil

    var body: some View {
        HStack(spacing: 12) {
            // Colored icon circle
            ZStack {
                Circle()
                    .fill(Color.accentOrange.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.accentOrange)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(liftName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                HStack(spacing: 5) {
                    if let muscle = muscleGroup {
                        Text(muscle.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.accentOrange)
                    }
                    Text(label)
                        .font(.system(size: 12))
                        .foregroundColor(.textSecondary)
                }
            }

            Spacer()

            Text("\(weight) x \(reps)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(LinearGradient.glassEdge, lineWidth: 1)
        )
    }
}

// MARK: - Muscle Rank Tile

struct MuscleRankTile: View {
    let info: MuscleRankInfo
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(info.muscle.rawValue)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: info.rank.symbolName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(info.rank.color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.06))
                    Capsule()
                        .fill(info.rank.color)
                        .frame(width: max(geo.size.width * info.progress, 4))
                }
            }
            .frame(height: 5)
            Text(info.rank.rawValue)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(info.rank.color)
        }
        .padding(14)
        .cardStyle(cornerRadius: 14)
    }
}

// MARK: - Muscle Rank Row

struct MuscleRankRow: View {
    let info: MuscleRankInfo
    var body: some View {
        MuscleRankTile(info: info)
    }
}

#Preview {
    HomeView(onLogTap: {}, onRankUp: { _, _ in }, onExerciseTap: { _, _ in })
        .modelContainer(for: [UserProfile.self, LiftEntry.self, AppStats.self, CustomExercise.self], inMemory: true)
}
