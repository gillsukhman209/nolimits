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
                "ContentView.swift",
                "DesignSystem.swift",
                "EditSetSheet.swift",
                "ExerciseDetailView.swift",
                "FontRegistration.swift",
                "HistoryView.swift",
                "HomeView.swift",
                "LogView.swift",
                "No_LimitsApp.swift",
                "OnboardingView.swift",
                "PaywallView.swift",
                "PersonalRecordCelebrationView.swift",
                "ProfileSettingsView.swift",
                "ProgressView.swift",
                "ReminderService.swift",
                "RestTimerController.swift",
                "RestTimerView.swift",
                "TrainingReviewService.swift",
                "TrainingReviewView.swift",
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
                "RestTimerMath.swift",
                "StreakService.swift",
                "TrainingReviewData.swift",
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
