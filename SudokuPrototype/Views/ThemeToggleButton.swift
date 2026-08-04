import SwiftUI

struct ThemeToggleButton: View {
    @ObservedObject var theme: ThemeManager

    private let width: CGFloat = 56
    private let height: CGFloat = 30

    var body: some View {
        Button {
            theme.toggle()
        } label: {
            ZStack(alignment: theme.isDarkMode ? .trailing : .leading) {
                Capsule()
                    .fill(theme.isDarkMode ? Color(white: 0.15) : Color.yellow.opacity(0.35))

                Circle()
                    .fill(Color.white)
                    .overlay(
                        Image(systemName: theme.isDarkMode ? "moon.fill" : "sun.max.fill")
                            .font(.system(size: (height - 6) * 0.55))
                            .foregroundStyle(theme.isDarkMode ? Color.indigo : Color.orange)
                    )
                    .padding(3)
            }
            .frame(width: width, height: height)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.35), value: theme.isDarkMode)
    }
}
