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
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear { seedDefaultData() }
        }
        .modelContainer(sharedModelContainer)
    }

    private func seedDefaultData() {
        let context = sharedModelContainer.mainContext
        let profileFetch = FetchDescriptor<UserProfile>()
        let statsFetch = FetchDescriptor<AppStats>()

        do {
            if try context.fetch(profileFetch).isEmpty {
                context.insert(UserProfile())
            }
            if try context.fetch(statsFetch).isEmpty {
                context.insert(AppStats())
            }
            try context.save()
        } catch {
            print("Failed to seed default data: \(error)")
        }
    }
}
