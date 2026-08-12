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

    /// The dim-to-black-and-back hides the moment the actual switch happens
    /// (colorScheme changes aren't reliably animatable by SwiftUI on their
    /// own), but the underlying value change itself is *also* wrapped in
    /// `withAnimation` so any view reading the resulting `Palette` colors
    /// cross-fades instead of snapping, rather than relying solely on the
    /// dim overlay to mask an instant jump.
    private func transition(_ change: @escaping () -> Void) {
        withAnimation(.easeInOut(duration: 0.15)) {
            isDimmed = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            withAnimation(.easeInOut(duration: 0.25)) {
                change()
            }
            withAnimation(.easeInOut(duration: 0.3)) {
                self?.isDimmed = false
            }
        }
    }
}
