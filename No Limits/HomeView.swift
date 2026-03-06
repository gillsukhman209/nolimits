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
    @State private var appeared = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                headerRow

                if vm.totalLifts == 0 {
                    emptyState
                } else {
                    heroScoreCard
                    logButton
                    bodyMapSection
                    muscleRanksList
                    statsRow
                    recentLiftsSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 48)
        }
        .background {
            ZStack {
                Color.appBg

                // Ambient rank glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [vm.overallRank.color.opacity(0.28), vm.overallRank.color.opacity(0.08), .clear],
                            center: .center,
                            startRadius: 30,
                            endRadius: 240
                        )
                    )
                    .frame(width: 500, height: 500)
                    .offset(y: 40)
                    .blur(radius: 50)

                // Secondary warm glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.accentOrange.opacity(0.10), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 180
                        )
                    )
                    .frame(width: 360, height: 360)
                    .offset(x: -80, y: 200)
                    .blur(radius: 60)
            }
            .ignoresSafeArea()
        }
        .onAppear {
            vm.refresh(context: modelContext)
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) { appeared = true }
        }
    }

    // MARK: - Empty State

    var emptyState: some View {
        VStack(spacing: 32) {
            Spacer().frame(height: 32)

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.accentOrange.opacity(0.20), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)

                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(LinearGradient.accent)
                    .glow(.accentOrange, radius: 12)
            }

            VStack(spacing: 12) {
                Text("No lifts yet")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundColor(.white)

                Text("Log your first lift to unlock\nyour strength rank.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Button(action: onLogTap) {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("Log Your First Lift")
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(LinearGradient.accent)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .glow(.accentOrange, radius: 6)
            }
            .buttonStyle(.plain)

            Spacer().frame(height: 16)
        }
    }

    // MARK: - Header

    var headerRow: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text(greeting)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.accentOrange)
                Text(vm.todayLogged ? "Lift logged. Nice." : "Time to lift.")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }

            Spacer()

            if vm.streak > 0 {
                HStack(spacing: 5) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(LinearGradient.accent)
                    Text("\(vm.streak)")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [Color.accentOrange.opacity(0.15), Color.accentRed.opacity(0.10)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.accentOrange.opacity(0.45), Color.accentRed.opacity(0.25)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1
                        )
                )
                .clipShape(Capsule())
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -10)
    }

    // MARK: - Hero Score Card

    var heroScoreCard: some View {
        VStack(spacing: 0) {
            // Top section: rank icon + score
            VStack(spacing: 16) {
                ZStack {
                    // Outer glow ring
                    Circle()
                        .fill(vm.overallRank.color.opacity(0.08))
                        .frame(width: 120, height: 120)

                    Circle()
                        .strokeBorder(
                            AngularGradient(
                                colors: [vm.overallRank.color, vm.overallRank.color.opacity(0.15), vm.overallRank.color],
                                center: .center
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 100, height: 100)

                    Image(systemName: vm.overallRank.symbolName)
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundStyle(vm.overallRank.gradient)
                        .glow(vm.overallRank.color, radius: 10)
                }

                VStack(spacing: 6) {
                    Text(vm.overallRank.rawValue.uppercased())
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundColor(vm.overallRank.color)
                        .tracking(4)

                    Text(String(format: "%.2f", vm.overallScore))
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, vm.overallRank.color.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .contentTransition(.numericText())

                    Text("Strength Score")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(.top, 32)

            // Progress bar
            VStack(spacing: 10) {
                HStack {
                    Text(vm.overallRank.rawValue)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(vm.overallRank.color)
                    Spacer()
                    Text(vm.overallRank.nextRank?.rawValue ?? "MAX")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(vm.overallRank.nextRank?.color ?? Color.white.opacity(0.25))
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(vm.overallRank.gradient)
                            .frame(width: geo.size.width * vm.overallProgress, height: 8)
                            .glow(vm.overallRank.color, radius: 4)
                    }
                }
                .frame(height: 8)

                Text("\(Int(vm.overallProgress * 100))% to \(vm.overallRank.nextRank?.rawValue ?? "MAX")")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.textTertiary)
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)
            .padding(.bottom, 28)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [vm.overallRank.color.opacity(0.08), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(
                    LinearGradient(
                        colors: [vm.overallRank.color.opacity(0.25), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
    }

    // MARK: - Log Button

    var logButton: some View {
        Button(action: onLogTap) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 42, height: 42)
                    Image(systemName: vm.todayLogged ? "pencil" : "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.todayLogged ? "Log Another Lift" : "Log Today's Lift")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text(vm.todayLogged ? "Keep the gains coming" : "Pick an exercise and go")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.55))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.45))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(LinearGradient.accent)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .glow(.accentOrange, radius: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Body Map

    var bodyMapSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(LinearGradient.accent)
                    .frame(width: 4, height: 18)
                Text("Muscle Map")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 20)

            BodyMapView(muscleRanks: vm.muscleRanks)
                .frame(height: 420)
        }
        .padding(.vertical, 20)
        .cardStyle(cornerRadius: 20)
    }

    // MARK: - Muscle Ranks List

    var muscleRanksList: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(LinearGradient.accent)
                    .frame(width: 4, height: 18)
                Text("Muscle Ranks")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }

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
            MiniStatCard(label: "Streak", value: "\(vm.streak)d", symbolName: "flame.fill", color: .accentOrange)
            MiniStatCard(label: "Lifts", value: "\(vm.totalLifts)", symbolName: "dumbbell.fill", color: Color(red: 0.45, green: 0.72, blue: 1.00))
        }
    }

    // MARK: - Recent Lifts

    var recentLiftsSection: some View {
        Group {
            if vm.recentLifts.isEmpty {
                EmptyView()
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(LinearGradient.accent)
                            .frame(width: 4, height: 18)
                        Text("Recent Lifts")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }

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
            // Rank icon with glow
            ZStack {
                Circle()
                    .fill(info.rank.color.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: info.rank.symbolName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(info.rank.gradient)
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(info.muscle.rawValue)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Text(info.rank.rawValue)
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(info.rank.color)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 5)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(info.rank.gradient)
                            .frame(width: geo.size.width * info.progress, height: 5)
                    }
                }
                .frame(height: 5)
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
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
                .glow(color, radius: 4)

            Text(value)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.textSecondary)
                .textCase(.uppercase)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
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
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.accentOrange)
                    }
                    Text(label)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
            }

            Spacer()

            Text("\(weight) lbs x \(reps)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
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
