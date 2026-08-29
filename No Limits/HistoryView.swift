import SwiftUI
import SwiftData

struct HistoryView: View {
    enum Mode: String, CaseIterable {
        case exercises = "Exercises"
        case timeline = "Timeline"
    }

    let onLogTap: () -> Void
    let onExerciseTap: (String, MuscleGroup) -> Void

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LiftEntry.date, order: .reverse) private var entries: [LiftEntry]
    @State private var mode: Mode = .exercises
    @State private var searchText = ""

    private var summaries: [ExerciseSummary] {
        LiftAnalytics.summaries(from: entries)
    }

    private var filteredSummaries: [ExerciseSummary] {
        guard !searchText.isEmpty else { return summaries }
        return summaries.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.muscleGroup.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredEntries: [LiftEntry] {
        guard !searchText.isEmpty else { return entries }
        return entries.filter {
            $0.liftType.localizedCaseInsensitiveContains(searchText)
                || ($0.muscleGroup?.rawValue.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 24)
                .padding(.top, 14)

            searchBar
                .padding(.horizontal, 24)
                .padding(.top, 20)

            modePicker
                .padding(.horizontal, 24)
                .padding(.top, 14)

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    if entries.isEmpty {
                        emptyState
                    } else if mode == .exercises {
                        exerciseList
                    } else {
                        timeline
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
        }
        .background(Color.paper)
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 1) {
                Text("YOUR")
                    .sectionEyebrow()
                Text("HISTORY")
                    .editorialTitle(size: 48, lineSpacing: -4)
                    .foregroundStyle(Color.ink)
            }
            Spacer()
            Button(action: onLogTap) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(Color.white)
                    .frame(width: 48, height: 48)
                    .background(Color.signalOrange, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Log a lift")
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.inkMuted)
            TextField("Find an exercise", text: $searchText)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.ink)
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.inkFaint)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(Color.paperRaised, in: RoundedRectangle(cornerRadius: 15))
        .overlay {
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }

    private var modePicker: some View {
        HStack(spacing: 4) {
            ForEach(Mode.allCases, id: \.self) { item in
                Button {
                    withAnimation(.easeOut(duration: 0.2)) { mode = item }
                } label: {
                    Text(item.rawValue.uppercased())
                        .font(.system(size: 12, weight: .black))
                        .fontWidth(.condensed)
                        .tracking(1)
                        .foregroundStyle(mode == item ? Color.paper : Color.inkMuted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(mode == item ? Color.ink : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 11))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.hairline.opacity(0.34), in: RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private var exerciseList: some View {
        if filteredSummaries.isEmpty {
            noResults
        } else {
            ForEach(filteredSummaries) { summary in
                Button {
                    onExerciseTap(summary.name, summary.muscleGroup)
                } label: {
                    ExerciseHistoryCard(summary: summary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var timeline: some View {
        if filteredEntries.isEmpty {
            noResults
        } else {
            ForEach(filteredEntries, id: \.id) { entry in
                TimelineLiftRow(entry: entry) {
                    AppStatsSynchronizer.delete(entry, context: modelContext)
                } onOpen: {
                    guard let muscle = entry.muscleGroup else { return }
                    onExerciseTap(entry.liftType, muscle)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "list.clipboard")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(Color.inkMuted)
            Text("Nothing logged yet")
                .font(.system(size: 23, weight: .black))
                .fontWidth(.condensed)
                .foregroundStyle(Color.ink)
            Text("Your exercise history and personal bests will collect here.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.inkMuted)
                .multilineTextAlignment(.center)
            Button("LOG YOUR FIRST LIFT", action: onLogTap)
                .font(.system(size: 15, weight: .black))
                .fontWidth(.condensed)
                .foregroundStyle(Color.white)
                .padding(.horizontal, 20)
                .frame(height: 48)
                .background(Color.signalOrange, in: RoundedRectangle(cornerRadius: 14))
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 72)
    }

    private var noResults: some View {
        Text("No exercises match “\(searchText)”.")
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Color.inkMuted)
            .frame(maxWidth: .infinity)
            .padding(.top, 44)
    }
}

struct ExerciseHistoryCard: View {
    let summary: ExerciseSummary

    var body: some View {
        HStack(spacing: 14) {
            ExerciseIcon(muscleGroup: summary.muscleGroup, size: 52, inverted: true)

            VStack(alignment: .leading, spacing: 5) {
                Text(summary.name)
                    .font(.system(size: 19, weight: .black))
                    .fontWidth(.condensed)
                    .foregroundStyle(Color.ink)
                    .lineLimit(1)

                Text(latestDescription)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.inkMuted)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                Text("PB")
                    .font(.system(size: 10, weight: .black))
                    .tracking(1.4)
                    .foregroundStyle(Color.signalOrange)
                Text(bestDescription)
                    .font(.system(size: 17, weight: .black))
                    .fontWidth(.condensed)
                    .foregroundStyle(Color.ink)
                Text("\(summary.logCount) log\(summary.logCount == 1 ? "" : "s")")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.inkMuted)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(Color.inkFaint)
        }
        .padding(15)
        .cardStyle(cornerRadius: 18)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Shows all \(summary.name) stats and logs")
    }

    private var latestDescription: String {
        let entry = summary.latestEntry
        let side = entry.side == .both ? "" : "\(entry.side.shortLabel) · "
        let load = entry.loadType == .assistance
            ? "\(entry.weight.formattedWeight) lb assist"
            : "\(entry.weight.formattedWeight) lb"
        return "Latest  \(side)\(load) × \(entry.reps)"
    }

    private var bestDescription: String {
        let entry = summary.bestEntry
        let side = entry.side == .both ? "" : "\(entry.side.shortLabel) · "
        return "\(side)\(entry.weight.formattedWeight) × \(entry.reps)"
    }
}

struct TimelineLiftRow: View {
    let entry: LiftEntry
    let onDelete: () -> Void
    let onOpen: () -> Void

    var body: some View {
        HStack(spacing: 13) {
            ExerciseIcon(muscleGroup: entry.muscleGroup ?? .legs, size: 46)

            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.liftType)
                        .font(.system(size: 17, weight: .black))
                        .fontWidth(.condensed)
                        .foregroundStyle(Color.ink)
                    Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.inkMuted)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            HStack(spacing: 7) {
                if entry.side != .both {
                    Text(entry.side.shortLabel)
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(Color.ink)
                        .frame(width: 24, height: 24)
                        .background(Color.hairline.opacity(0.55), in: Circle())
                }
                Text(loadDescription)
                    .font(.system(size: 17, weight: .black))
                    .fontWidth(.condensed)
                    .foregroundStyle(Color.ink)
            }

            Menu {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete log", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.inkMuted)
                    .frame(width: 30, height: 40)
            }
        }
        .padding(14)
        .cardStyle(cornerRadius: 16)
    }

    private var loadDescription: String {
        let suffix = entry.loadType == .assistance ? " assist" : ""
        return "\(entry.weight.formattedWeight) lb\(suffix) × \(entry.reps)"
    }
}
