//
//  PaywallView.swift
//  No Limits
//
//  Created by Sukhman Singh on 3/5/26.
//

import SwiftUI

struct PaywallView: View {
    let onUnlock: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            // Ambient glow
            VStack {
                Circle()
                    .fill(Color.accentOrange.opacity(0.13))
                    .frame(width: 420, height: 420)
                    .blur(radius: 80)
                    .offset(y: -60)
                Spacer()
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Dismiss
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 32, height: 32)
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color.white.opacity(0.45))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()

                // Icon + Title
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.accentOrange.opacity(0.28), Color.clear],
                                    center: .center,
                                    startRadius: 8,
                                    endRadius: 52
                                )
                            )
                            .frame(width: 96, height: 96)
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(LinearGradient.accent)
                    }

                    VStack(spacing: 8) {
                        Text("Unlock Liftoff")
                            .font(.system(size: 34, weight: .black))
                            .foregroundColor(.white)
                        Text("Start your journey to Titan rank")
                            .font(.system(size: 16))
                            .foregroundColor(.textSecondary)
                    }
                }

                Spacer().frame(height: 44)

                // Features
                VStack(spacing: 16) {
                    PaywallFeatureRow(symbolName: "chart.bar.fill",   text: "Track your strength score over time")
                    PaywallFeatureRow(symbolName: "medal.fill",       text: "Earn and level up through 7 ranks")
                    PaywallFeatureRow(symbolName: "flame.fill",       text: "Build and maintain your daily streak")
                    PaywallFeatureRow(symbolName: "bell.badge.fill",  text: "Smart daily lift reminders")
                }
                .padding(.horizontal, 32)

                Spacer()

                // CTA
                VStack(spacing: 14) {
                    Button(action: onUnlock) {
                        VStack(spacing: 3) {
                            Text("Start for Free")
                                .font(.system(size: 17, weight: .bold))
                            Text("Then $9.99 / month")
                                .font(.system(size: 12))
                                .opacity(0.75)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(LinearGradient.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }

                    Button(action: {}) {
                        Text("Restore Purchase")
                            .font(.system(size: 14))
                            .foregroundColor(Color.white.opacity(0.4))
                    }

                    Text("Cancel anytime. Billed monthly.")
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.28))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }
}

// MARK: - Paywall Feature Row

struct PaywallFeatureRow: View {
    let symbolName: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.accentOrange.opacity(0.14))
                    .frame(width: 42, height: 42)
                Image(systemName: symbolName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(LinearGradient.accent)
            }

            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.white.opacity(0.82))

            Spacer()
        }
    }
}

#Preview {
    PaywallView(onUnlock: {}, onDismiss: {})
}
