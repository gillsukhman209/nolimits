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
            .transition(.move(edge: .bottom))
        case .home:
            HomeView(
                onLogTap: { navigate(to: .log) },
                onRankUp: { rank, muscle in navigate(to: .rankUp(rank, muscle)) }
            )
            .transition(.opacity)
        case .log:
            LogView(
                onDismiss: { navigate(to: .home) },
                onRankUp: { rank, muscle in navigate(to: .rankUp(rank, muscle)) }
            )
            .transition(.move(edge: .bottom))
        case .rankUp(let rank, let muscle):
            RankUpView(rank: rank, muscleGroup: muscle, onContinue: { navigate(to: .home) })
                .transition(.opacity)
        }
    }

    private func navigate(to destination: AppScreen) {
        withAnimation(.easeInOut(duration: 0.35)) {
            screen = destination
        }
    }
}

#Preview {
    ContentView()
}
