import SwiftUI

private let bg       = Color(red: 0.05, green: 0.05, blue: 0.06)
private let accent   = Color(red: 0.92, green: 0.46, blue: 0.18)  // Claude orange
private let barBg    = Color(red: 0.07, green: 0.07, blue: 0.08)

struct ContentView: View {
    var body: some View {
        VStack(spacing: 0) {
            YouTubePlayerView()
                .aspectRatio(16 / 9, contentMode: .fit)
                .frame(maxWidth: .infinity)

            BottomBar()
        }
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
        )
    }
}

// MARK: - Bottom bar

private struct BottomBar: View {
    var body: some View {
        HStack(spacing: 10) {
            LiveBadge()

            Text("Claude FM")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)

            Text("·")
                .foregroundColor(Color.white.opacity(0.25))

            Text("music for thinking & building")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(Color.white.opacity(0.45))
                .lineLimit(1)

            Spacer()

            CloseButton()
        }
        .padding(.horizontal, 14)
        .frame(height: 54)
        .background(barBg)
    }
}

// MARK: - Animated live badge

private struct LiveBadge: View {
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 5) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.35))
                    .frame(width: 13, height: 13)
                    .scaleEffect(pulse ? 1.6 : 1.0)
                    .opacity(pulse ? 0 : 0.8)
                Circle()
                    .fill(Color.red)
                    .frame(width: 7, height: 7)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) {
                    pulse = true
                }
            }

            Text("LIVE")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.red)
                .tracking(0.5)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(Color.red.opacity(0.1))
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(Color.red.opacity(0.3), lineWidth: 0.5))
    }
}

// MARK: - Close button

private struct CloseButton: View {
    @State private var hovering = false

    var body: some View {
        Button {
            AppState.shared.pauseVideo()
            NSApplication.shared.keyWindow?.orderOut(nil)
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(hovering ? .white : Color.white.opacity(0.5))
                .frame(width: 24, height: 24)
                .background(hovering ? Color.white.opacity(0.15) : Color.white.opacity(0.07))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(.easeInOut(duration: 0.15), value: hovering)
    }
}
