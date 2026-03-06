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

    @State private var badgeScale: CGFloat = 0.3
    @State private var badgeOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.5
    @State private var ringRotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var particleOpacity: Double = 0
    @State private var particleOffset: CGFloat = 0

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            // Deep background glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [rank.color.opacity(0.25), rank.color.opacity(0.06), .clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 300
                    )
                )
                .frame(width: 600, height: 600)
                .scaleEffect(ringScale)
                .opacity(glowOpacity)

            // Particle burst
            ForEach(0..<8) { i in
                Circle()
                    .fill(rank.color)
                    .frame(width: 4, height: 4)
                    .offset(
                        x: cos(Double(i) * .pi / 4) * (80 + particleOffset),
                        y: sin(Double(i) * .pi / 4) * (80 + particleOffset)
                    )
                    .opacity(particleOpacity)
            }

            VStack(spacing: 0) {
                Spacer()

                // Badge
                ZStack {
                    // Outer rotating ring
                    Circle()
                        .strokeBorder(
                            AngularGradient(
                                colors: [rank.color, rank.color.opacity(0.1), rank.color.opacity(0.4), rank.color],
                                center: .center
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 180, height: 180)
                        .rotationEffect(.degrees(ringRotation))

                    // Inner glow
                    Circle()
                        .fill(rank.color.opacity(0.10))
                        .frame(width: 150, height: 150)
                        .scaleEffect(pulseScale)

                    Circle()
                        .strokeBorder(rank.color.opacity(0.25), lineWidth: 1.5)
                        .frame(width: 150, height: 150)

                    Image(systemName: rank.symbolName)
                        .font(.system(size: 60, weight: .semibold))
                        .foregroundStyle(rank.gradient)
                        .glow(rank.color, radius: 16)
                }
                .scaleEffect(badgeScale)
                .opacity(badgeOpacity)

                Spacer().frame(height: 44)

                // Text
                VStack(spacing: 14) {
                    Text("RANK UP")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundColor(rank.color)
                        .tracking(6)
                        .glow(rank.color, radius: 3)

                    Text(rank.rawValue)
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundColor(.white)

                    Text("Your \(muscleGroup.rawValue) ranked up.\nKeep pushing.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                }
                .opacity(textOpacity)

                Spacer()

                // Continue button
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onContinue()
                }) {
                    Text("Continue")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(rank.color.opacity(0.18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(rank.color.opacity(0.45), lineWidth: 1.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .opacity(buttonOpacity)
                .padding(.horizontal, 32)
                .padding(.bottom, 52)
            }
        }
        .onAppear { runEntranceAnimation() }
    }

    private func runEntranceAnimation() {
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)

        // Badge entrance
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.05)) {
            badgeScale = 1.0
            badgeOpacity = 1.0
            ringScale = 1.0
            glowOpacity = 1.0
        }

        // Particle burst
        withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
            particleOpacity = 0.8
            particleOffset = 40
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
            particleOpacity = 0
        }

        // Ring rotation (continuous)
        withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
            ringRotation = 360
        }

        // Pulse (continuous)
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(0.3)) {
            pulseScale = 1.08
        }

        // Text
        withAnimation(.easeOut(duration: 0.4).delay(0.35)) {
            textOpacity = 1.0
        }

        // Button
        withAnimation(.easeOut(duration: 0.35).delay(0.55)) {
            buttonOpacity = 1.0
        }
    }
}

#Preview {
    RankUpView(rank: .gold, muscleGroup: .chest, onContinue: {})
}
