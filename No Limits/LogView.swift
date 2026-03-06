//
//  LogView.swift
//  No Limits
//
//  Created by Sukhman Singh on 3/5/26.
//

import SwiftUI
import SwiftData
import UIKit

struct LogView: View {
    let onDismiss: () -> Void
    let onRankUp: ((Rank, MuscleGroup) -> Void)?

    @Environment(\.modelContext) private var modelContext
    @State private var vm = LogViewModel()
    @State private var saveResult: SaveResult?
    @State private var showXPToast = false
    @State private var showExercisePicker = false

    init(onDismiss: @escaping () -> Void, onRankUp: ((Rank, MuscleGroup) -> Void)? = nil) {
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
                        exerciseSelector
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
        .sheet(isPresented: $showExercisePicker) {
            ExercisePickerSheet(selected: $vm.selectedExercise)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
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

    // MARK: - Exercise Selector

    var exerciseSelector: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("EXERCISE")

            Button(action: { showExercisePicker = true }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(vm.selectedExercise?.name ?? "Choose exercise")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        if let muscle = vm.selectedExercise?.muscleGroup {
                            Text(muscle.rawValue)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.accentOrange)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.textSecondary)
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 18)
                .cardStyle(cornerRadius: 16)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Weight / Reps

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
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Estimated 1RM")
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
                Text("\(Int(vm.currentE1RM)) lbs")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Targets")
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
                Text(vm.selectedExercise?.muscleGroup.rawValue ?? "")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.accentOrange)
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
                Text(result.isNewPR ? "New \(result.muscleGroup.rawValue) PR!" : "Lift Saved")
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
        .cardStyle(cornerRadius: 14)
        .padding(.horizontal, 24)
    }

    // MARK: - Save Logic

    func handleSave() {
        guard let result = vm.saveLift(context: modelContext) else { return }
        saveResult = result

        let impact = UIImpactFeedbackGenerator(style: result.isNewPR ? .heavy : .medium)
        impact.impactOccurred()

        withAnimation { showXPToast = true }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation { showXPToast = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if result.didRankUp {
                    onRankUp?(result.newRank, result.muscleGroup)
                } else {
                    onDismiss()
                }
            }
        }
    }

    func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.textSecondary)
            .tracking(2)
    }
}

// MARK: - Exercise Picker Sheet

struct ExercisePickerSheet: View {
    @Binding var selected: Exercise?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Choose Exercise")
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                    ForEach(ExerciseCatalog.grouped, id: \.0) { group, exercises in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(group.rawValue.uppercased())
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.accentOrange)
                                .tracking(2)
                                .padding(.horizontal, 24)

                            VStack(spacing: 4) {
                                ForEach(exercises) { exercise in
                                    Button(action: {
                                        selected = exercise
                                        dismiss()
                                    }) {
                                        HStack {
                                            Text(exercise.name)
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.white)
                                            Spacer()
                                            if selected?.name == exercise.name {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 18))
                                                    .foregroundStyle(LinearGradient.accent)
                                            }
                                        }
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 14)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    LogView(onDismiss: {})
        .modelContainer(for: [UserProfile.self, LiftEntry.self, AppStats.self], inMemory: true)
}
