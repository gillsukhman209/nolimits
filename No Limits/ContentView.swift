import SwiftUI
import Combine
import UIKit

enum AppPhase {
    case onboarding
    case paywall
    case locked
    case home
}

final class DesignPrototypeViewModel: ObservableObject {
    @Published var phase: AppPhase = .onboarding
    @Published var onboardingStep = 0

    @Published var selectedExperience: ExperienceLevel = .beginner
    @Published var selectedGoal: GoalType = .strength
    @Published var bodyWeight: Int = 170
    @Published var heightInches: Int = 70

    @Published var home = HomeSnapshot(
        rank: .silver,
        score: 0.96,
        nextRankProgress: 0.65,
        streakDays: 6,
        xp: 420,
        todaysLift: .bench,
        todaysWeight: 185,
        todaysReps: 5
    )

    @Published var selectedLift: LiftType = .bench
    @Published var loggedWeight: Int = 185
    @Published var loggedReps: Int = 5

    @Published var isLogPresented = false
    @Published var isSettingsPresented = false
    @Published var showRankUpCelebration = false
    @Published var showSaveFeedback = false

    @Published var remindersEnabled = true
    @Published var reminderTime: Date = {
        var components = DateComponents()
        components.hour = 19
        components.minute = 30
        return Calendar.current.date(from: components) ?? .now
    }()

    func goNextOnboardingStep() {
        HapticEngine.tap(.light)
        if onboardingStep < 2 {
            onboardingStep += 1
        } else {
            phase = .paywall
        }
    }

    func goBackOnboardingStep() {
        guard onboardingStep > 0 else { return }
        HapticEngine.tap(.light)
        onboardingStep -= 1
    }

    func unlockFromPaywall() {
        HapticEngine.notify(.success)
        phase = .home
    }

    func closePaywall() {
        HapticEngine.tap(.rigid)
        phase = .locked
    }

    func openPaywallFromLocked() {
        HapticEngine.tap(.medium)
        phase = .paywall
    }

    func presentLog() {
        loggedWeight = home.todaysWeight
        loggedReps = home.todaysReps
        selectedLift = home.todaysLift
        isLogPresented = true
    }

    func saveMockLift() {
        HapticEngine.notify(.success)
        home.todaysLift = selectedLift
        home.todaysWeight = loggedWeight
        home.todaysReps = loggedReps
        home.xp += 35
        home.streakDays += 1

        let previousScore = home.score
        home.score = min(1.62, home.score + 0.04)
        home.nextRankProgress = min(1.0, home.nextRankProgress + 0.15)

        if previousScore < 1.0, home.score >= 1.0 {
            home.rank = .gold
            showRankUpCelebration = true
        }

        isLogPresented = false
        showSaveFeedback = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) { [weak self] in
            self?.showSaveFeedback = false
        }
    }

    func previewRankUp() {
        HapticEngine.notify(.warning)
        home.rank = .gold
        showRankUpCelebration = true
    }
}

struct ContentView: View {
    @StateObject private var vm = DesignPrototypeViewModel()

    var body: some View {
        ZStack {
            LiftoffBackground()

            Group {
                switch vm.phase {
                case .onboarding:
                    OnboardingFlowView(vm: vm)
                case .paywall:
                    PaywallDesignView(vm: vm)
                case .locked:
                    LockedGateView(vm: vm)
                case .home:
                    HomeDesignView(vm: vm)
                }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
            .animation(.snappy, value: vm.phase)
        }
        .overlay(alignment: .top) {
            if vm.showSaveFeedback {
                SaveFeedbackBanner()
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $vm.isLogPresented) {
            LogLiftDesignView(vm: vm)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $vm.isSettingsPresented) {
            SettingsDesignView(vm: vm)
                .presentationDetents([.medium])
        }
        .fullScreenCover(isPresented: $vm.showRankUpCelebration) {
            RankUpCelebrationView(rank: vm.home.rank) {
                vm.showRankUpCelebration = false
            }
        }
    }
}

struct OnboardingFlowView: View {
    @ObservedObject var vm: DesignPrototypeViewModel

    var body: some View {
        VStack(spacing: 22) {
            VStack(spacing: 8) {
                Text("Liftoff")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("Set up in under 30 seconds")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))
            }

            StepProgressBar(currentStep: vm.onboardingStep, totalSteps: 3)

            Group {
                switch vm.onboardingStep {
                case 0:
                    SelectionStepCard(
                        title: "Your experience",
                        subtitle: "This helps us tune your starting vibe.",
                        selections: ExperienceLevel.allCases,
                        selectedValue: vm.selectedExperience
                    ) { item in
                        vm.selectedExperience = item
                    }
                case 1:
                    SelectionStepCard(
                        title: "Primary goal",
                        subtitle: "Choose what you care about most right now.",
                        selections: GoalType.allCases,
                        selectedValue: vm.selectedGoal
                    ) { item in
                        vm.selectedGoal = item
                    }
                default:
                    MetricsStepCard(bodyWeight: $vm.bodyWeight, heightInches: $vm.heightInches)
                }
            }
            .frame(maxHeight: 420)

            HStack(spacing: 12) {
                if vm.onboardingStep > 0 {
                    SecondaryButton(title: "Back", action: vm.goBackOnboardingStep)
                }

                PrimaryButton(
                    title: vm.onboardingStep == 2 ? "Continue" : "Next",
                    action: vm.goNextOnboardingStep
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
    }
}

struct PaywallDesignView: View {
    @ObservedObject var vm: DesignPrototypeViewModel

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 20)

            ZStack {
                Circle()
                    .fill(.white.opacity(0.12))
                    .frame(width: 120, height: 120)
                    .blur(radius: 4)
                Image(systemName: "flame.fill")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }

            VStack(spacing: 8) {
                Text("Unlock Liftoff")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("Track one lift a day. Build momentum.")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.74))
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 14) {
                    FeatureRow(text: "Fast daily lift logging")
                    FeatureRow(text: "Rank progression and streaks")
                    FeatureRow(text: "Simple reminders to stay consistent")
                }
            }

            HStack(spacing: 12) {
                PlanCard(title: "Monthly", subtitle: "$9.99 / month", badge: "Starter")
                PlanCard(title: "Yearly", subtitle: "$59.99 / year", badge: "Best Value", isHighlighted: true)
            }

            Spacer(minLength: 4)

            PrimaryButton(title: "Start Membership", action: vm.unlockFromPaywall)

            Button("Not now") {
                vm.closePaywall()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white.opacity(0.72))
            .padding(.top, 2)

            Text("Design prototype only. Purchase flow is mocked.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.55))
                .padding(.top, 4)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 28)
    }
}

struct LockedGateView: View {
    @ObservedObject var vm: DesignPrototypeViewModel

    var body: some View {
        ZStack {
            HomeDesignView(vm: vm)
                .blur(radius: 10)
                .allowsHitTesting(false)

            Rectangle()
                .fill(.black.opacity(0.5))
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(16)
                    .background(.white.opacity(0.15), in: Circle())

                Text("Unlock to start")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                Text("Your dashboard is ready. Activate access to begin logging.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.74))
                    .multilineTextAlignment(.center)

                PrimaryButton(title: "Open Paywall", action: vm.openPaywallFromLocked)
                    .padding(.top, 4)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.95))
            )
            .padding(24)
        }
    }
}

struct HomeDesignView: View {
    @ObservedObject var vm: DesignPrototypeViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Liftoff")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Today is a good day to lift.")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                    CircleIconButton(symbol: "gearshape.fill") {
                        vm.isSettingsPresented = true
                    }
                    .accessibilityLabel("Open settings")
                }

                RankCard(rank: vm.home.rank, score: vm.home.score, progress: vm.home.nextRankProgress)

                HStack(spacing: 12) {
                    StatPill(title: "Streak", value: "\(vm.home.streakDays) days", symbol: "flame.fill")
                    StatPill(title: "XP", value: "\(vm.home.xp)", symbol: "star.fill")
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Today's Preview")
                            .font(.headline)
                            .foregroundStyle(.white)
                        HStack {
                            Label(vm.home.todaysLift.rawValue, systemImage: vm.home.todaysLift.symbolName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.85))
                            Spacer()
                            Text("\(vm.home.todaysWeight) lb x \(vm.home.todaysReps)")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.white)
                        }
                    }
                }

                SecondaryButton(title: "Preview Rank-Up Animation", action: vm.previewRankUp)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 96)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(.white.opacity(0.08))
                    .frame(height: 1)

                PrimaryButton(title: "Log Today's Lift", action: vm.presentLog)
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 10)
            }
            .background(.ultraThinMaterial)
        }
    }
}

struct LogLiftDesignView: View {
    @ObservedObject var vm: DesignPrototypeViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Text("Quick daily log")
                    .font(.title2.weight(.bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(.white)

                GlassCard {
                    VStack(spacing: 14) {
                        Picker("Lift Type", selection: $vm.selectedLift) {
                            ForEach(LiftType.allCases) { lift in
                                Text(lift.rawValue).tag(lift)
                            }
                        }
                        .pickerStyle(.segmented)

                        HStack(spacing: 12) {
                            NumberPickerCard(title: "Weight", value: $vm.loggedWeight, range: 45...600, suffix: "lb")
                            NumberPickerCard(title: "Reps", value: $vm.loggedReps, range: 1...20, suffix: "reps")
                        }
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mock feedback")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("+35 XP  •  Streak +1 day")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer(minLength: 0)

                PrimaryButton(title: "Save Today's Lift") {
                    vm.saveMockLift()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 20)
            .background(LiftoffBackground())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct SettingsDesignView: View {
    @ObservedObject var vm: DesignPrototypeViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                GlassCard {
                    Toggle(isOn: $vm.remindersEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Daily reminders")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text("Get nudged if you haven't logged today")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.65))
                        }
                    }
                    .tint(.orange)
                }

                GlassCard {
                    DatePicker(
                        "Reminder time",
                        selection: $vm.reminderTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .background(LiftoffBackground())
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct RankUpCelebrationView: View {
    let rank: RankTier
    let onContinue: () -> Void

    @State private var pulse = false

    var body: some View {
        ZStack {
            LiftoffBackground()

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.22), lineWidth: 2)
                        .frame(width: 180, height: 180)
                        .scaleEffect(pulse ? 1.08 : 0.9)
                        .opacity(pulse ? 0.2 : 0.6)
                    Circle()
                        .fill(rank.gradient)
                        .frame(width: 144, height: 144)
                        .shadow(color: .orange.opacity(0.45), radius: 24)
                    Text(rank.rawValue)
                        .font(.title2.weight(.black))
                        .foregroundStyle(.white)
                }

                Text("Rank Up")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("You ranked up to \(rank.rawValue)")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))

                PrimaryButton(title: "Back to Home", action: onContinue)
                    .padding(.top, 4)
            }
            .padding(24)
        }
        .onAppear {
            HapticEngine.notify(.success)
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

struct StepProgressBar: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStep ? .white : .white.opacity(0.22))
                    .frame(height: 6)
            }
        }
    }
}

struct SelectionStepCard<Item: Identifiable & RawRepresentable>: View where Item.RawValue == String {
    let title: String
    let subtitle: String
    let selections: [Item]
    let selectedValue: Item
    let onSelect: (Item) -> Void

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))

                ForEach(selections) { item in
                    SelectableRow(
                        title: item.rawValue,
                        subtitle: subtitleFor(item),
                        isSelected: item.id == selectedValue.id
                    ) {
                        onSelect(item)
                        HapticEngine.tap(.soft)
                    }
                }
            }
        }
    }

    private func subtitleFor(_ item: Item) -> String {
        if let experience = item as? ExperienceLevel {
            return experience.subtitle
        }
        if let goal = item as? GoalType {
            return goal.subtitle
        }
        return ""
    }
}

struct MetricsStepCard: View {
    @Binding var bodyWeight: Int
    @Binding var heightInches: Int

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Body metrics")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Text("Used for your normalized rank design preview.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))

                HStack(spacing: 12) {
                    NumberPickerCard(title: "Bodyweight", value: $bodyWeight, range: 90...400, suffix: "lb")
                    NumberPickerCard(title: "Height", value: $heightInches, range: 54...84, suffix: "in")
                }
            }
        }
    }
}

struct RankCard: View {
    let rank: RankTier
    let score: Double
    let progress: Double

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Current Rank")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.8))
                    Spacer()
                    Text(rank.rawValue)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(rank.gradient, in: Capsule())
                }

                Text(String(format: "%.2f", score))
                    .font(.system(size: 52, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Progress to next rank")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.white.opacity(0.62))

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(.white.opacity(0.14))
                            Capsule()
                                .fill(rank.gradient)
                                .frame(width: geo.size.width * progress)
                        }
                    }
                    .frame(height: 10)
                }
            }
        }
    }
}

struct StatPill: View {
    let title: String
    let value: String
    let symbol: String

    var body: some View {
        GlassCard {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.headline)
                    .foregroundStyle(.orange)
                    .frame(width: 32, height: 32)
                    .background(.white.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.65))
                    Text(value)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                }
                Spacer()
            }
        }
    }
}

struct NumberPickerCard: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let suffix: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.65))

            HStack(spacing: 8) {
                Button {
                    value = max(range.lowerBound, value - 1)
                    HapticEngine.tap(.light)
                } label: {
                    Image(systemName: "minus")
                        .font(.caption.weight(.bold))
                        .frame(width: 28, height: 28)
                        .background(.white.opacity(0.12), in: Circle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)

                Text("\(value)")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(minWidth: 48)

                Button {
                    value = min(range.upperBound, value + 1)
                    HapticEngine.tap(.light)
                } label: {
                    Image(systemName: "plus")
                        .font(.caption.weight(.bold))
                        .frame(width: 28, height: 28)
                        .background(.white.opacity(0.12), in: Circle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
            }

            Text(suffix)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.52))
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.06))
        )
    }
}

struct SelectableRow: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.62))
                }
                Spacer()
                Circle()
                    .strokeBorder(.white.opacity(isSelected ? 1 : 0.4), lineWidth: 2)
                    .background(
                        Circle()
                            .fill(.orange)
                            .padding(5)
                            .opacity(isSelected ? 1 : 0)
                    )
                    .frame(width: 24, height: 24)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? .white.opacity(0.15) : .white.opacity(0.07))
            )
        }
        .buttonStyle(.plain)
    }
}

struct PlanCard: View {
    let title: String
    let subtitle: String
    let badge: String
    var isHighlighted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(badge)
                .font(.caption2.weight(.bold))
                .foregroundStyle(isHighlighted ? .black : .white.opacity(0.85))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isHighlighted ? .white : .white.opacity(0.16), in: Capsule())

            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(isHighlighted ? .orange.opacity(0.55) : .white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.white.opacity(isHighlighted ? 0.5 : 0.2), lineWidth: 1)
        )
    }
}

struct FeatureRow: View {
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(.orange)
                .font(.subheadline)
            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.9))
            Spacer()
        }
    }
}

struct SaveFeedbackBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("Lift saved. +35 XP")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule(style: .continuous)
                .fill(.black.opacity(0.6))
        )
    }
}

struct CircleIconButton: View {
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(.white.opacity(0.12), in: Circle())
        }
        .buttonStyle(.plain)
    }
}

struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(colors: [.white, Color(red: 1.0, green: 0.80, blue: 0.42)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.white.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(.white.opacity(0.18), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct GlassCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                    )
            )
    }
}

struct LiftoffBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.08, blue: 0.14),
                    Color(red: 0.12, green: 0.08, blue: 0.08),
                    Color(red: 0.03, green: 0.04, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.orange.opacity(0.2))
                .frame(width: 280)
                .blur(radius: 40)
                .offset(x: 140, y: -240)

            Circle()
                .fill(Color.blue.opacity(0.18))
                .frame(width: 240)
                .blur(radius: 44)
                .offset(x: -140, y: 250)
        }
    }
}

enum HapticEngine {
    static func tap(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}
