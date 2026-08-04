import Foundation

enum Difficulty: String, CaseIterable, Codable, Identifiable, Equatable {
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
        case .easy: return 40
        case .medium: return 32
        case .hard: return 28
        case .expert: return 24
        }
    }
}
