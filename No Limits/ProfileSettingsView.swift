import SwiftUI
import SwiftData

struct ProfileSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var entries: [LiftEntry]
    @AppStorage("liftoff.remindersEnabled") private var remindersEnabled = false
    @AppStorage("liftoff.appearance") private var appearanceRaw =
        AppearancePreference.system.rawValue
    @AppStorage("liftoff.restTimer.autoStart") private var autoStartRestTimer = true
    @AppStorage("liftoff.restTimer.duration") private var restTimerDuration = 150
    @AppStorage("liftoff.reminderTime") private var reminderTimestamp =
        Calendar.current.date(
            bySettingHour: 19,
            minute: 30,
            second: 0,
            of: .now
        )?.timeIntervalSince1970 ?? Date.now.timeIntervalSince1970

    @State private var bodyweight = ""
    @State private var height = ""
    @State private var experience = "Intermediate"
    @State private var goal = "Strength"
    @State private var showResetConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    Picker("Experience", selection: $experience) {
                        ForEach(["Beginner", "Intermediate", "Advanced"], id: \.self) {
                            Text($0).tag($0)
                        }
                    }
                    Picker("Primary goal", selection: $goal) {
                        ForEach(["Strength", "Muscle", "Fat Loss"], id: \.self) {
                            Text($0).tag($0)
                        }
                    }
                    LabeledContent("Bodyweight") {
                        HStack(spacing: 4) {
                            TextField("175", text: $bodyweight)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 70)
                            Text("lb").foregroundStyle(.secondary)
                        }
                    }
                    LabeledContent("Height") {
                        HStack(spacing: 4) {
                            TextField("70", text: $height)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 70)
                            Text("in").foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    Picker("Appearance", selection: $appearanceRaw) {
                        ForEach(AppearancePreference.allCases) { appearance in
                            Label(appearance.rawValue, systemImage: appearance.iconName)
                                .tag(appearance.rawValue)
                        }
                    }
                } header: {
                    Text("Theme")
                } footer: {
                    Text("System follows your iPhone appearance automatically.")
                }

                Section {
                    Toggle("Start after saving a set", isOn: $autoStartRestTimer)
                    if autoStartRestTimer {
                        Picker("Rest duration", selection: $restTimerDuration) {
                            Text("2:00").tag(120)
                            Text("2:30").tag(150)
                            Text("3:00").tag(180)
                        }
                    }
                } header: {
                    Text("Rest Timer")
                } footer: {
                    Text("The timer stays accurate while Liftoff is in the background. If notifications are allowed, Liftoff alerts you when rest is over.")
                }

                Section {
                    Toggle("Daily reminder", isOn: $remindersEnabled)
                    if remindersEnabled {
                        DatePicker(
                            "Reminder time",
                            selection: reminderDateBinding,
                            displayedComponents: .hourAndMinute
                        )
                    }
                } header: {
                    Text("Reminder")
                } footer: {
                    Text("A local reminder can prompt you if today has not been logged.")
                }

                Section {
                    Button("Delete all lift history", role: .destructive) {
                        showResetConfirmation = true
                    }
                } footer: {
                    Text("\(entries.count) lift log\(entries.count == 1 ? "" : "s") stored on this device.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.paper)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.ink)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .fontWeight(.bold)
                }
            }
            .confirmationDialog(
                "Delete every lift log?",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete All", role: .destructive, action: resetHistory)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This cannot be undone.")
            }
        }
        .presentationCornerRadius(30)
        .onAppear(perform: loadProfile)
        .onChange(of: remindersEnabled) {
            Task {
                await ReminderService.updateSchedule(
                    isEnabled: remindersEnabled,
                    reminderTime: Date(timeIntervalSince1970: reminderTimestamp),
                    logDates: entries.map(\.date),
                    requestAuthorization: remindersEnabled
                )
            }
        }
        .onChange(of: reminderTimestamp) {
            guard remindersEnabled else { return }
            Task {
                await ReminderService.updateSchedule(
                    isEnabled: true,
                    reminderTime: Date(timeIntervalSince1970: reminderTimestamp),
                    logDates: entries.map(\.date)
                )
            }
        }
    }

    private var reminderDateBinding: Binding<Date> {
        Binding(
            get: { Date(timeIntervalSince1970: reminderTimestamp) },
            set: { reminderTimestamp = $0.timeIntervalSince1970 }
        )
    }

    private func loadProfile() {
        guard let profile = profiles.first else { return }
        bodyweight = profile.bodyweight.formattedWeight
        height = profile.height.formattedWeight
        experience = profile.experience
        goal = profile.goal
    }

    private func save() {
        guard let profile = profiles.first else {
            dismiss()
            return
        }
        profile.experience = experience
        profile.goal = goal
        if let value = Double(bodyweight), value > 0 {
            profile.bodyweight = value
        }
        if let value = Double(height), value > 0 {
            profile.height = value
        }
        try? modelContext.save()
        dismiss()
    }

    private func resetHistory() {
        entries.forEach(modelContext.delete)
        try? modelContext.save()
        AppStatsSynchronizer.rebuild(context: modelContext)
    }
}
