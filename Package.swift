// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "LiftoffCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "LiftoffCore", targets: ["LiftoffCore"]),
    ],
    targets: [
        .target(
            name: "LiftoffCore",
            path: "No Limits",
            exclude: [
                "AppearancePreference.swift",
                "Assets.xcassets",
                "BebasNeue-OFL.txt",
                "BebasNeue-Regular.ttf",
                "BodyMapView.swift",
                "ContentView.swift",
                "DesignSystem.swift",
                "ExerciseDetailView.swift",
                "FontRegistration.swift",
                "HistoryView.swift",
                "HomeView.swift",
                "HomeViewModel.swift",
                "LogView.swift",
                "No_LimitsApp.swift",
                "OnboardingView.swift",
                "PaywallView.swift",
                "ProfileSettingsView.swift",
                "ProgressView.swift",
                "RankUpView.swift",
                "ReminderService.swift",
                "body.png",
            ],
            sources: [
                "AppStats.swift",
                "CustomExercise.swift",
                "ExerciseTracking.swift",
                "LiftAnalytics.swift",
                "LiftEntry.swift",
                "LogViewModel.swift",
                "MuscleGroup.swift",
                "Rank.swift",
                "RankingService.swift",
                "StreakService.swift",
                "UserProfile.swift",
            ]
        ),
        .testTarget(
            name: "LiftoffCoreTests",
            dependencies: ["LiftoffCore"],
            path: "No LimitsTests"
        ),
    ]
)
