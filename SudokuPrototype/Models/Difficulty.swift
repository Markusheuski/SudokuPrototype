import Foundation

enum Difficulty: String, CaseIterable, Codable, Identifiable, Equatable, Hashable {
    case easy, medium, hard, expert

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .expert: return "Expert"
        }
    }

    var clueCount: Int {
        switch self {
        case .easy: return 45
        case .medium: return 32
        case .hard: return 28
        case .expert: return 24
        }
    }

    var maxMistakes: Int {
        switch self {
        case .easy: return 3
        case .medium, .hard, .expert: return 2
        }
    }

    var next: Difficulty? {
        switch self {
        case .easy: return nil
        case .medium: return .hard
        case .hard: return .expert
        case .expert: return nil
        }
    }

    var previous: Difficulty? {
        switch self {
        case .easy: return nil
        case .medium: return .easy
        case .hard: return .medium
        case .expert: return .hard
        }
    }
}
