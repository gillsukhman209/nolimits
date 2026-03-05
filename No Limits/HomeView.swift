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
    let onRankUp: (Rank) -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var vm = HomeViewModel()

    var body: some View {
        ZStack(alignment: .top) {
            Color.appBg.ignoresSafeArea()

            // Ambient glow behind rank badge
            Circle()
                .fill(vm.currentRank.color.opacity(0.12))
                .frame(width: 320, height: 320)
                .blur(radius: 60)
                .offset(y: 100)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    headerRow
                    rankCard
                    logButton
                    statsRow
                    recentLiftsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 64)
                .padding(.bottom, 48)
            }
        }
        .onAppear { vm.refresh(context: modelContext) }
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

    // MARK: - Rank Card

    var rankCard: some View {
        VStack(spacing: 0) {
            // Emblem
            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(vm.currentRank.color.opacity(0.12))
                        .frame(width: 108, height: 108)
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [vm.currentRank.color, vm.currentRank.color.opacity(0.25)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 108, height: 108)
                    Image(systemName: vm.currentRank.symbolName)
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundColor(vm.currentRank.color)
                }

                VStack(spacing: 4) {
                    Text(vm.currentRank.rawValue.uppercased())
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(vm.currentRank.color)
                        .tracking(3.5)

                    Text(String(format: "%.2f", vm.score))
                        .font(.system(size: 58, weight: .black, design: .rounded))
                        .foregroundColor(.white)

                    Text("Strength Score")
                        .font(.system(size: 13))
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(.top, 36)

            // Progress bar
            VStack(spacing: 10) {
                HStack {
                    Text(vm.currentRank.rawValue)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(vm.currentRank.color)
                    Spacer()
                    Text(vm.currentRank.nextRank?.rawValue ?? "MAX")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(vm.currentRank.nextRank?.color ?? Color.white.opacity(0.3))
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 10)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [vm.currentRank.color, vm.currentRank.nextRank?.color ?? vm.currentRank.color],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * vm.progress, height: 10)
                    }
                }
                .frame(height: 10)

                Text("\(Int(vm.progress * 100))% to \(vm.currentRank.nextRank?.rawValue ?? "MAX")")
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
                    Text(vm.todayLogged ? "Keep the gains coming" : "Bench, Squat, or Deadlift")
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

    // MARK: - Stats Row

    var statsRow: some View {
        HStack(spacing: 12) {
            MiniStatCard(label: "XP", value: "\(vm.xp)", symbolName: "star.fill", color: .accentOrange)
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
                                label: vm.relativeLabel(for: entry)
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

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(liftName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
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
    HomeView(onLogTap: {}, onRankUp: { _ in })
        .modelContainer(for: [UserProfile.self, LiftEntry.self, AppStats.self], inMemory: true)
}
