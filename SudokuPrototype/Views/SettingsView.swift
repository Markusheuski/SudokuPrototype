import SwiftUI

struct SettingsView: View {
    @ObservedObject var theme: ThemeManager
    @ObservedObject var game: GameState
    @ObservedObject private var haptics = HapticManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss
    @State private var showResetStatsConfirmation = false

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

                Section {
                    Button("Reset Statistics", role: .destructive) {
                        showResetStatsConfirmation = true
                    }
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
            .confirmationDialog(
                "Reset Statistics?",
                isPresented: $showResetStatsConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    PlayerStats.shared.resetAll()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete your stats, streaks, and unlocked difficulties. This can't be undone.")
            }
        }
    }

    private var appearancePicker: some View {
        SegmentedSelector(options: AppearanceMode.allCases, selection: theme.appearanceMode) { mode in
            mode.displayName
        } onSelect: { mode in
            theme.setAppearanceMode(mode)
        }
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
            .background(palette.background, in: RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusLarge))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusLarge)
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
                    RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium)
                        .fill(variant.backgroundColor)
                        .frame(height: 56)
                        .shadow(color: Color.black.opacity(0.18), radius: 8, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium)
                                .fill(palette.accent.opacity(isSelected ? 0.12 : 0))
                        )
                        .overlay(
                            Circle()
                                .fill(variant.accentColor)
                                .frame(width: 20, height: 20)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium)
                                .stroke(variant.accentColor.opacity(isSelected ? 1 : 0.4), lineWidth: isSelected ? 2 : 1)
                        )

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(variant.accentColor)
                            .background(Circle().fill(Color.white))
                            .padding(4)
                            .transition(.scale.combined(with: .opacity))
                    }
                }

                Text(variant.displayName)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: theme.selectedVariant)
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
