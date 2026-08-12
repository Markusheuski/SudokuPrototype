import SwiftUI

/// Experimental Liquid Glass variant of `SegmentedSelector`, isolated to
/// the stats Profile screen's Classic/Freestyle switcher only — a testbed
/// to see how a glass material reads against the rest of the app's flat +
/// accent-glow language before deciding whether to roll it out anywhere
/// else. Everything except the active capsule's material (position spring
/// via `matchedGeometryEffect`, haptic via the caller's `onSelect`) is
/// identical to `SegmentedSelector`. Deliberately a separate type rather
/// than a flag on `SegmentedSelector` so the other three usages (Start
/// screen's difficulty/mode pickers, Settings' Appearance picker) can't be
/// affected by this experiment.
struct SegmentedSelectorGlass<Option: Hashable>: View {
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
                                    activeCapsule
                                        .matchedGeometryEffect(id: "segmentGlass", in: animation)
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

    @ViewBuilder
    private var activeCapsule: some View {
        if #available(iOS 26, *) {
            Capsule()
                .fill(Color.clear)
                .glassEffect(.regular.tint(palette.accent), in: .capsule, isEnabled: true)
        } else {
            RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusSmall)
                .fill(palette.accent)
                .shadow(color: palette.accent.opacity(0.3), radius: 8, y: 3)
        }
    }
}
