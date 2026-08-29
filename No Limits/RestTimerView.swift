import SwiftUI
import UIKit

struct RestTimerBanner: View {
    let timer: RestTimerController
    let onOpen: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onOpen) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .stroke(Color.signalPaper.opacity(0.2), lineWidth: 3)
                        Circle()
                            .trim(from: 0, to: timer.progress)
                            .stroke(
                                Color.signalOrange,
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                        Image(systemName: "timer")
                            .font(.system(size: 14, weight: .black))
                    }
                    .frame(width: 36, height: 36)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("REST")
                            .font(.system(size: 10, weight: .black))
                            .tracking(1.5)
                            .foregroundStyle(Color.signalPaper.opacity(0.62))
                        Text(timer.formattedRemainingTime)
                            .font(.system(size: 22, weight: .black, design: .monospaced))
                            .foregroundStyle(Color.signalPaper)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Button("+30") {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                timer.add(seconds: 30)
            }
            .font(.system(size: 13, weight: .black))
            .foregroundStyle(Color.signalPaper)
            .frame(width: 52, height: 38)
            .background(Color.signalPaper.opacity(0.12), in: Capsule())

            Button {
                timer.stop()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(Color.signalPaper.opacity(0.72))
                    .frame(width: 38, height: 38)
            }
            .accessibilityLabel("End rest timer")
        }
        .padding(.horizontal, 16)
        .frame(height: 66)
        .background(Color.signalInk)
        .overlay(alignment: .top) {
            Rectangle().fill(Color.signalOrange).frame(height: 2)
        }
        .accessibilityElement(children: .contain)
    }
}

struct RestTimerSheet: View {
    let timer: RestTimerController

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("NEXT SET")
                        .sectionEyebrow()
                    Text("REST TIMER")
                        .editorialTitle(size: 44)
                        .foregroundStyle(Color.ink)
                }
                Spacer()
                Button("Done") { dismiss() }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.ink)
            }

            Spacer(minLength: 24)

            ZStack {
                Circle()
                    .stroke(Color.hairline.opacity(0.5), lineWidth: 12)
                Circle()
                    .trim(from: 0, to: timer.progress)
                    .stroke(
                        Color.signalOrange,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.2), value: timer.progress)

                VStack(spacing: 3) {
                    Text(timer.formattedRemainingTime)
                        .font(.system(size: 54, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.ink)
                    Text(timer.isRunning ? "RECOVER" : "READY")
                        .font(.system(size: 11, weight: .black))
                        .tracking(2)
                        .foregroundStyle(Color.inkMuted)
                }
            }
            .frame(width: 230, height: 230)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Rest timer")
            .accessibilityValue(timer.formattedRemainingTime)

            Spacer(minLength: 20)

            HStack(spacing: 8) {
                presetButton("2:00", seconds: 120)
                presetButton("2:30", seconds: 150)
                presetButton("3:00", seconds: 180)
            }

            Spacer(minLength: 14)

            HStack(spacing: 10) {
                timerButton("+30 SEC", icon: "plus") {
                    timer.add(seconds: 30)
                }
                timerButton("END REST", icon: "stop.fill") {
                    timer.stop()
                    dismiss()
                }
            }
        }
        .padding(24)
        .background(Color.paper.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(30)
    }

    private func presetButton(_ title: String, seconds: Int) -> some View {
        Button {
            timer.start(seconds: seconds)
        } label: {
            Text(title)
                .font(.system(size: 15, weight: .black, design: .monospaced))
                .foregroundStyle(timer.durationSeconds == seconds ? Color.signalInk : Color.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(
                    timer.durationSeconds == seconds ? Color.signalOrange : Color.hairline.opacity(0.3),
                    in: RoundedRectangle(cornerRadius: 12)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Start a \(title) rest timer")
    }

    private func timerButton(
        _ title: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 13, weight: .black))
                .fontWidth(.condensed)
                .foregroundStyle(Color.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.paperRaised, in: RoundedRectangle(cornerRadius: 15))
                .overlay {
                    RoundedRectangle(cornerRadius: 15).stroke(Color.hairline)
                }
        }
        .buttonStyle(.plain)
    }
}
