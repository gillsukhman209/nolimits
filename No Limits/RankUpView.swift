//
//  RankUpView.swift
//  No Limits
//
//  Created by Sukhman Singh on 3/5/26.
//

import SwiftUI
import UIKit

struct RankUpView: View {
    let rank: Rank
    let muscleGroup: MuscleGroup
    let onContinue: () -> Void

    @State private var phase: Int = 0
    @State private var ringRotation: Double = 0

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            // Radial glow behind everything
            RadialGradient(
                colors: [rank.color.opacity(0.12), rank.color.opacity(0.02), .clear],
                center: .center,
                startRadius: 20,
                endRadius: 400
            )
            .ignoresSafeArea()
            .opacity(phase >= 1 ? 1 : 0)

            VStack(spacing: 0) {
                Spacer()

                // Concentric ring animation
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(rank.color.opacity(0.06), lineWidth: 1)
                        .frame(width: 240, height: 240)
                        .scaleEffect(phase >= 1 ? 1 : 0.5)

                    // Middle ring
                    Circle()
                        .stroke(rank.color.opacity(0.12), lineWidth: 1.5)
                        .frame(width: 180, height: 180)
                        .scaleEffect(phase >= 1 ? 1 : 0.5)

                    // Progress ring
                    Circle()
                        .trim(from: 0, to: phase >= 1 ? 1 : 0)
                        .stroke(
                            rank.color.opacity(0.30),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(ringRotation - 90))

                    // Inner filled circle
                    Circle()
                        .fill(rank.color.opacity(0.08))
                        .frame(width: 110, height: 110)
                        .scaleEffect(phase >= 1 ? 1 : 0.3)

                    // Rank icon
                    Image(systemName: rank.symbolName)
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(rank.gradient)
                        .scaleEffect(phase >= 1 ? 1 : 0.3)
                        .opacity(phase >= 1 ? 1 : 0)
                }

                Spacer().frame(height: 48)

                // Text
                VStack(spacing: 12) {
                    Text("RANK UP")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(rank.color)
                        .tracking(5)

                    Text(rank.rawValue)
                        .font(.system(size: 56, weight: .heavy))
                        .foregroundColor(.white)

                    Text("\(muscleGroup.rawValue) ranked up")
                        .font(.system(size: 15))
                        .foregroundColor(.textSecondary)
                }
                .opacity(phase >= 2 ? 1 : 0)
                .offset(y: phase >= 2 ? 0 : 16)

                Spacer()

                // Continue
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onContinue()
                }) {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(rank.color)
                        .clipShape(Capsule())
                }
                .opacity(phase >= 3 ? 1 : 0)
                .padding(.horizontal, 32)
                .padding(.bottom, 52)
            }
        }
        .onAppear { runAnimation() }
    }

    private func runAnimation() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.05)) {
            phase = 1
        }
        withAnimation(.easeOut(duration: 0.35).delay(0.35)) {
            phase = 2
        }
        withAnimation(.easeOut(duration: 0.3).delay(0.6)) {
            phase = 3
        }
        withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false).delay(0.3)) {
            ringRotation = 360
        }
    }
}

#Preview {
    RankUpView(rank: .gold, muscleGroup: .chest, onContinue: {})
}
