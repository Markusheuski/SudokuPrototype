import SwiftUI

struct SettingsView: View {
    @ObservedObject var theme: ThemeManager
    @ObservedObject var game: GameState
    @ObservedObject private var haptics = HapticManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss

    private var isDarkActive: Bool {
        colorScheme == .dark
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    themePreview
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                Section("Appearance") {
                    appearancePicker
                }

                Section {
                    themeCards
                } header: {
                    Text("Theme")
                } footer: {
                    if !isDarkActive {
                        Text("Available for dark theme")
                    }
                }
                .opacity(isDarkActive ? 1 : 0.4)
                .disabled(!isDarkActive)

                Section("Feedback") {
                    Toggle("Haptic feedback", isOn: $haptics.isEnabled)
                }

                #if DEBUG
                Section("Debug") {
                    Button("Reset All Data", role: .destructive) {
                        resetAllData()
                    }
                }
                #endif
            }
            .scrollContentBackground(.hidden)
            .background(palette.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .tint(palette.accent)
                }
            }
        }
    }

    private var appearancePicker: some View {
        HStack(spacing: 4) {
            ForEach(AppearanceMode.allCases) { mode in
                let isSelected = mode == theme.appearanceMode
                Button {
                    theme.setAppearanceMode(mode)
                } label: {
                    Text(mode.displayName)
                        .font(.subheadline.weight(isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? Color.white : Color.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            isSelected ? palette.accent : Color.clear,
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }

    private var themePreview: some View {
        let cells: [[MiniBoardPreview.Cell]] = [
            [.init(5, highlight: .selected), .init(0, highlight: .peer), .init(0, highlight: .peer)],
            [.init(0, highlight: .peer), .init(8), .init(0)],
            [.init(0, highlight: .peer), .init(0), .init(3, isAccent: true)]
        ]

        return MiniBoardPreview(cells: cells, palette: palette)
            .frame(width: 130, height: 130)
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(palette.background, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
    }

    private var themeCards: some View {
        HStack(spacing: 12) {
            ForEach(DarkVariant.allCases) { variant in
                themeCard(variant)
            }
        }
        .padding(.vertical, 4)
    }

    private func themeCard(_ variant: DarkVariant) -> some View {
        let isSelected = theme.selectedVariant == variant

        return Button {
            theme.setVariant(variant)
        } label: {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(variant.backgroundColor)
                        .frame(height: 56)
                        .overlay(
                            Circle()
                                .fill(variant.accentColor)
                                .frame(width: 20, height: 20)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? variant.accentColor : Color.clear, lineWidth: 2)
                        )

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(variant.accentColor)
                            .background(Circle().fill(Color.white))
                            .padding(4)
                    }
                }

                Text(variant.displayName)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
    }

    #if DEBUG
    private func resetAllData() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "sudoku.playerStats")
        defaults.removeObject(forKey: "sudoku.savedGame")
        defaults.removeObject(forKey: "appearanceMode")
        defaults.removeObject(forKey: "selectedTheme")
        defaults.removeObject(forKey: "hapticFeedbackEnabled")

        PlayerStats.shared.resetAll()
        theme.resetToDefaults()
        game.reset()
        HapticManager.shared.isEnabled = true
    }
    #endif
}

#Preview {
    SettingsView(theme: ThemeManager(), game: GameState())
}
