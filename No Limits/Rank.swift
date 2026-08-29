import Foundation

enum Rank: String, CaseIterable, Equatable, Codable {
    case iron = "Iron"
    case bronze = "Bronze"
    case silver = "Silver"
    case gold = "Gold"
    case platinum = "Platinum"
    case diamond = "Diamond"
    case titan = "Titan"

    var lowerBound: Double {
        switch self {
        case .iron: return 0
        case .bronze: return 0.60
        case .silver: return 0.80
        case .gold: return 1.00
        case .platinum: return 1.20
        case .diamond: return 1.40
        case .titan: return 1.60
        }
    }

    var upperBound: Double {
        switch self {
        case .iron: return 0.60
        case .bronze: return 0.80
        case .silver: return 1.00
        case .gold: return 1.20
        case .platinum: return 1.40
        case .diamond: return 1.60
        case .titan: return 1.60
        }
    }

    var nextRank: Rank? {
        guard let index = Rank.allCases.firstIndex(of: self),
              index < Rank.allCases.count - 1 else {
            return nil
        }
        return Rank.allCases[index + 1]
    }

    static func fromScore(_ score: Double) -> Rank {
        Rank.allCases.reversed().first { score >= $0.lowerBound } ?? .iron
    }
}
