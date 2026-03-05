//
//  HomeView.swift
//  No Limits
//
//  Created by Sukhman Singh on 3/5/26.
//

import SwiftUI

struct HomeView: View {
    let onLogTap: () -> Void
    let onRankUp: (Rank) -> Void

    // Mock data for design prototype
    private let currentRank: Rank  = .gold
    private let score: Double      = 1.05
    private let progress: Double   = 0.72
    private let streak: Int        = 7
    private let xp: Int            = 340
    private let totalLifts: Int    = 24
    private let todayLogged: Bool  = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.appBg.ignoresSafeArea()

            // Ambient glow behind rank badge
            Circle()
                .fill(currentRank.color.opacity(0.12))
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
    }

    // MARK: - Header

    var headerRow: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                Text(todayLogged ? "Lift logged. Nice work." : "Time to lift.")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }

            Spacer()

            HStack(spacing: 5) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(LinearGradient.accent)
                Text("\(streak)")
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

    // MARK: - Rank Card

    var rankCard: some View {
        VStack(spacing: 0) {
            // Emblem
            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(currentRank.color.opacity(0.12))
                        .frame(width: 108, height: 108)
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [currentRank.color, currentRank.color.opacity(0.25)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 108, height: 108)
                    Image(systemName: currentRank.symbolName)
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundColor(currentRank.color)
                }

                VStack(spacing: 4) {
                    Text(currentRank.rawValue.uppercased())
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(currentRank.color)
                        .tracking(3.5)

                    Text(String(format: "%.2f", score))
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
                    Text(currentRank.rawValue)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(currentRank.color)
                    Spacer()
                    Text(currentRank.nextRank?.rawValue ?? "MAX")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(currentRank.nextRank?.color ?? Color.white.opacity(0.3))
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 10)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [currentRank.color, currentRank.nextRank?.color ?? currentRank.color],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * progress, height: 10)
                    }
                }
                .frame(height: 10)

                Text("\(Int(progress * 100))% to \(currentRank.nextRank?.rawValue ?? "MAX")")
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
                    Image(systemName: todayLogged ? "pencil" : "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(todayLogged ? "Edit Today's Lift" : "Log Today's Lift")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    Text(todayLogged ? "Tap to update your entry" : "Bench, Squat, or Deadlift")
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
            MiniStatCard(label: "XP", value: "\(xp)", symbolName: "star.fill", color: .accentOrange)
            MiniStatCard(label: "Streak", value: "\(streak)d", symbolName: "flame.fill", color: .red)
            MiniStatCard(label: "Lifts", value: "\(totalLifts)", symbolName: "dumbbell.fill", color: Color(red: 0.42, green: 0.76, blue: 1.00))
        }
    }

    // MARK: - Recent Lifts

    var recentLiftsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Lifts")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            VStack(spacing: 8) {
                LiftHistoryRow(liftName: "Bench Press", weight: 185, reps: 5, xpGained: 35, label: "Today")
                LiftHistoryRow(liftName: "Squat", weight: 225, reps: 3, xpGained: 10, label: "2d ago")
                LiftHistoryRow(liftName: "Deadlift", weight: 275, reps: 4, xpGained: 35, label: "4d ago")
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
    let xpGained: Int
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

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(weight) lbs x \(reps)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text("+\(xpGained) XP")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.accentOrange)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .cardStyle(cornerRadius: 14)
    }
}

#Preview {
    HomeView(onLogTap: {}, onRankUp: { _ in })
}
