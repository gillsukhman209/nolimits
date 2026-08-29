import SwiftUI
import SwiftData

struct ProfileDraft {
    let experience: String
    let goal: String
    let bodyweight: Double
    let height: Double
}

struct ExerciseDestination: Hashable {
    let name: String
    let muscleGroup: MuscleGroup
}

struct LogPresentation: Identifiable {
    let id = UUID()
    let exercise: Exercise?
    let side: ExerciseSide?

    init(exercise: Exercise?, side: ExerciseSide? = nil) {
        self.exercise = exercise
        self.side = side
    }
}

enum AppTab: String, CaseIterable, Identifiable {
    case today = "Today"
    case history = "History"
    case progress = "Progress"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .today: return "list.clipboard.fill"
        case .history: return "clock.fill"
        case .progress: return "chart.bar.fill"
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]
    @Query private var entries: [LiftEntry]
    @AppStorage("liftoff.remindersEnabled") private var remindersEnabled = false
    @AppStorage("liftoff.reminderTime") private var reminderTimestamp =
        Calendar.current.date(
            bySettingHour: 19,
            minute: 30,
            second: 0,
            of: .now
        )?.timeIntervalSince1970 ?? Date.now.timeIntervalSince1970
    @AppStorage("liftoff.appearance") private var appearanceRaw =
        AppearancePreference.system.rawValue

    var body: some View {
        Group {
            if shouldShowOnboarding {
                OnboardingView(onComplete: createProfile)
            } else {
                LiftoffShellView()
            }
        }
        .tint(.signalOrange)
        .preferredColorScheme(
            AppearancePreference(rawValue: appearanceRaw)?.colorScheme
        )
        .task { await refreshReminders() }
        .onChange(of: entries.count) {
            Task { await refreshReminders() }
        }
        .onChange(of: scenePhase) {
            guard scenePhase == .active else { return }
            Task { await refreshReminders() }
        }
    }

    private func createProfile(_ draft: ProfileDraft) {
        if let profile = profiles.first {
            profile.experience = draft.experience
            profile.goal = draft.goal
            profile.bodyweight = draft.bodyweight
            profile.height = draft.height
        } else {
            modelContext.insert(
                UserProfile(
                    experience: draft.experience,
                    goal: draft.goal,
                    bodyweight: draft.bodyweight,
                    height: draft.height
                )
            )
        }
        try? modelContext.save()
    }

    private func refreshReminders() async {
        await ReminderService.updateSchedule(
            isEnabled: remindersEnabled,
            reminderTime: Date(timeIntervalSince1970: reminderTimestamp),
            logDates: entries.map(\.date)
        )
    }

    private var shouldShowOnboarding: Bool {
        profiles.first == nil
    }
}

struct LiftoffShellView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: AppTab = .today
    @State private var path: [ExerciseDestination] = []
    @State private var showSettings = false
    @State private var loggerPresentation: LogPresentation?
    @State private var rankUpResult: SaveResult?

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color.paper.ignoresSafeArea()
                tabContent
            }
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                LiftoffTabBar(selection: $selectedTab)
            }
            .navigationDestination(for: ExerciseDestination.self) { destination in
                let exercise = ExerciseCatalog.exercise(
                    named: destination.name,
                    context: modelContext
                ) ?? Exercise(
                    name: destination.name,
                    muscleGroup: destination.muscleGroup
                )
                ExerciseDetailView(
                    exercise: exercise,
                    onLog: { side in
                        loggerPresentation = LogPresentation(
                            exercise: exercise,
                            side: side
                        )
                    }
                )
            }
        }
        .sheet(item: $loggerPresentation) { presentation in
            LogView(
                preselectedExercise: presentation.exercise,
                preselectedSide: presentation.side,
                onSaved: handleSaved
            )
        }
        .sheet(isPresented: $showSettings) {
            ProfileSettingsView()
        }
        .fullScreenCover(item: $rankUpResult) { result in
            RankUpView(
                rank: result.newRank,
                exerciseName: result.exerciseName,
                onContinue: {
                    rankUpResult = nil
                    path.removeAll()
                    selectedTab = .today
                }
            )
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .today:
            HomeView(
                onLogTap: {
                    loggerPresentation = LogPresentation(exercise: nil)
                },
                onSettingsTap: { showSettings = true },
                onExerciseTap: openExercise
            )
        case .history:
            HistoryView(
                onLogTap: {
                    loggerPresentation = LogPresentation(exercise: nil)
                },
                onExerciseTap: openExercise
            )
        case .progress:
            ProgressView(onExerciseTap: openExercise)
        }
    }

    private func openExercise(_ name: String, _ muscleGroup: MuscleGroup) {
        path.append(ExerciseDestination(name: name, muscleGroup: muscleGroup))
    }

    private func handleSaved(_ result: SaveResult) {
        if let current = path.last,
           current.name != result.exerciseName {
            path[path.count - 1] = ExerciseDestination(
                name: result.exerciseName,
                muscleGroup: result.muscleGroup
            )
        }
        loggerPresentation = nil
        guard result.didRankUp else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            rankUpResult = result
        }
    }
}

struct LiftoffTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        selection = tab
                    }
                } label: {
                    VStack(spacing: 7) {
                        Capsule()
                            .fill(selection == tab ? Color.signalOrange : Color.clear)
                            .frame(width: 38, height: 4)

                        Image(systemName: tab.iconName)
                            .font(.system(size: 20, weight: .bold))

                        Text(tab.rawValue)
                            .displayLabel(size: 14)
                    }
                    .foregroundStyle(selection == tab ? Color.ink : Color.inkMuted)
                    .frame(maxWidth: .infinity)
                    .frame(height: 72)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.rawValue)
                .accessibilityAddTraits(selection == tab ? .isSelected : [])
            }
        }
        .padding(.horizontal, 8)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.hairline)
                .frame(height: 1)
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [UserProfile.self, LiftEntry.self, AppStats.self, CustomExercise.self], inMemory: true)
}
