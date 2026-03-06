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
    @State private var selectedTab: HomeTab = .muscles

    enum HomeTab: String, CaseIterable {
        case muscles = "Muscles"
        case activity = "Activity"
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.appBg.ignoresSafeArea()

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
                // Pulsing rings
                Circle()
                    .stroke(Color.accentOrange.opacity(0.06), lineWidth: 1)
                    .frame(width: 200, height: 200)
                Circle()
                    .stroke(Color.accentOrange.opacity(0.10), lineWidth: 1)
                    .frame(width: 150, height: 150)
                Circle()
                    .fill(Color.accentOrange.opacity(0.05))
                    .frame(width: 100, height: 100)
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(LinearGradient.accent)
            }

            Spacer().frame(height: 40)

            Text("Start Your Journey")
                .font(.system(size: 28, weight: .bold))
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
                .foregroundColor(.black)
                .frame(width: 200, height: 52)
                .background(LinearGradient.accent)
                .clipShape(Capsule())
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
                topBar
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                // Ring hero section
                ringHero
                    .padding(.top, 16)

                // Stats strip
                statsStrip
                    .padding(.top, 24)
                    .padding(.horizontal, 24)

                // Tab switcher
                tabSwitcher
                    .padding(.top, 28)
                    .padding(.horizontal, 24)

                // Tab content
                tabContent
                    .padding(.top, 16)

                Spacer().frame(height: 100)
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
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }

            Spacer()

            if vm.streak > 0 {
                HStack(spacing: 5) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.accentOrange)
                    Text("\(vm.streak)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.accentOrange.opacity(0.10))
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(Color.accentOrange.opacity(0.15), lineWidth: 1))
            }
        }
    }

    // MARK: - Ring Hero

    private var ringHero: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Color.white.opacity(0.04), lineWidth: 14)
                .frame(width: 220, height: 220)

            // Progress arc
            Circle()
                .trim(from: 0, to: vm.overallProgress)
                .stroke(
                    AngularGradient(
                        colors: [vm.overallRank.color.opacity(0.5), vm.overallRank.color],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * vm.overallProgress)
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .frame(width: 220, height: 220)
                .rotationEffect(.degrees(-90))

            // Glow dot at end of arc
            Circle()
                .fill(vm.overallRank.color)
                .frame(width: 18, height: 18)
                .shadow(color: vm.overallRank.color.opacity(0.6), radius: 8)
                .offset(y: -110)
                .rotationEffect(.degrees(360 * vm.overallProgress))

            // Center content
            VStack(spacing: 6) {
                Text(String(format: "%.2f", vm.overallScore))
                    .font(.system(size: 52, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                HStack(spacing: 6) {
                    Image(systemName: vm.overallRank.symbolName)
                        .font(.system(size: 11, weight: .semibold))
                    Text(vm.overallRank.rawValue.uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .tracking(2)
                }
                .foregroundColor(vm.overallRank.color)
            }
        }
        .frame(height: 260)
    }

    // MARK: - Stats Strip

    private var statsStrip: some View {
        HStack(spacing: 0) {
            statItem(value: "\(vm.totalLifts)", label: "LIFTS")
            Divider()
                .frame(height: 28)
                .background(Color.white.opacity(0.08))
            statItem(value: "\(vm.streak)", label: "STREAK")
            Divider()
                .frame(height: 28)
                .background(Color.white.opacity(0.08))
            statItem(value: "\(Int(vm.overallProgress * 100))%", label: "TO NEXT")
        }
        .padding(.vertical, 16)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.cardBorder, lineWidth: 1)
        )
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.textSecondary)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Tab Switcher

    private var tabSwitcher: some View {
        HStack(spacing: 4) {
            ForEach(HomeTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab }
                }) {
                    Text(tab.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(selectedTab == tab ? .white : .textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedTab == tab
                                ? Color.surfaceBg
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .muscles:
            musclesTab
        case .activity:
            activityTab
        }
    }

    // MARK: - Muscles Tab

    private var musclesTab: some View {
        VStack(spacing: 16) {
            // Body map — full width, no card wrapper
            BodyMapView(muscleRanks: vm.muscleRanks)
                .frame(height: 380)
                .padding(.horizontal, 24)

            // Horizontal scrolling muscle chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(vm.muscleRankList) { info in
                        muscleChip(info: info)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private func muscleChip(info: MuscleRankInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Circle()
                    .fill(info.rank.color)
                    .frame(width: 8, height: 8)
                Text(info.muscle.rawValue)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
            }

            Text(info.rank.rawValue)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(info.rank.color)
                .tracking(0.5)

            // Thin progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.06))
                    Capsule()
                        .fill(info.rank.color)
                        .frame(width: max(geo.size.width * info.progress, 4))
                }
            }
            .frame(height: 3)
        }
        .frame(width: 120)
        .padding(14)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(info.rank.color.opacity(0.12), lineWidth: 1)
        )
    }

    // MARK: - Activity Tab

    private var activityTab: some View {
        VStack(spacing: 8) {
            if vm.recentLifts.isEmpty {
                Text("No lifts yet")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                ForEach(vm.recentLifts, id: \.id) { entry in
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
        .padding(.horizontal, 24)
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
            .foregroundColor(.black)
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
            .background(LinearGradient.accent)
            .clipShape(Capsule())
            .shadow(color: Color.accentOrange.opacity(0.3), radius: 16, y: 4)
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
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(color.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Mini Stat Card (kept for compatibility)

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
        HStack {
            // Colored side indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(muscleGroup.map { _ in Color.accentOrange } ?? Color.textSecondary)
                .frame(width: 3, height: 36)

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
            .padding(.leading, 8)

            Spacer()

            Text("\(weight) x \(reps)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.cardBorder, lineWidth: 1)
        )
    }
}

// MARK: - Muscle Rank Tile (kept for compatibility)

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

// MARK: - Muscle Rank Row (kept for compatibility)

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
