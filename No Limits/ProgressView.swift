import Charts
import SwiftData
import SwiftUI

struct ProgressView: View {
    enum SortMode: String, CaseIterable, Identifiable {
        case recent = "Recent"
        case mostSets = "Most sets"
        case name = "A–Z"
        var id: String { rawValue }
    }

    let onExerciseTap: (String, MuscleGroup) -> Void

    @Query(sort: \LiftEntry.date, order: .reverse) private var entries: [LiftEntry]
    @Query private var profiles: [UserProfile]
    @State private var searchText = ""
    @State private var selectedMuscle: MuscleGroup?
    @State private var sortMode: SortMode = .recent
    @State private var showTrainingReview = false

    private var summaries: [ExerciseSummary] {
        let base = LiftAnalytics.summaries(from: entries).filter { summary in
            let matchesSearch = searchText.isEmpty
                || summary.name.localizedCaseInsensitiveContains(searchText)
            let matchesMuscle = selectedMuscle == nil
                || summary.muscleGroup == selectedMuscle
            return matchesSearch && matchesMuscle
        }
        switch sortMode {
        case .recent:
            return base.sorted { $0.latestEntry.date > $1.latestEntry.date }
        case .mostSets:
            return base.sorted {
                $0.logCount == $1.logCount
                    ? $0.name < $1.name
                    : $0.logCount > $1.logCount
            }
        case .name:
            return base.sorted { $0.name < $1.name }
        }
    }

    private var activeMuscles: [MuscleGroup] {
        let groups = Set(entries.compactMap(\.muscleGroup))
        return MuscleGroup.allCases.filter(groups.contains)
    }

    private var trainingDays: Int {
        Set(entries.map { Calendar.current.startOfDay(for: $0.date) }).count
    }

    private var monthSetCount: Int {
        entries.filter {
            Calendar.current.isDate($0.date, equalTo: .now, toGranularity: .month)
        }.count
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                header
                overviewCard
                trainingReviewCard
                if entries.isEmpty {
                    emptyState
                } else {
                    searchField
                    muscleFilters
                    sectionHeader
                    exerciseList
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 14)
            .padding(.bottom, 28)
        }
        .background(Color.paper)
        .sheet(isPresented: $showTrainingReview) {
            TrainingReviewView(
                entries: entries,
                bodyweight: profiles.first?.bodyweight ?? 0
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("PROGRESS")
                .sectionEyebrow()
            Text("BY EXERCISE")
                .editorialTitle(size: 48, lineSpacing: -4)
                .foregroundStyle(Color.ink)
            Text("Every set, record, and trend lives inside the exercise that created it.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.inkMuted)
                .padding(.top, 6)
        }
    }

    private var overviewCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("YOUR TRAINING RECORD")
                        .font(.system(size: 11, weight: .black))
                        .tracking(1.8)
                        .foregroundStyle(Color.signalPaper.opacity(0.62))
                    Text(entries.isEmpty ? "START WITH ONE SET" : "BUILT SET BY SET")
                        .font(.system(size: 25, weight: .black))
                        .fontWidth(.compressed)
                        .foregroundStyle(Color.signalPaper)
                }
                Spacer()
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 25, weight: .black))
                    .foregroundStyle(Color.signalOrange)
            }

            HStack(spacing: 0) {
                overviewStat(value: "\(LiftAnalytics.summaries(from: entries).count)", label: "EXERCISES")
                overviewDivider
                overviewStat(value: "\(entries.count)", label: "TOTAL SETS")
                overviewDivider
                overviewStat(value: "\(trainingDays)", label: "TRAINING DAYS")
                overviewDivider
                overviewStat(value: "\(monthSetCount)", label: "THIS MONTH")
            }
        }
        .padding(20)
        .background(Color.signalInk, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var trainingReviewCard: some View {
        Button {
            showTrainingReview = true
        } label: {
            HStack(spacing: 15) {
                Image(systemName: "sparkles")
                    .font(.system(size: 19, weight: .black))
                    .foregroundStyle(Color.signalInk)
                    .frame(width: 48, height: 48)
                    .background(Color.signalOrange, in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text("AI TRAINING REVIEW")
                        .font(.system(size: 17, weight: .black))
                        .fontWidth(.condensed)
                        .foregroundStyle(Color.ink)
                    Text(entries.isEmpty
                         ? "Available after your first set"
                         : "See what’s rising, stalled, or falling")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.inkMuted)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(Color.ink)
            }
            .padding(15)
            .cardStyle(cornerRadius: 18)
        }
        .buttonStyle(.plain)
        .disabled(entries.isEmpty)
        .opacity(entries.isEmpty ? 0.58 : 1)
        .accessibilityHint("Creates a private review from your recorded training data")
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.inkMuted)
            TextField("Search your exercises", text: $searchText)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.ink)
                .textInputAutocapitalization(.never)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.inkMuted)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(Color.paperRaised, in: RoundedRectangle(cornerRadius: 15))
        .overlay {
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }

    private var muscleFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterButton(title: "ALL", muscle: nil)
                ForEach(activeMuscles) { muscle in
                    filterButton(title: muscle.rawValue.uppercased(), muscle: muscle)
                }
            }
        }
        .contentMargins(.horizontal, 0)
    }

    private func filterButton(title: String, muscle: MuscleGroup?) -> some View {
        let isSelected = selectedMuscle == muscle
        return Button {
            withAnimation(.easeOut(duration: 0.18)) {
                selectedMuscle = muscle
            }
        } label: {
            Text(title)
                .font(.system(size: 10, weight: .black))
                .tracking(0.8)
                .foregroundStyle(isSelected ? Color.paper : Color.inkMuted)
                .padding(.horizontal, 14)
                .frame(height: 36)
                .background(isSelected ? Color.ink : Color.paperRaised, in: Capsule())
                .overlay {
                    if !isSelected {
                        Capsule().stroke(Color.hairline, lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var sectionHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("EXERCISE ANALYTICS")
                    .sectionEyebrow()
                Text("\(summaries.count) shown")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.inkMuted)
            }
            Spacer()
            Menu {
                Picker("Sort exercises", selection: $sortMode) {
                    ForEach(SortMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
            } label: {
                Label(sortMode.rawValue, systemImage: "arrow.up.arrow.down")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(Color.ink)
                    .padding(.horizontal, 12)
                    .frame(height: 36)
                    .background(Color.hairline.opacity(0.35), in: Capsule())
            }
        }
    }

    @ViewBuilder
    private var exerciseList: some View {
        if summaries.isEmpty {
            Text("No exercises match these filters.")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.inkMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 42)
        } else {
            LazyVStack(spacing: 12) {
                ForEach(summaries) { summary in
                    Button {
                        onExerciseTap(summary.name, summary.muscleGroup)
                    } label: {
                        ProgressExerciseCard(summary: summary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 13) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(Color.inkMuted)
            Text("No progress to chart yet")
                .font(.system(size: 22, weight: .black))
                .fontWidth(.condensed)
                .foregroundStyle(Color.ink)
            Text("Your first saved set creates an exercise dashboard automatically.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.inkMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
    }

    private func overviewStat(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 21, weight: .black))
                .fontWidth(.compressed)
                .foregroundStyle(Color.signalPaper)
            Text(label)
                .font(.system(size: 7.5, weight: .black))
                .tracking(0.6)
                .foregroundStyle(Color.signalPaper.opacity(0.55))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
    }

    private var overviewDivider: some View {
        Rectangle()
            .fill(Color.signalPaper.opacity(0.12))
            .frame(width: 1, height: 31)
    }
}

struct ProgressExerciseCard: View {
    let summary: ExerciseSummary

    private var trend: Double? {
        LiftAnalytics.recentTrendPercent(entries: summary.entries)
    }

    private var chartEntries: [LiftEntry] {
        Array(summary.entries.sorted { $0.date < $1.date }.suffix(12))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 13) {
                ExerciseIcon(muscleGroup: summary.muscleGroup, size: 48, inverted: true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(summary.name)
                        .font(.system(size: 19, weight: .black))
                        .fontWidth(.condensed)
                        .foregroundStyle(Color.ink)
                        .lineLimit(1)
                    Text("\(summary.logCount) sets · \(summary.trainingDays) training day\(summary.trainingDays == 1 ? "" : "s")")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.inkMuted)
                }
                Spacer()
                if let trend {
                    Text("\(trend >= 0 ? "+" : "")\(trend, format: .number.precision(.fractionLength(1)))%")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(trend > 0.5 ? Color.success : Color.inkMuted)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background((trend > 0.5 ? Color.success : Color.inkMuted).opacity(0.10), in: Capsule())
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(Color.inkFaint)
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("BEST SET")
                        .font(.system(size: 9, weight: .black))
                        .tracking(1)
                        .foregroundStyle(Color.signalOrange)
                    Text(setDescription(summary.bestEntry))
                        .font(.system(size: 18, weight: .black))
                        .fontWidth(.condensed)
                        .foregroundStyle(Color.ink)
                    Text("Est. max \(summary.bestE1RM.formattedWeight) lb")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.inkMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Chart(chartEntries, id: \.id) { entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Estimated max", entry.e1RM)
                    )
                    .foregroundStyle(Color.signalOrange)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    PointMark(
                        x: .value("Date", entry.date),
                        y: .value("Estimated max", entry.e1RM)
                    )
                    .foregroundStyle(Color.ink)
                    .symbolSize(13)
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(width: 104, height: 54)
                .accessibilityHidden(true)
            }
        }
        .padding(16)
        .cardStyle(cornerRadius: 18)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens detailed charts, records, and all sets")
    }

    private func setDescription(_ entry: LiftEntry) -> String {
        let side = entry.side == .both ? "" : "\(entry.side.shortLabel) · "
        let assistance = entry.loadType == .assistance ? " assist" : ""
        return "\(side)\(entry.weight.formattedWeight) lb\(assistance) × \(entry.reps)"
    }
}
