//
//  OnboardingView.swift
//  No Limits
//
//  Created by Sukhman Singh on 3/5/26.
//

import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var step = 0
    @State private var selectedExperience: String? = nil
    @State private var selectedGoal: String? = nil
    @State private var weight = ""
    @State private var height = ""

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            VStack(spacing: 0) {
                if step > 0 {
                    progressDots
                        .padding(.top, 64)
                        .padding(.bottom, 8)
                }

                Spacer()

                Group {
                    switch step {
                    case 0: welcomeStep
                    case 1: experienceStep
                    case 2: goalStep
                    case 3: bodyStatsStep
                    default: EmptyView()
                    }
                }
                .id(step)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                Spacer()

                if step > 0 {
                    continueButton
                        .padding(.horizontal, 24)
                        .padding(.bottom, 48)
                }
            }
        }
    }

    // MARK: - Progress Dots

    var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(1..<4, id: \.self) { i in
                Capsule()
                    .fill(i <= step ? Color.accentOrange : Color.white.opacity(0.15))
                    .frame(width: i == step ? 28 : 8, height: 8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: step)
            }
        }
    }

    // MARK: - Continue Button

    var continueButton: some View {
        Button(action: advance) {
            HStack(spacing: 8) {
                Text(step == 3 ? "Get Started" : "Continue")
                    .font(.system(size: 17, weight: .semibold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient.accent
                    .opacity(canAdvance ? 1 : 0.35)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(!canAdvance)
    }

    var canAdvance: Bool {
        switch step {
        case 1: return selectedExperience != nil
        case 2: return selectedGoal != nil
        case 3: return !weight.isEmpty && !height.isEmpty
        default: return true
        }
    }

    func advance() {
        if step < 3 {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { step += 1 }
        } else {
            onComplete()
        }
    }

    // MARK: - Step 0: Welcome

    var welcomeStep: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.accentOrange.opacity(0.25), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "bolt.fill")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(LinearGradient.accent)
            }

            VStack(spacing: 12) {
                Text("Liftoff")
                    .font(.system(size: 52, weight: .black))
                    .foregroundColor(.white)

                Text("Track your lifts.\nEarn your rank.")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
            }

            Button(action: {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { step = 1 }
            }) {
                HStack(spacing: 8) {
                    Text("Get Started")
                        .font(.system(size: 17, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(LinearGradient.accent)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Step 1: Experience

    var experienceStep: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Experience")
                    .font(.system(size: 34, weight: .black))
                    .foregroundColor(.white)
                Text("How long have you been lifting?")
                    .font(.system(size: 16))
                    .foregroundColor(.textSecondary)
            }
            .padding(.horizontal, 32)

            VStack(spacing: 12) {
                OnboardingOptionCard(
                    title: "Beginner",
                    subtitle: "Under 1 year",
                    symbolName: "figure.walk",
                    isSelected: selectedExperience == "Beginner"
                ) { selectedExperience = "Beginner" }

                OnboardingOptionCard(
                    title: "Intermediate",
                    subtitle: "1 to 3 years",
                    symbolName: "figure.run",
                    isSelected: selectedExperience == "Intermediate"
                ) { selectedExperience = "Intermediate" }

                OnboardingOptionCard(
                    title: "Advanced",
                    subtitle: "3+ years",
                    symbolName: "bolt.fill",
                    isSelected: selectedExperience == "Advanced"
                ) { selectedExperience = "Advanced" }
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Step 2: Goal

    var goalStep: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Goal")
                    .font(.system(size: 34, weight: .black))
                    .foregroundColor(.white)
                Text("What are you training for?")
                    .font(.system(size: 16))
                    .foregroundColor(.textSecondary)
            }
            .padding(.horizontal, 32)

            VStack(spacing: 12) {
                OnboardingOptionCard(
                    title: "Strength",
                    subtitle: "Lift heavier, get stronger",
                    symbolName: "dumbbell.fill",
                    isSelected: selectedGoal == "Strength"
                ) { selectedGoal = "Strength" }

                OnboardingOptionCard(
                    title: "Muscle",
                    subtitle: "Build size and definition",
                    symbolName: "figure.strengthtraining.traditional",
                    isSelected: selectedGoal == "Muscle"
                ) { selectedGoal = "Muscle" }

                OnboardingOptionCard(
                    title: "Fat Loss",
                    subtitle: "Burn fat, stay strong",
                    symbolName: "flame.fill",
                    isSelected: selectedGoal == "Fat Loss"
                ) { selectedGoal = "Fat Loss" }
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Step 3: Body Stats

    var bodyStatsStep: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 8) {
                Text("About You")
                    .font(.system(size: 34, weight: .black))
                    .foregroundColor(.white)
                Text("Used to calculate your strength score.")
                    .font(.system(size: 16))
                    .foregroundColor(.textSecondary)
            }
            .padding(.horizontal, 32)

            VStack(spacing: 16) {
                StatsInputField(label: "Bodyweight", placeholder: "175", unit: "lbs", value: $weight)
                StatsInputField(label: "Height", placeholder: "70", unit: "inches", value: $height)
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Onboarding Option Card

struct OnboardingOptionCard: View {
    let title: String
    let subtitle: String
    let symbolName: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.accentOrange.opacity(0.18) : Color.white.opacity(0.07))
                        .frame(width: 50, height: 50)

                    Image(systemName: symbolName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(
                            isSelected
                                ? LinearGradient.accent
                                : LinearGradient(colors: [Color.white.opacity(0.45), Color.white.opacity(0.45)], startPoint: .top, endPoint: .bottom)
                        )
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(
                        isSelected
                            ? LinearGradient.accent
                            : LinearGradient(colors: [Color.white.opacity(0.25), Color.white.opacity(0.25)], startPoint: .top, endPoint: .bottom)
                    )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                isSelected ? Color.accentOrange.opacity(0.55) : Color.cardBorder,
                                lineWidth: 1.5
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Stats Input Field

struct StatsInputField: View {
    let label: String
    let placeholder: String
    let unit: String
    @Binding var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.textSecondary)
                .tracking(1.5)

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                TextField(placeholder, text: $value)
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .keyboardType(.decimalPad)

                Text(unit)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.35))
                    .padding(.bottom, 4)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .cardStyle(cornerRadius: 14)
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
