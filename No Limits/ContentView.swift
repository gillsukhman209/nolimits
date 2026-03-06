//
//  ContentView.swift
//  No Limits
//
//  Created by Sukhman Singh on 3/5/26.
//

import SwiftUI

enum AppScreen: Equatable {
    case onboarding
    case paywall
    case home
    case log
    case rankUp(Rank, MuscleGroup)
    case exerciseDetail(String, MuscleGroup) // exerciseName, muscleGroup
}

struct ContentView: View {
    @State private var screen: AppScreen = .home

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()
            screenContent
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var screenContent: some View {
        switch screen {
        case .onboarding:
            OnboardingView(onComplete: { navigate(to: .paywall) })
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
        case .paywall:
            PaywallView(
                onUnlock: { navigate(to: .home) },
                onDismiss: { navigate(to: .home) }
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
        case .home:
            HomeView(
                onLogTap: { navigate(to: .log) },
                onRankUp: { rank, muscle in navigate(to: .rankUp(rank, muscle)) },
                onExerciseTap: { name, muscle in navigate(to: .exerciseDetail(name, muscle)) }
            )
            .transition(.opacity)
        case .log:
            LogView(
                onDismiss: { navigate(to: .home) },
                onRankUp: { rank, muscle in navigate(to: .rankUp(rank, muscle)) }
            )
            .transition(.asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .move(edge: .bottom).combined(with: .opacity)
            ))
        case .rankUp(let rank, let muscle):
            RankUpView(rank: rank, muscleGroup: muscle, onContinue: { navigate(to: .home) })
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                    removal: .opacity
                ))
        case .exerciseDetail(let name, let muscle):
            ExerciseDetailView(
                exerciseName: name,
                muscleGroup: muscle,
                onDismiss: { navigate(to: .home) }
            )
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            ))
        }
    }

    private func navigate(to destination: AppScreen) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            screen = destination
        }
    }
}

#Preview {
    ContentView()
}
