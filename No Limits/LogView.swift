//
//  LogView.swift
//  No Limits
//
//  Created by Sukhman Singh on 3/5/26.
//

import SwiftUI
import SwiftData

struct LogView: View {
    let onDismiss: () -> Void
    let onRankUp: ((Rank) -> Void)?

    @Environment(\.modelContext) private var modelContext
    @State private var vm = LogViewModel()
    @State private var saveResult: SaveResult?
    @State private var showXPToast = false

    init(onDismiss: @escaping () -> Void, onRankUp: ((Rank) -> Void)? = nil) {
        self.onDismiss = onDismiss
        self.onRankUp = onRankUp
    }

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

                        if !vm.weight.isEmpty && !vm.reps.isEmpty {
                            scorePreview
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 36)
                    .padding(.bottom, 24)
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: vm.weight.isEmpty || vm.reps.isEmpty)

                saveButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
            }

            // XP toast overlay
            if showXPToast, let result = saveResult {
                VStack {
                    Spacer()
                    xpToast(result: result)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 120)
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: showXPToast)
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
                ForEach(vm.liftOptions.indices, id: \.self) { i in
                    LiftTypeChip(
                        title: vm.liftOptions[i],
                        isSelected: vm.selectedLiftIndex == i,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                vm.selectedLiftIndex = i
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
                TextField("0", text: $vm.weight)
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
                TextField("0", text: $vm.reps)
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
        let e1rm = vm.currentE1RM

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
                if vm.saved {
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
                    if vm.saved {
                        Color.green.opacity(0.75)
                    } else {
                        LinearGradient.accent.opacity(vm.canSave ? 1 : 0.35)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(!vm.canSave)
        .animation(.easeInOut(duration: 0.2), value: vm.saved)
    }

    // MARK: - XP Toast

    func xpToast(result: SaveResult) -> some View {
        HStack(spacing: 12) {
            Image(systemName: result.isNewPR ? "trophy.fill" : "star.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(LinearGradient.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text(result.isNewPR ? "New PR!" : "Lift Saved")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                Text("+\(result.xpEarned) XP")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.accentOrange)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.cardBg)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.accentOrange.opacity(0.4), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 24)
    }

    // MARK: - Save Logic

    func handleSave() {
        guard let result = vm.saveLift(context: modelContext) else { return }
        saveResult = result

        // Show toast briefly, then dismiss
        withAnimation { showXPToast = true }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation { showXPToast = false }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if result.didRankUp {
                    onRankUp?(result.newRank)
                } else {
                    onDismiss()
                }
            }
        }
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
        .modelContainer(for: [UserProfile.self, LiftEntry.self, AppStats.self], inMemory: true)
}
