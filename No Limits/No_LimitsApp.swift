//
//  No_LimitsApp.swift
//  No Limits
//
//  Created by Sukhman Singh on 3/5/26.
//

import SwiftUI
import SwiftData

@main
struct No_LimitsApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            LiftEntry.self,
            AppStats.self,
            CustomExercise.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        FontRegistration.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear { ensureSupportingData() }
        }
        .modelContainer(sharedModelContainer)
    }

    private func ensureSupportingData() {
        let context = sharedModelContainer.mainContext
        let statsFetch = FetchDescriptor<AppStats>()

        do {
            if try context.fetch(statsFetch).isEmpty {
                context.insert(AppStats())
            }
            try context.save()
        } catch {
            print("Failed to initialize supporting data: \(error)")
        }
    }
}
