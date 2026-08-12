import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable, Equatable, Hashable {
    case light, dark, system

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

enum DarkVariant: String, CaseIterable, Identifiable, Equatable {
    case graphite, charcoal, navy

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .graphite: return "Graphite"
        case .charcoal: return "Warm Charcoal"
        case .navy: return "Deep Blue"
        }
    }

    var backgroundColor: Color {
        switch self {
        case .graphite: return Color(hex: "1C1C1E")
        case .charcoal: return Color(hex: "242220")
        case .navy: return Color(hex: "151B24")
        }
    }

    var accentColor: Color {
        switch self {
        case .graphite: return Color(hex: "5B9BD5")
        case .charcoal: return Color(hex: "D99A44")
        case .navy: return Color(hex: "4FBFA8")
        }
    }

    var givenColor: Color {
        switch self {
        case .graphite: return Color(hex: "9B9BA1")
        case .charcoal: return Color(hex: "A69C8E")
        case .navy: return Color(hex: "9B9BA1")
        }
    }

    /// A shade lighter than backgroundColor, for cards/panels that should
    /// read as sitting above the screen background.
    var surfaceElevatedColor: Color {
        switch self {
        case .graphite: return Color(hex: "2C2C2E")
        case .charcoal: return Color(hex: "322F2B")
        case .navy: return Color(hex: "202836")
        }
    }
}

struct Palette: Equatable {
    let background: Color
    let accent: Color
    let given: Color
    let surfaceElevated: Color
    let border: Color

    static let light = Palette(
        background: Color(hex: "F5F5F7"),
        accent: .blue,
        given: Color(hex: "3A3A3C"),
        surfaceElevated: Color.white,
        border: Color.black.opacity(0.08)
    )

    static func dark(for variant: DarkVariant) -> Palette {
        Palette(
            background: variant.backgroundColor,
            accent: variant.accentColor,
            given: variant.givenColor,
            surfaceElevated: variant.surfaceElevatedColor,
            border: Color.white.opacity(0.08)
        )
    }
}

private struct PaletteKey: EnvironmentKey {
    static let defaultValue = Palette.light
}

extension EnvironmentValues {
    var palette: Palette {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue }
    }
}

extension Color {
    init(hex: String) {
        let sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&rgb)
        let r = Double((rgb & 0xFF0000) >> 16) / 255
        let g = Double((rgb & 0x00FF00) >> 8) / 255
        let b = Double(rgb & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
