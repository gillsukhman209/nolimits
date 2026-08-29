import SwiftUI
import SwiftData
import UIKit

struct LogView: View {
    enum Field {
        case weight
        case reps
    }

    let onSaved: (SaveResult) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LiftEntry.date, order: .reverse) private var entries: [LiftEntry]
    @Query private var profiles: [UserProfile]
    @State private var vm: LogViewModel
    @State private var showExercisePicker = false
    @FocusState private var focusedField: Field?

    init(
        preselectedExercise: Exercise? = nil,
        preselectedSide: ExerciseSide? = nil,
        onSaved: @escaping (SaveResult) -> Void
    ) {
        self.onSaved = onSaved
        _vm = State(
            initialValue: LogViewModel(
                selectedExercise: preselectedExercise,
                selectedSide: preselectedSide
            )
        )
    }

    private var exerciseEntries: [LiftEntry] {
        guard let exercise = vm.selectedExercise else { return [] }
        return entries.filter {
            guard $0.liftType == exercise.name else { return false }
            if exercise.sideTracking == .separate {
                return $0.side == vm.selectedSide
            }
            return true
        }
    }

    private var latestExerciseEntry: LiftEntry? { exerciseEntries.first }
    private var bestExerciseEntry: LiftEntry? {
        exerciseEntries.max(by: { $0.e1RM < $1.e1RM })
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    exerciseSelector

                    if vm.selectedExercise?.sideTracking == .separate {
                        sideSelector
                    }

                    if vm.selectedExercise?.loadType == .assistance {
                        assistanceGuidance
                    }

                    if let latestExerciseEntry {
                        previousPerformance(latestExerciseEntry)
                    }

                    inputSection

                    if vm.currentE1RM > 0 {
                        estimateCard
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 120)
            }
            .background(Color.paper)
            .safeAreaInset(edge: .bottom) {
                saveButton
            }
            .toolbar(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
            }
        }
        .presentationCornerRadius(30)
        .sheet(isPresented: $showExercisePicker) {
            ExercisePickerSheet(selected: $vm.selectedExercise)
        }
        .onAppear {
            vm.bodyweight = profiles.first?.bodyweight ?? 0
            prefillLatestSet(replacingCurrentValues: false)
        }
        .onChange(of: vm.selectedExercise?.name) {
            configureSideForSelectedExercise()
            prefillLatestSet(replacingCurrentValues: true)
        }
        .onChange(of: vm.selectedSide) {
            prefillLatestSet(replacingCurrentValues: true)
        }
        .onChange(of: profiles.first?.bodyweight) {
            vm.bodyweight = profiles.first?.bodyweight ?? 0
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("NEW LIFT")
                    .sectionEyebrow()
                Text("Make it count.")
                    .font(.system(size: 34, weight: .black))
                    .fontWidth(.compressed)
                    .foregroundStyle(Color.ink)
            }

            Spacer()

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.ink)
                    .frame(width: 42, height: 42)
                    .background(Color.hairline.opacity(0.38), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
    }

    private var exerciseSelector: some View {
        Button { showExercisePicker = true } label: {
            HStack(spacing: 14) {
                if let muscleGroup = vm.selectedExercise?.muscleGroup {
                    ExerciseIcon(muscleGroup: muscleGroup, size: 52, inverted: true)
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: 19, weight: .black))
                        .foregroundStyle(Color.paper)
                        .frame(width: 52, height: 52)
                        .background(Color.ink, in: Circle())
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(vm.selectedExercise?.name ?? "Choose exercise")
                        .font(.system(size: 20, weight: .black))
                        .fontWidth(.condensed)
                        .foregroundStyle(Color.ink)

                    Text(vm.selectedExercise.map {
                        if ExerciseCatalog.isRanked($0.name) {
                            return "\($0.muscleGroup.rawValue) · Ranked lift"
                        }
                        if $0.loadType == .assistance {
                            return "\($0.muscleGroup.rawValue) · Lower is harder"
                        }
                        if $0.sideTracking == .separate {
                            return "\($0.muscleGroup.rawValue) · Track each side"
                        }
                        return $0.muscleGroup.rawValue
                    } ?? "Search or pick a recent exercise")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.inkMuted)
                }

                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(Color.ink)
            }
            .padding(16)
            .cardStyle(cornerRadius: 18)
        }
        .buttonStyle(.plain)
    }

    private var sideSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SIDE")
                .sectionEyebrow()

            HStack(spacing: 8) {
                ForEach([ExerciseSide.left, .right]) { side in
                    Button {
                        withAnimation(.easeOut(duration: 0.18)) {
                            vm.selectedSide = side
                        }
                    } label: {
                        Text(side.rawValue.uppercased())
                            .font(.system(size: 15, weight: .black))
                            .fontWidth(.condensed)
                            .foregroundStyle(
                                vm.selectedSide == side ? Color.paper : Color.ink
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(
                                vm.selectedSide == side
                                    ? Color.ink
                                    : Color.hairline.opacity(0.32),
                                in: RoundedRectangle(cornerRadius: 13)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(
                        vm.selectedSide == side ? .isSelected : []
                    )
                }
            }
        }
    }

    private var assistanceGuidance: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: "arrow.down")
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(Color.signalOrange)
                .frame(width: 28, height: 28)
                .background(Color.signalOrange.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text("LOWER ASSISTANCE IS HARDER")
                    .font(.system(size: 12, weight: .black))
                    .fontWidth(.condensed)
                    .tracking(0.7)
                    .foregroundStyle(Color.ink)
                Text("Your score uses bodyweight minus assistance, then adjusts for reps.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.inkMuted)
            }
        }
        .padding(14)
        .background(Color.signalOrange.opacity(0.08), in: RoundedRectangle(cornerRadius: 15))
    }

    private func previousPerformance(_ entry: LiftEntry) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("LAST TIME")
                    .sectionEyebrow()
                Text("\(entry.weight.formattedWeight) lb × \(entry.reps)")
                    .font(.system(size: 17, weight: .bold))
                    .fontWidth(.condensed)
                    .foregroundStyle(Color.ink)
            }
            Spacer()
            if let bestExerciseEntry {
                VStack(alignment: .trailing, spacing: 3) {
                    Text(
                        vm.selectedExercise?.loadType == .assistance
                            ? "BEST EFFECTIVE MAX"
                            : "BEST E1RM"
                    )
                        .sectionEyebrow()
                    Text("\(bestExerciseEntry.e1RM.formattedWeight) lb")
                        .font(.system(size: 17, weight: .bold))
                        .fontWidth(.condensed)
                        .foregroundStyle(Color.ink)
                }
            }
        }
        .padding(.horizontal, 2)
    }

    private var inputSection: some View {
        HStack(spacing: 12) {
            numberInput(
                title: vm.selectedExercise?.loadType.inputLabel ?? "WEIGHT",
                value: $vm.weight,
                unit: "LB",
                field: .weight,
                decrement: { vm.adjustWeight(by: -5) },
                increment: { vm.adjustWeight(by: 5) }
            )

            numberInput(
                title: "REPS",
                value: $vm.reps,
                unit: "REPS",
                field: .reps,
                decrement: { vm.adjustReps(by: -1) },
                increment: { vm.adjustReps(by: 1) }
            )
        }
    }

    private func numberInput(
        title: String,
        value: Binding<String>,
        unit: String,
        field: Field,
        decrement: @escaping () -> Void,
        increment: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 12) {
            Text(title)
                .sectionEyebrow()

            TextField("0", text: value)
                .font(.system(size: 44, weight: .black))
                .fontWidth(.compressed)
                .foregroundStyle(Color.ink)
                .multilineTextAlignment(.center)
                .keyboardType(field == .weight ? .decimalPad : .numberPad)
                .focused($focusedField, equals: field)
                .minimumScaleFactor(0.65)

            Text(unit)
                .font(.system(size: 11, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(Color.inkMuted)

            HStack(spacing: 8) {
                stepButton(icon: "minus", action: decrement)
                stepButton(icon: "plus", action: increment)
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .cardStyle(cornerRadius: 18)
    }

    private func stepButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(Color.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(Color.hairline.opacity(0.35), in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private var estimateCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(
                    vm.selectedExercise?.loadType.metricLabel
                        ?? "ESTIMATED 1 REP MAX"
                )
                    .sectionEyebrow()
                Text("\(vm.currentE1RM.formattedWeight) lb")
                    .font(.system(size: 28, weight: .black))
                    .fontWidth(.compressed)
                    .foregroundStyle(Color.ink)
            }

            Spacer()

            if let bestExerciseEntry {
                let difference = vm.currentE1RM - bestExerciseEntry.e1RM
                Text(difference > 0 ? "+\(difference.formattedWeight) PR" : "PB \(bestExerciseEntry.e1RM.formattedWeight)")
                    .font(.system(size: 12, weight: .black))
                    .fontWidth(.condensed)
                    .foregroundStyle(difference > 0 ? Color.white : Color.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(difference > 0 ? Color.signalOrange : Color.hairline.opacity(0.45), in: Capsule())
            }
        }
        .padding(18)
        .cardStyle(cornerRadius: 18)
    }

    private var saveButton: some View {
        Button(action: save) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .black))
                Text("SAVE LIFT")
                    .font(.system(size: 20, weight: .black))
                    .fontWidth(.compressed)
                    .tracking(0.7)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 62)
            .opacity(vm.canSave ? 1 : 0.45)
        }
        .buttonStyle(OrangeButtonStyle())
        .disabled(!vm.canSave)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    private func save() {
        focusedField = nil
        guard let result = vm.saveLift(context: modelContext) else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onSaved(result)
    }

    private func prefillLatestSet(replacingCurrentValues: Bool) {
        guard let latest = exerciseEntries.first else {
            if replacingCurrentValues {
                vm.weight = ""
                vm.reps = ""
            }
            return
        }
        if replacingCurrentValues || vm.weight.isEmpty {
            vm.weight = latest.weight.formattedWeight
        }
        if replacingCurrentValues || vm.reps.isEmpty {
            vm.reps = String(latest.reps)
        }
    }

    private func configureSideForSelectedExercise() {
        guard let exercise = vm.selectedExercise else {
            vm.selectedSide = .both
            return
        }
        vm.selectedSide = exercise.sideTracking == .separate ? .left : .both
    }
}

struct ExercisePickerSheet: View {
    @Binding var selected: Exercise?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LiftEntry.date, order: .reverse) private var entries: [LiftEntry]
    @State private var searchText = ""
    @State private var showAddExercise = false

    private var allExercises: [Exercise] {
        ExerciseCatalog.allExercises(context: modelContext)
    }

    private var filteredExercises: [Exercise] {
        guard !searchText.isEmpty else { return allExercises }
        return allExercises.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.muscleGroup.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var recentExercises: [Exercise] {
        var names = Set<String>()
        return entries.compactMap { entry in
            guard names.insert(entry.liftType).inserted else { return nil }
            if let exercise = ExerciseCatalog.exercise(
                named: entry.liftType,
                context: modelContext
            ) {
                return exercise
            }
            let muscle = entry.muscleGroup
                ?? ExerciseCatalog.muscleGroup(for: entry.liftType)
                ?? .legs
            return Exercise(
                name: entry.liftType,
                muscleGroup: muscle,
                loadType: entry.loadType,
                sideTracking: entry.side == .both ? .combined : .separate
            )
        }
        .prefix(4)
        .map { $0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 10) {
                    Button {
                        showAddExercise = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "plus")
                                .font(.system(size: 15, weight: .black))
                                .foregroundStyle(Color.paper)
                                .frame(width: 36, height: 36)
                                .background(Color.ink, in: Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text("CREATE CUSTOM EXERCISE")
                                    .font(.system(size: 14, weight: .black))
                                    .fontWidth(.condensed)
                                    .tracking(0.6)
                                    .foregroundStyle(Color.ink)
                                Text("Choose resistance and side tracking")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color.inkMuted)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(Color.signalOrange)
                        }
                        .padding(13)
                        .background(
                            Color.signalOrange.opacity(0.10),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 8)

                    if searchText.isEmpty, !recentExercises.isEmpty {
                        Text("RECENT")
                            .sectionEyebrow()
                            .padding(.top, 6)
                        ForEach(recentExercises) { exerciseRow($0) }

                        Text("ALL EXERCISES")
                            .sectionEyebrow()
                            .padding(.top, 18)
                    }

                    ForEach(filteredExercises) { exerciseRow($0) }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(Color.paper)
            .searchable(text: $searchText, prompt: "Exercise or muscle")
            .navigationTitle("Choose Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.ink)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddExercise = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.bold)
                    }
                    .accessibilityLabel("Add custom exercise")
                }
            }
        }
        .presentationDetents([.large])
        .presentationCornerRadius(30)
        .sheet(isPresented: $showAddExercise) {
            AddExerciseSheet { exercise in
                selected = exercise
                dismiss()
            }
        }
    }

    private func exerciseRow(_ exercise: Exercise) -> some View {
        Button {
            selected = exercise
            dismiss()
        } label: {
            HStack(spacing: 13) {
                ExerciseIcon(muscleGroup: exercise.muscleGroup, size: 44)
                VStack(alignment: .leading, spacing: 3) {
                    Text(exercise.name)
                        .font(.system(size: 17, weight: .bold))
                        .fontWidth(.condensed)
                        .foregroundStyle(Color.ink)
                    Text(exercise.muscleGroup.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.inkMuted)
                }
                Spacer()
                HStack(spacing: 5) {
                    if exercise.loadType == .assistance {
                        exerciseBadge("ASSISTED")
                    }
                    if exercise.sideTracking == .separate {
                        exerciseBadge("L/R")
                    }
                    if ExerciseCatalog.isRanked(exercise.name) {
                        exerciseBadge("RANKED")
                    }
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.inkFaint)
            }
            .padding(13)
            .cardStyle(cornerRadius: 16)
        }
        .buttonStyle(.plain)
    }

    private func exerciseBadge(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 9, weight: .black))
            .tracking(0.8)
            .foregroundStyle(Color.signalOrange)
    }
}

struct AddExerciseSheet: View {
    let onSave: (Exercise) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name = ""
    @State private var muscleGroup: MuscleGroup = .chest
    @State private var loadType: ExerciseLoadType = .externalWeight
    @State private var sideTracking: ExerciseSideTracking = .combined
    @State private var showDuplicateError = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
                    TextField("Name", text: $name)
                    Picker("Muscle group", selection: $muscleGroup) {
                        ForEach(MuscleGroup.allCases) { muscle in
                            Text(muscle.rawValue).tag(muscle)
                        }
                    }
                }

                Section {
                    Picker("Resistance", selection: $loadType) {
                        ForEach(ExerciseLoadType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    Picker("Side tracking", selection: $sideTracking) {
                        ForEach(ExerciseSideTracking.allCases) { tracking in
                            Text(tracking.rawValue).tag(tracking)
                        }
                    }
                } header: {
                    Text("Tracking")
                } footer: {
                    Text(loadType.guidance)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.paper)
            .navigationTitle("Custom Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .fontWeight(.bold)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .alert("Exercise already exists", isPresented: $showDuplicateError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Choose a different exercise name.")
        }
    }

    private func save() {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let nameExists = ExerciseCatalog
            .allExercises(context: modelContext)
            .contains { $0.name.localizedCaseInsensitiveCompare(cleanName) == .orderedSame }
        guard !nameExists else {
            showDuplicateError = true
            return
        }

        let model = CustomExercise(
            name: cleanName,
            muscleGroup: muscleGroup,
            loadType: loadType,
            sideTracking: sideTracking
        )
        modelContext.insert(model)
        try? modelContext.save()
        onSave(
            Exercise(
                name: cleanName,
                muscleGroup: muscleGroup,
                isCustom: true,
                loadType: loadType,
                sideTracking: sideTracking
            )
        )
        dismiss()
    }
}
