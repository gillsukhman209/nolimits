//
//  ExerciseDetailView.swift
//  No Limits
//
//  Created by Sukhman Singh on 3/6/26.
//

import SwiftUI
import SwiftData

// MARK: - Weight Record

struct WeightRecord: Identifiable {
    let weight: Int
    let bestReps: Int
    let previousBestReps: Int?
    let entries: [LiftEntry] // all entries at this weight, chronological
    var id: Int { weight }

    var trend: Trend {
        guard let prev = previousBestReps else { return .new }
        if bestReps > prev { return .up }
        if bestReps < prev { return .down }
        return .same
    }

    enum Trend {
        case up, down, same, new
    }
}

struct ExerciseDetailView: View {
    let exerciseName: String
    let muscleGroup: MuscleGroup
    let onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var allEntries: [LiftEntry] = []
    @State private var weightRecords: [WeightRecord] = []
    @State private var bestE1RM: Double = 0
    @State private var bestEntry: LiftEntry?
    @State private var selectedWeight: Int?

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            VStack(spacing: 0) {
                navBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Best lift hero
                        bestLiftCard

                        // Last session
                        lastSessionCard

                        // Weight records
                        weightRecordsSection

                        // Chart for selected weight
                        if let selected = selectedWeight,
                           let record = weightRecords.first(where: { $0.weight == selected }),
                           record.entries.count >= 2 {
                            repChartSection(record: record)
                        }

                        // Full history
                        historySection
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear { loadData() }
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        HStack {
            Button(action: onDismiss) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.textSecondary)
            }
            Spacer()
            VStack(spacing: 2) {
                Text(exerciseName)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                Text(muscleGroup.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.accentOrange)
            }
            Spacer()
            Color.clear.frame(width: 15, height: 15)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Best Lift Card

    private var bestLiftCard: some View {
        VStack(spacing: 8) {
            Text("PERSONAL BEST")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.textSecondary)
                .tracking(2)

            if let best = bestEntry {
                Text("\(Int(best.weight)) lbs x \(best.reps)")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                Text("E1RM: \(Int(best.e1RM)) lbs")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.accentOrange)
            } else {
                Text("No lifts yet")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.accentOrange.opacity(0.12), lineWidth: 1)
        )
    }

    // MARK: - Last Session Card

    private var lastSessionCard: some View {
        Group {
            if let lastEntry = allEntries.first {
                VStack(alignment: .leading, spacing: 10) {
                    Text("LAST SESSION")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.textSecondary)
                        .tracking(2)

                    // Group entries by date — show the most recent day
                    let lastDay = Calendar.current.startOfDay(for: lastEntry.date)
                    let dayEntries = allEntries.filter {
                        Calendar.current.startOfDay(for: $0.date) == lastDay
                    }

                    HStack {
                        Text(formattedDate(lastEntry.date))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(dayEntries.count) set\(dayEntries.count == 1 ? "" : "s")")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }

                    ForEach(dayEntries, id: \.id) { entry in
                        HStack {
                            Text("\(Int(entry.weight)) lbs")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            Text("x")
                                .font(.system(size: 12))
                                .foregroundColor(.textTertiary)
                            Text("\(entry.reps) reps")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            Spacer()
                            Text("E1RM \(Int(entry.e1RM))")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.vertical, 6)
                    }
                }
                .padding(16)
                .background(Color.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.cardBorder, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Weight Records

    private var weightRecordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RECORDS BY WEIGHT")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.textSecondary)
                .tracking(2)

            if weightRecords.isEmpty {
                Text("Log some lifts to see your records")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                    .padding(.vertical, 16)
            } else {
                ForEach(weightRecords) { record in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedWeight = selectedWeight == record.weight ? nil : record.weight
                        }
                    }) {
                        weightRecordRow(record: record)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func weightRecordRow(record: WeightRecord) -> some View {
        HStack(spacing: 12) {
            // Weight
            VStack(alignment: .leading, spacing: 2) {
                Text("\(record.weight) lbs")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("\(record.entries.count) log\(record.entries.count == 1 ? "" : "s")")
                    .font(.system(size: 11))
                    .foregroundColor(.textTertiary)
            }

            Spacer()

            // Best reps
            Text("\(record.bestReps) reps")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(.white)

            // Trend indicator
            trendBadge(record.trend)

            // Expand indicator
            Image(systemName: selectedWeight == record.weight ? "chevron.down" : "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.textTertiary)
        }
        .padding(14)
        .background(selectedWeight == record.weight ? Color.surfaceBg : Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    selectedWeight == record.weight ? Color.accentOrange.opacity(0.2) : Color.cardBorder,
                    lineWidth: 1
                )
        )
    }

    private func trendBadge(_ trend: WeightRecord.Trend) -> some View {
        Group {
            switch trend {
            case .up:
                HStack(spacing: 3) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 9, weight: .bold))
                    Text("PR")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(.green)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.12))
                .clipShape(Capsule())
            case .down:
                Image(systemName: "arrow.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.accentRed)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentRed.opacity(0.12))
                    .clipShape(Capsule())
            case .same:
                Image(systemName: "equal")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.surfaceBg)
                    .clipShape(Capsule())
            case .new:
                Text("NEW")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.accentOrange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentOrange.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Rep Chart for Selected Weight

    private func repChartSection(record: WeightRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("REPS AT \(record.weight) LBS")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.textSecondary)
                .tracking(2)

            RepChartView(entries: record.entries)
                .frame(height: 160)
        }
        .padding(18)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.accentOrange.opacity(0.12), lineWidth: 1)
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Full History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ALL HISTORY")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.textSecondary)
                .tracking(2)

            if allEntries.isEmpty {
                Text("No entries yet")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                ForEach(allEntries, id: \.id) { entry in
                    HStack {
                        Text(formattedDate(entry.date))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.textSecondary)
                            .frame(width: 70, alignment: .leading)
                        Spacer()
                        Text("\(Int(entry.weight)) lbs")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        Text("x")
                            .font(.system(size: 11))
                            .foregroundColor(.textTertiary)
                        Text("\(entry.reps)")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 30, alignment: .trailing)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(Color.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.cardBorder, lineWidth: 1)
                    )
                }
            }
        }
    }

    // MARK: - Data Loading

    private func loadData() {
        let name = exerciseName
        var descriptor = FetchDescriptor<LiftEntry>(
            predicate: #Predicate<LiftEntry> { $0.liftType == name },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 100
        allEntries = (try? modelContext.fetch(descriptor)) ?? []

        // Best entry by e1RM
        bestEntry = allEntries.max(by: { $0.e1RM < $1.e1RM })
        bestE1RM = bestEntry?.e1RM ?? 0

        // Build weight records
        buildWeightRecords()
    }

    private func buildWeightRecords() {
        // Group entries by rounded weight
        var grouped: [Int: [LiftEntry]] = [:]
        for entry in allEntries {
            let w = Int(entry.weight)
            grouped[w, default: []].append(entry)
        }

        weightRecords = grouped.map { weight, entries in
            // Sort chronologically for this weight
            let sorted = entries.sorted { $0.date < $1.date }
            let bestReps = sorted.map(\.reps).max() ?? 0

            // Previous best = best reps before the most recent entry
            let previousBestReps: Int? = {
                guard sorted.count >= 2 else { return nil }
                let allButLast = sorted.dropLast()
                return allButLast.map(\.reps).max()
            }()

            return WeightRecord(
                weight: weight,
                bestReps: bestReps,
                previousBestReps: previousBestReps,
                entries: sorted
            )
        }
        .sorted { $0.weight > $1.weight } // heaviest first
    }

    private func formattedDate(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Rep Chart (reps over time at a specific weight)

struct RepChartView: View {
    let entries: [LiftEntry]

    var body: some View {
        GeometryReader { geo in
            let data = entries.map { $0.reps }
            let minVal = max((data.min() ?? 0) - 2, 0)
            let maxVal = (data.max() ?? 1) + 2
            let range = max(Double(maxVal - minVal), 1)
            let w = geo.size.width
            let h = geo.size.height
            let count = data.count

            ZStack(alignment: .topLeading) {
                // Grid lines
                ForEach(0..<4, id: \.self) { i in
                    let y = h * CGFloat(i) / 3.0
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: y))
                        p.addLine(to: CGPoint(x: w, y: y))
                    }
                    .stroke(Color.white.opacity(0.04), lineWidth: 1)
                }

                if count > 1 {
                    // Gradient fill
                    Path { path in
                        for (i, val) in data.enumerated() {
                            let x = w * CGFloat(i) / CGFloat(count - 1)
                            let y = h - h * CGFloat(Double(val - minVal) / range)
                            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                            else { path.addLine(to: CGPoint(x: x, y: y)) }
                        }
                        path.addLine(to: CGPoint(x: w, y: h))
                        path.addLine(to: CGPoint(x: 0, y: h))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [Color.accentOrange.opacity(0.15), Color.accentOrange.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // Line
                    Path { path in
                        for (i, val) in data.enumerated() {
                            let x = w * CGFloat(i) / CGFloat(count - 1)
                            let y = h - h * CGFloat(Double(val - minVal) / range)
                            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                            else { path.addLine(to: CGPoint(x: x, y: y)) }
                        }
                    }
                    .stroke(Color.accentOrange, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                    // Dots with rep labels
                    ForEach(Array(data.enumerated()), id: \.offset) { i, val in
                        let x = w * CGFloat(i) / CGFloat(count - 1)
                        let y = h - h * CGFloat(Double(val - minVal) / range)

                        Circle()
                            .fill(Color.accentOrange)
                            .frame(width: 7, height: 7)
                            .position(x: x, y: y)

                        Text("\(val)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .position(x: x, y: y - 14)
                    }
                } else if count == 1 {
                    let val = data[0]
                    let x = w / 2
                    let y = h / 2
                    Circle()
                        .fill(Color.accentOrange)
                        .frame(width: 8, height: 8)
                        .position(x: x, y: y)
                    Text("\(val) reps")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .position(x: x, y: y - 16)
                }

                // Y-axis labels
                VStack {
                    Text("\(maxVal)")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundColor(.textTertiary)
                    Spacer()
                    Text("\(minVal)")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundColor(.textTertiary)
                }
                .frame(height: h)
            }
        }
    }
}
