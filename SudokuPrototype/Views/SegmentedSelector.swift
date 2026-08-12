import SwiftUI

/// Shared "physical switch" segmented control — a single floating capsule
/// slides between equal-width options via `matchedGeometryEffect`, driven
/// by a spring. Used by the mode picker on the Start screen and the
/// Appearance picker in Settings so every "always selectable, N equal
/// options" picker in the app moves and feels identically. Callers own
/// what actually happens on selection (persistence, haptics, custom
/// transitions like ThemeManager's dim effect) via `onSelect`.
struct SegmentedSelector<Option: Hashable>: View {
    let options: [Option]
    let selection: Option
    let label: (Option) -> String
    let onSelect: (Option) -> Void

    @Environment(\.palette) private var palette
    @Namespace private var animation

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection
                Button {
                    onSelect(option)
                } label: {
                    Text(label(option))
                        .font(.subheadline.weight(isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? Color.white : Color.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            ZStack {
                                if isSelected {
                                    RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusSmall)
                                        .fill(palette.accent)
                                        .matchedGeometryEffect(id: "segment", in: animation)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium))
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: selection)
    }
}
