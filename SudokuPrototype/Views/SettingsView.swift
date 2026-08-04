import SwiftUI

struct SettingsView: View {
    @ObservedObject var theme: ThemeManager
    @ObservedObject private var haptics = HapticManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    private var isDarkActive: Bool {
        colorScheme == .dark
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Appearance", selection: Binding(
                        get: { theme.appearanceMode },
                        set: { theme.setAppearanceMode($0) }
                    )) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
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
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
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
}

#Preview {
    SettingsView(theme: ThemeManager())
}
