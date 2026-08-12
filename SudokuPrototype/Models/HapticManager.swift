import UIKit

final class HapticManager: ObservableObject {
    static let shared = HapticManager()

    private static let storageKey = "hapticFeedbackEnabled"

    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Self.storageKey)
        }
    }

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let softImpact = UIImpactFeedbackGenerator(style: .soft)
    private let notification = UINotificationFeedbackGenerator()

    private init() {
        if UserDefaults.standard.object(forKey: Self.storageKey) == nil {
            isEnabled = true
        } else {
            isEnabled = UserDefaults.standard.bool(forKey: Self.storageKey)
        }
    }

    func cellSelected() {
        guard isEnabled else { return }
        softImpact.impactOccurred()
        // Selecting a cell usually precedes a digit entry, so warm up
        // the generators most likely to fire next.
        lightImpact.prepare()
        notification.prepare()
    }

    func correctEntry() {
        guard isEnabled else { return }
        lightImpact.impactOccurred()
    }

    func wrongEntry() {
        guard isEnabled else { return }
        notification.notificationOccurred(.error)
    }

    func pencilModeToggled() {
        guard isEnabled else { return }
        lightImpact.impactOccurred()
    }

    func selectionChanged() {
        guard isEnabled else { return }
        lightImpact.impactOccurred()
    }

    func win() {
        guard isEnabled else { return }
        notification.notificationOccurred(.success)
    }

    func gameOver() {
        guard isEnabled else { return }
        notification.notificationOccurred(.error)
    }
}
