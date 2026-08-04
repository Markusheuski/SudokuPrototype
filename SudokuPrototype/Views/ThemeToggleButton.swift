import SwiftUI

struct ThemeToggleButton: View {
    @ObservedObject var theme: ThemeManager

    var body: some View {
        Button {
            theme.toggle()
        } label: {
            ZStack {
                Image(systemName: "sun.max.fill")
                    .opacity(theme.isDarkMode ? 0 : 1)
                    .rotationEffect(.degrees(theme.isDarkMode ? -90 : 0))
                Image(systemName: "moon.fill")
                    .opacity(theme.isDarkMode ? 1 : 0)
                    .rotationEffect(.degrees(theme.isDarkMode ? 0 : 90))
            }
            .font(.title2)
            .foregroundStyle(theme.isDarkMode ? .yellow : .orange)
            .frame(width: 44, height: 44)
        }
    }
}
