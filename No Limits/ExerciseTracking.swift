import Foundation

enum ExerciseLoadType: String, CaseIterable, Codable, Identifiable {
    case externalWeight = "External weight"
    case assistance = "Assistance"

    var id: String { rawValue }

    var inputLabel: String {
        switch self {
        case .externalWeight: return "WEIGHT"
        case .assistance: return "ASSISTANCE"
        }
    }

    var metricLabel: String {
        switch self {
        case .externalWeight: return "ESTIMATED 1 REP MAX"
        case .assistance: return "ESTIMATED EFFECTIVE MAX"
        }
    }

    var guidance: String {
        switch self {
        case .externalWeight:
            return "More weight or reps improves your performance."
        case .assistance:
            return "Lower assistance is harder and counts as improvement."
        }
    }
}

enum ExerciseSideTracking: String, CaseIterable, Codable, Identifiable {
    case combined = "Combined"
    case separate = "Left & right"

    var id: String { rawValue }
}

enum ExerciseSide: String, CaseIterable, Codable, Identifiable {
    case both = "Both"
    case left = "Left"
    case right = "Right"

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .both: return "BOTH"
        case .left: return "L"
        case .right: return "R"
        }
    }
}

struct PerformanceService {
    static func estimatedMax(
        weight: Double,
        reps: Int,
        bodyweight: Double,
        loadType: ExerciseLoadType
    ) -> Double {
        guard weight >= 0, reps > 0 else { return 0 }

        let workingLoad: Double
        switch loadType {
        case .externalWeight:
            guard weight > 0 else { return 0 }
            workingLoad = weight
        case .assistance:
            guard bodyweight > 0 else { return 0 }
            workingLoad = max(bodyweight - weight, 0)
        }

        return workingLoad * (1 + Double(reps) / 30)
    }

    static func isPersonalBest(
        candidate: Double,
        previousBest: Double
    ) -> Bool {
        previousBest > 0 && candidate > previousBest
    }

    static func trainingVolume(
        weight: Double,
        reps: Int,
        bodyweight: Double,
        loadType: ExerciseLoadType
    ) -> Double {
        guard reps > 0 else { return 0 }
        switch loadType {
        case .externalWeight:
            return max(weight, 0) * Double(reps)
        case .assistance:
            return max(bodyweight - weight, 0) * Double(reps)
        }
    }
}

extension Double {
    var formattedWeight: String {
        rounded() == self
            ? String(Int(self))
            : formatted(.number.precision(.fractionLength(1)))
    }
}
