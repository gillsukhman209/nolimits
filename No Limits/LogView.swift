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
    @State private var showSaveToast = false
    @State private var showExercisePicker = false

    init(onDismiss: @escaping () -> Void, onRankUp: ((Rank, MuscleGroup) -> Void)? = nil) {
        self.onDismiss = onDismiss
        self.onRankUp = onRankUp
    }

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Drag indicator
                Capsule()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)

                // Close & title
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.textSecondary)
                    }
                    Spacer()
                    Text("Log Lift")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 15, height: 15)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Exercise pill
                        exercisePill
                            .padding(.top, 32)
                            .padding(.horizontal, 24)

                        // Weight & reps — stacked vertically, large
                        inputArea
                            .padding(.top, 40)
                            .padding(.horizontal, 24)

                        // Score preview
                        if !vm.weight.isEmpty && !vm.reps.isEmpty {
                            scorePreview
                                .padding(.top, 32)
                                .padding(.horizontal, 24)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .padding(.bottom, 24)
                }
                .animation(.easeInOut(duration: 0.25), value: vm.weight.isEmpty || vm.reps.isEmpty)

                Spacer()

                // Save button
                saveButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
            }

            if showSaveToast, let result = saveResult {
                VStack {
                    Spacer()
                    saveToast(result: result)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 120)
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showSaveToast)
            }
        }
        .sheet(isPresented: $showExercisePicker) {
            ExercisePickerSheet(selected: $vm.selectedExercise)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Exercise Pill

    private var exercisePill: some View {
        Button(action: { showExercisePicker = true }) {
            HStack(spacing: 12) {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(Color.accentOrange.opacity(0.10))
                        .frame(width: 40, height: 40)
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.accentOrange)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.selectedExercise?.name ?? "Choose exercise")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    if let muscle = vm.selectedExercise?.muscleGroup {
                        Text(muscle.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.accentOrange)
                    } else {
                        Text("Tap to select")
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.textTertiary)
            }
            .padding(16)
            .background(Color.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Input Area

    private var inputArea: some View {
        VStack(spacing: 32) {
            // Weight — centered, large
            VStack(spacing: 6) {
                Text("WEIGHT")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.textSecondary)
                    .tracking(3)

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    TextField("0", text: $vm.weight)
                        .font(.system(size: 64, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                    Text("lbs")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.textTertiary)
                        .padding(.bottom, 8)
                }
                .frame(maxWidth: .infinity)
            }

            // Thin separator
            Rectangle()
                .fill(Color.white.opacity(0.04))
                .frame(height: 1)
                .padding(.horizontal, 40)

            // Reps — centered, large
            VStack(spacing: 6) {
                Text("REPS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.textSecondary)
                    .tracking(3)

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    TextField("0", text: $vm.reps)
                        .font(.system(size: 64, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                    Text("reps")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.textTertiary)
                        .padding(.bottom, 8)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Score Preview

    private var scorePreview: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("EST. 1RM")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.textSecondary)
                    .tracking(1)
                Text("\(Int(vm.currentE1RM)) lbs")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("TARGETS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.textSecondary)
                    .tracking(1)
                Text(vm.selectedExercise?.muscleGroup.rawValue ?? "")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.accentOrange)
            }
        }
        .padding(18)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.accentOrange.opacity(0.12), lineWidth: 1)
        )
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button(action: handleSave) {
            Group {
                if vm.saved {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                        Text("Saved!")
                            .font(.system(size: 17, weight: .semibold))
                    }
                } else {
                    Text("Save Lift")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .foregroundColor(vm.saved ? .white : (vm.canSave ? .black : .textSecondary))
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                vm.saved ? AnyShapeStyle(Color.green) :
                vm.canSave ? AnyShapeStyle(LinearGradient.accent) :
                AnyShapeStyle(Color.surfaceBg)
            )
            .clipShape(Capsule())
        }
        .disabled(!vm.canSave)
        .animation(.easeInOut(duration: 0.2), value: vm.saved)
    }

    // MARK: - Save Toast

    private func saveToast(result: SaveResult) -> some View {
        HStack(spacing: 10) {
            Image(systemName: result.isNewPR ? "trophy.fill" : "checkmark.circle.fill")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(result.isNewPR ? .accentOrange : .green)
            Text(result.isNewPR ? "New \(result.muscleGroup.rawValue) PR!" : "Lift Saved")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.cardBorder, lineWidth: 1)
        )
        .padding(.horizontal, 24)
    }

    // MARK: - Save Logic

    private func handleSave() {
        guard let result = vm.saveLift(context: modelContext) else { return }
        saveResult = result

        let impact = UIImpactFeedbackGenerator(style: result.isNewPR ? .heavy : .medium)
        impact.impactOccurred()

        withAnimation { showSaveToast = true }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation { showSaveToast = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if result.didRankUp {
                    onRankUp?(result.newRank, result.muscleGroup)
                } else {
                    onDismiss()
                }
            }
        }
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
                VStack(alignment: .leading, spacing: 28) {
                    Text("Choose Exercise")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                    ForEach(ExerciseCatalog.grouped, id: \.0) { group, exercises in
                        VStack(alignment: .leading, spacing: 0) {
                            Text(group.rawValue.uppercased())
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.accentOrange)
                                .tracking(2)
                                .padding(.horizontal, 24)
                                .padding(.bottom, 10)

                            ForEach(exercises) { exercise in
                                Button(action: {
                                    selected = exercise
                                    dismiss()
                                }) {
                                    HStack {
                                        Text(exercise.name)
                                            .font(.system(size: 16))
                                            .foregroundColor(.white)
                                        Spacer()
                                        if selected?.name == exercise.name {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 18))
                                                .foregroundColor(.accentOrange)
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 13)
                                    .background(
                                        selected?.name == exercise.name
                                        ? Color.accentOrange.opacity(0.06)
                                        : Color.clear
                                    )
                                }
                                .buttonStyle(.plain)
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
