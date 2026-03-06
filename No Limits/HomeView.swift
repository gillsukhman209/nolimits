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

    @Environment(\.modelContext) private var modelContext
    @State private var vm = HomeViewModel()

    var body: some View {
        ZStack(alignment: .top) {
            Color.appBg.ignoresSafeArea()

            // Ambient glow behind rank badge
            Circle()
                .fill(vm.overallRank.color.opacity(0.12))
                .frame(width: 320, height: 320)
                .blur(radius: 60)
                .offset(y: 100)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    headerRow

                    if vm.totalLifts == 0 {
                        emptyState
                    } else {
                        overallRankCard
                        bodyMapSection
                        logButton
                        muscleRanksList
                        statsRow
                        recentLiftsSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 64)
                .padding(.bottom, 48)
            }
        }
        .onAppear { vm.refresh(context: modelContext) }
    }

    // MARK: - Empty State

    var emptyState: some View {
        VStack(spacing: 28) {
            Spacer().frame(height: 40)

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.accentOrange.opacity(0.18), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)

                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 52, weight: .semibold))
                    .foregroundStyle(LinearGradient.accent)
            }

            VStack(spacing: 10) {
                Text("No lifts yet")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.white)

                Text("Log your first lift to see your\nstrength score and rank.")
                    .font(.system(size: 16))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Button(action: onLogTap) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("Log Your First Lift")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(LinearGradient.accent)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)

            Spacer().frame(height: 20)
        }
    }

    // MARK: - Header

    var headerRow: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                Text(vm.todayLogged ? "Lift logged. Nice work." : "Time to lift.")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }

            Spacer()

            if vm.streak > 0 {
                HStack(spacing: 5) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(LinearGradient.accent)
                    Text("\(vm.streak)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text("day streak")
                        .font(.system(size: 13))
                        .foregroundColor(.textSecondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Color.accentOrange.opacity(0.12))
                .overlay(Capsule().strokeBorder(Color.accentOrange.opacity(0.35), lineWidth: 1))
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - Overall Rank Card

    var overallRankCard: some View {
        VStack(spacing: 0) {
            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(vm.overallRank.color.opacity(0.12))
                        .frame(width: 108, height: 108)
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [vm.overallRank.color, vm.overallRank.color.opacity(0.25)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 108, height: 108)
                    Image(systemName: vm.overallRank.symbolName)
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundColor(vm.overallRank.color)
                }

                VStack(spacing: 4) {
                    Text(vm.overallRank.rawValue.uppercased())
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(vm.overallRank.color)
                        .tracking(3.5)

                    Text(String(format: "%.2f", vm.overallScore))
                        .font(.system(size: 58, weight: .black, design: .rounded))
                        .foregroundColor(.white)

                    Text("Overall Strength Score")
                        .font(.system(size: 13))
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(.top, 36)

            // Progress bar
            VStack(spacing: 10) {
                HStack {
                    Text(vm.overallRank.rawValue)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(vm.overallRank.color)
                    Spacer()
                    Text(vm.overallRank.nextRank?.rawValue ?? "MAX")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(vm.overallRank.nextRank?.color ?? Color.white.opacity(0.3))
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 10)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [vm.overallRank.color, vm.overallRank.nextRank?.color ?? vm.overallRank.color],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * vm.overallProgress, height: 10)
                    }
                }
                .frame(height: 10)

                Text("\(Int(vm.overallProgress * 100))% to \(vm.overallRank.nextRank?.rawValue ?? "MAX")")
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)
            .padding(.bottom, 32)
        }
        .cardStyle(cornerRadius: 24)
    }

    // MARK: - Body Map

    var bodyMapSection: some View {
        VStack(spacing: 16) {
            Text("Muscle Map")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            BodyMapView(muscleRanks: vm.muscleRanks)
                .frame(height: 420)
        }
        .padding(.vertical, 20)
        .cardStyle(cornerRadius: 20)
    }

    // MARK: - Log Button

    var logButton: some View {
        Button(action: onLogTap) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: vm.todayLogged ? "pencil" : "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.todayLogged ? "Log Another Lift" : "Log Today's Lift")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    Text(vm.todayLogged ? "Keep the gains coming" : "Pick an exercise and go")
                        .font(.system(size: 13))
                        .foregroundColor(Color.white.opacity(0.65))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.6))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(LinearGradient.accent)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Muscle Ranks List

    var muscleRanksList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Muscle Ranks")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            VStack(spacing: 8) {
                ForEach(vm.muscleRankList) { info in
                    MuscleRankRow(info: info)
                }
            }
        }
    }

    // MARK: - Stats Row

    var statsRow: some View {
        HStack(spacing: 12) {
            // XP card (commented out — uncomment to re-enable)
            // MiniStatCard(label: "XP", value: "\(vm.xp)", symbolName: "star.fill", color: .accentOrange)
            MiniStatCard(label: "Streak", value: "\(vm.streak)d", symbolName: "flame.fill", color: .red)
            MiniStatCard(label: "Lifts", value: "\(vm.totalLifts)", symbolName: "dumbbell.fill", color: Color(red: 0.42, green: 0.76, blue: 1.00))
        }
    }

    // MARK: - Recent Lifts

    var recentLiftsSection: some View {
        Group {
            if vm.recentLifts.isEmpty {
                EmptyView()
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Lifts")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    VStack(spacing: 8) {
                        ForEach(vm.recentLifts, id: \.id) { entry in
                            LiftHistoryRow(
                                liftName: entry.liftType,
                                weight: Int(entry.weight),
                                reps: entry.reps,
                                label: vm.relativeLabel(for: entry),
                                muscleGroup: entry.muscleGroup
                            )
                        }
                    }
                }
            }
        }
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

// MARK: - Muscle Rank Row

struct MuscleRankRow: View {
    let info: MuscleRankInfo

    var body: some View {
        HStack(spacing: 14) {
            // Rank icon
            ZStack {
                Circle()
                    .fill(info.rank.color.opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: info.rank.symbolName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(info.rank.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(info.muscle.rawValue)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Text(info.rank.rawValue)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(info.rank.color)
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(info.rank.color)
                            .frame(width: geo.size.width * info.progress, height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .cardStyle(cornerRadius: 14)
    }
}

// MARK: - Mini Stat Card

struct MiniStatCard: View {
    let label: String
    let value: String
    let symbolName: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: symbolName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .cardStyle(cornerRadius: 16)
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
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(liftName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                HStack(spacing: 6) {
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

            Text("\(weight) lbs x \(reps)")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .cardStyle(cornerRadius: 14)
    }
}

#Preview {
    HomeView(onLogTap: {}, onRankUp: { _, _ in })
        .modelContainer(for: [UserProfile.self, LiftEntry.self, AppStats.self], inMemory: true)
}
