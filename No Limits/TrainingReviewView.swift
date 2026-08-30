import SwiftUI

struct TrainingReviewView: View {
    let entries: [LiftEntry]
    let bodyweight: Double

    @Environment(\.dismiss) private var dismiss
    @State private var result: TrainingReviewResult?
    @State private var isGenerating = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    hero
                    privacyNote
                    reviewContent
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
                .padding(.bottom, 34)
            }
            .background(Color.paper)
            .navigationTitle("Training Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.ink)
                }
                if result != nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            Task { await generate() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .disabled(isGenerating)
                        .accessibilityLabel("Generate a new review")
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationCornerRadius(30)
        .task {
            guard result == nil else { return }
            await generate()
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("LIFTOFF COACH")
                        .font(.system(size: 11, weight: .black))
                        .tracking(1.8)
                        .foregroundStyle(Color.signalPaper.opacity(0.62))
                    Text("YOUR DATA,\nREVIEWED.")
                        .font(.system(size: 34, weight: .black))
                        .fontWidth(.compressed)
                        .foregroundStyle(Color.signalPaper)
                }
                Spacer()
                Image(systemName: "sparkles")
                    .font(.system(size: 27, weight: .black))
                    .foregroundStyle(Color.signalOrange)
            }

            HStack(spacing: 0) {
                heroStat("\(entries.count)", "SETS")
                heroDivider
                heroStat("\(Set(entries.map(\.liftType)).count)", "EXERCISES")
                heroDivider
                heroStat("\(trainingDays)", "DAYS")
            }
        }
        .padding(20)
        .background(Color.signalInk, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var privacyNote: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: "lock.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.success)
                .frame(width: 28, height: 28)
                .background(Color.success.opacity(0.1), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text("PRIVATE BY DESIGN")
                    .font(.system(size: 10, weight: .black))
                    .tracking(1)
                    .foregroundStyle(Color.ink)
                Text("On supported devices, Apple Intelligence reviews aggregated training data on-device. Nothing is sent to a Liftoff server.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.inkMuted)
            }
        }
        .padding(14)
        .cardStyle(cornerRadius: 15)
    }

    @ViewBuilder
    private var reviewContent: some View {
        if isGenerating {
            VStack(spacing: 17) {
                SwiftUI.ProgressView()
                    .tint(Color.signalOrange)
                    .scaleEffect(1.1)
                Text("Reviewing your full week…")
                    .font(.system(size: 16, weight: .black))
                    .fontWidth(.condensed)
                    .foregroundStyle(Color.ink)
                Text("Checking each day, muscle coverage, workload balance, exercise trends, and left/right performance.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.inkMuted)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 48)
        } else if let result {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label(sourceLabel(result.source), systemImage: sourceIcon(result.source))
                        .font(.system(size: 10, weight: .black))
                        .tracking(0.8)
                        .foregroundStyle(Color.signalOrange)
                    Spacer()
                    Text(result.generatedAt.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.inkMuted)
                }

                ReviewMarkdownText(text: result.text)
            }
            .padding(18)
            .cardStyle(cornerRadius: 18)
        }
    }

    private var trainingDays: Int {
        Set(entries.map { Calendar.current.startOfDay(for: $0.date) }).count
    }

    private var heroDivider: some View {
        Rectangle()
            .fill(Color.signalPaper.opacity(0.12))
            .frame(width: 1, height: 31)
    }

    private func heroStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 22, weight: .black))
                .fontWidth(.compressed)
                .foregroundStyle(Color.signalPaper)
            Text(label)
                .font(.system(size: 8, weight: .black))
                .tracking(0.8)
                .foregroundStyle(Color.signalPaper.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
    }

    private func sourceLabel(_ source: TrainingReviewResult.Source) -> String {
        switch source {
        case .onDeviceAI: return "ON-DEVICE AI REVIEW"
        case .analytics: return "PRIVATE DATA REVIEW"
        }
    }

    private func sourceIcon(_ source: TrainingReviewResult.Source) -> String {
        switch source {
        case .onDeviceAI: return "sparkles"
        case .analytics: return "chart.xyaxis.line"
        }
    }

    @MainActor
    private func generate() async {
        isGenerating = true
        result = await TrainingReviewService.generate(
            entries: entries,
            bodyweight: bodyweight
        )
        isGenerating = false
    }
}

private struct ReviewMarkdownText: View {
    let text: String

    private var lines: [String] {
        text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                if line.hasPrefix("## ") {
                    Text(String(line.dropFirst(3)).uppercased())
                        .font(.system(size: 12, weight: .black))
                        .tracking(1.3)
                        .foregroundStyle(Color.signalOrange)
                        .padding(.top, 5)
                } else if line.hasPrefix("- ") {
                    HStack(alignment: .top, spacing: 9) {
                        Circle()
                            .fill(Color.signalOrange)
                            .frame(width: 5, height: 5)
                            .padding(.top, 8)
                        inlineText(String(line.dropFirst(2)))
                    }
                } else {
                    inlineText(line)
                }
            }
        }
        .textSelection(.enabled)
    }

    private func inlineText(_ value: String) -> Text {
        let attributed = (try? AttributedString(
            markdown: value,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
        )) ?? AttributedString(value)
        return Text(attributed)
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(Color.ink)
    }
}
