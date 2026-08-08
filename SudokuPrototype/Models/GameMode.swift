import Foundation

enum GameMode: String, CaseIterable, Codable, Identifiable, Equatable, Hashable {
    case classic, freestyle

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .freestyle: return "Freestyle"
        }
    }
}
