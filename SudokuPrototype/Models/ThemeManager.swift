import SwiftUI

final class ThemeManager: ObservableObject {
    @Published var appearanceMode: AppearanceMode {
        didSet {
            UserDefaults.standard.set(appearanceMode.rawValue, forKey: "appearanceMode")
        }
    }
    @Published var selectedVariant: DarkVariant {
        didSet {
            UserDefaults.standard.set(selectedVariant.rawValue, forKey: "selectedTheme")
        }
    }
    @Published var isDimmed = false

    init() {
        if let raw = UserDefaults.standard.string(forKey: "appearanceMode"),
           let mode = AppearanceMode(rawValue: raw) {
            appearanceMode = mode
        } else {
            appearanceMode = .system
        }
        if let raw = UserDefaults.standard.string(forKey: "selectedTheme"),
           let variant = DarkVariant(rawValue: raw) {
            selectedVariant = variant
        } else {
            selectedVariant = .graphite
        }
    }

    func setAppearanceMode(_ mode: AppearanceMode) {
        guard mode != appearanceMode else { return }
        HapticManager.shared.selectionChanged()
        transition { self.appearanceMode = mode }
    }

    func setVariant(_ variant: DarkVariant) {
        guard variant != selectedVariant else { return }
        HapticManager.shared.selectionChanged()
        transition { self.selectedVariant = variant }
    }

    #if DEBUG
    func resetToDefaults() {
        appearanceMode = .system
        selectedVariant = .graphite
        isDimmed = false
    }
    #endif

    private func transition(_ change: @escaping () -> Void) {
        withAnimation(.easeInOut(duration: 0.15)) {
            isDimmed = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            change()
            withAnimation(.easeInOut(duration: 0.3)) {
                self?.isDimmed = false
            }
        }
    }
}
