import SwiftData
import SwiftUI

struct EditSetPresentation: Identifiable {
    let id = UUID()
    let entry: LiftEntry
}

struct EditSetSheet: View {
    let entry: LiftEntry

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var weight: String
    @State private var reps: String
    @State private var date: Date

    init(entry: LiftEntry) {
        self.entry = entry
        _weight = State(initialValue: entry.weight.formattedWeight)
        _reps = State(initialValue: String(entry.reps))
        _date = State(initialValue: entry.date)
    }

    private var canSave: Bool {
        guard let weightValue = Double(weight),
              let repsValue = Int(reps),
              repsValue > 0 else { return false }
        return entry.loadType == .assistance ? weightValue >= 0 : weightValue > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Set") {
                    LabeledContent(entry.loadType.inputLabel.capitalized) {
                        HStack(spacing: 4) {
                            TextField("0", text: $weight)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            Text("lb").foregroundStyle(.secondary)
                        }
                        .frame(width: 112)
                    }
                    LabeledContent("Reps") {
                        TextField("0", text: $reps)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 70)
                    }
                    DatePicker("Date and time", selection: $date)
                }

                Section {
                    LabeledContent("Exercise", value: entry.liftType)
                    if entry.side != .both {
                        LabeledContent("Side", value: entry.side.rawValue)
                    }
                } header: {
                    Text("Tracking")
                } footer: {
                    Text("Editing recalculates the estimated max, personal bests, charts, and exercise trends.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.paper)
            .navigationTitle("Edit Set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .fontWeight(.bold)
                        .disabled(!canSave)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(30)
    }

    private func save() {
        guard canSave,
              let weightValue = Double(weight),
              let repsValue = Int(reps) else { return }
        entry.weight = weightValue
        entry.reps = repsValue
        entry.date = date
        entry.e1RM = PerformanceService.estimatedMax(
            weight: weightValue,
            reps: repsValue,
            bodyweight: entry.bodyweightAtLog ?? profiles.first?.bodyweight ?? 0,
            loadType: entry.loadType
        )
        try? modelContext.save()
        AppStatsSynchronizer.rebuild(context: modelContext)
        dismiss()
    }
}
