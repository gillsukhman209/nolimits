//
//  LogView.swift
//  No Limits
//
//  Created by Sukhman Singh on 3/5/26.
//

import SwiftUI

struct LogView: View {
    let onDismiss: () -> Void

    @State private var selectedLift = 0
    @State private var weight = ""
    @State private var reps = ""
    @State private var saved = false

    private let lifts = ["Bench", "Squat", "Deadlift"]

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            VStack(spacing: 0) {
                navBar
                    .padding(.top, 20)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        liftTypePicker
                        weightInput
                        repsInput

                        if !weight.isEmpty && !reps.isEmpty {
                            scorePreview
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 36)
                    .padding(.bottom, 24)
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: weight.isEmpty || reps.isEmpty)

                saveButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
            }
        }
    }

    // MARK: - Nav Bar

    var navBar: some View {
        HStack {
            Button(action: onDismiss) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 38, height: 38)
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.65))
                }
            }

            Spacer()

            Text("Log Lift")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)

            Spacer()

            Color.clear.frame(width: 38, height: 38)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Lift Type Picker

    var liftTypePicker: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("LIFT TYPE")

            HStack(spacing: 10) {
                ForEach(lifts.indices, id: \.self) { i in
                    LiftTypeChip(
                        title: lifts[i],
                        isSelected: selectedLift == i,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedLift = i
                            }
                        }
                    )
                }
            }
        }
    }

    // MARK: - Weight Input

    var weightInput: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("WEIGHT")

            HStack(alignment: .lastTextBaseline, spacing: 8) {
                TextField("0", text: $weight)
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .keyboardType(.numberPad)

                Text("lbs")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.35))
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 20)
            .cardStyle(cornerRadius: 16)
        }
    }

    // MARK: - Reps Input

    var repsInput: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("REPS")

            HStack(alignment: .lastTextBaseline, spacing: 8) {
                TextField("0", text: $reps)
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .keyboardType(.numberPad)

                Text("reps")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.35))
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 20)
            .cardStyle(cornerRadius: 16)
        }
    }

    // MARK: - Score Preview

    var scorePreview: some View {
        let w = Double(weight) ?? 0
        let r = Double(reps) ?? 0
        let e1rm = w * (1 + r / 30)

        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Estimated 1RM")
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
                Text("\(Int(e1rm)) lbs")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("XP Reward")
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
                Text("+10 XP")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(LinearGradient.accent)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.accentOrange.opacity(0.35), lineWidth: 1)
                )
        )
    }

    // MARK: - Save Button

    var saveButton: some View {
        Button(action: handleSave) {
            HStack(spacing: 10) {
                if saved {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                } else {
                    Text("Save Lift")
                        .font(.system(size: 17, weight: .semibold))
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 18))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Group {
                    if saved {
                        Color.green.opacity(0.75)
                    } else {
                        LinearGradient.accent.opacity(canSave ? 1 : 0.35)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(!canSave)
        .animation(.easeInOut(duration: 0.2), value: saved)
    }

    var canSave: Bool { !weight.isEmpty && !reps.isEmpty && !saved }

    func handleSave() {
        withAnimation { saved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { onDismiss() }
    }

    // MARK: - Helper

    func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.textSecondary)
            .tracking(2)
    }
}

// MARK: - Lift Type Chip

struct LiftTypeChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isSelected ? .white : Color.white.opacity(0.5))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient.accent
                        } else {
                            Color.cardBg
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(isSelected ? Color.clear : Color.cardBorder, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LogView(onDismiss: {})
}
