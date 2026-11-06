import SwiftUI

private let bg       = Color(red: 0.05, green: 0.05, blue: 0.06)
private let accent   = Color(red: 0.92, green: 0.46, blue: 0.18)  // Claude orange
private let barBg    = Color(red: 0.07, green: 0.07, blue: 0.08)

let barHeight: CGFloat = 54

struct ContentView: View {
    var body: some View {
        VStack(spacing: 0) {
            // The window decides the video's height: full size leaves a 16:9
            // area, mini mode shrinks the window to just the bar. The player is
            // never removed from the view tree, so the music keeps playing.
            YouTubePlayerView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // Drag the widget by the video; a click toggles play/pause
                // like it does on YouTube. The bar has the other controls.
                .overlay(WindowDragArea(onClick: { AppState.shared.togglePlayPause() }))

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
    @ObservedObject private var state = AppState.shared
    @State private var volumeExpanded = false

    private var appDelegate: AppDelegate? { NSApp.delegate as? AppDelegate }

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 10) {
                LiveBadge()

                Text("Claude FM")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .fixedSize()

                // Gives its room to the volume slider while that's open.
                if !volumeExpanded {
                    Text("·")
                        .foregroundColor(Color.white.opacity(0.25))

                    Text("music for thinking & building")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color.white.opacity(0.45))
                        .lineLimit(1)
                }
            }
            // Labels would otherwise catch the click, so grabbing the bar by
            // its text wouldn't drag; let it fall through to WindowDragArea.
            .allowsHitTesting(false)

            Spacer(minLength: 0)

            HStack(spacing: 4) {
                BarButton(
                    systemName: state.isPlaying ? "pause.fill" : "play.fill",
                    help: state.isPlaying ? "Pause" : "Play"
                ) { state.togglePlayPause() }

                VolumeControl(expanded: $volumeExpanded)
            }

            HStack(spacing: 4) {
                BarButton(
                    systemName: state.isMini ? "chevron.up" : "minus",
                    help: state.isMini ? "Show video" : "Mini player"
                ) { appDelegate?.toggleMini() }

                BarButton(systemName: "xmark", help: "Hide (click the Dock icon to bring it back)") {
                    appDelegate?.hideWindow()
                }
            }
        }
        .padding(.horizontal, 14)
        .frame(height: barHeight)
        .background(WindowDragArea())   // behind the buttons: drag from anywhere else on the bar
        .background(barBg)
    }
}

// MARK: - Volume

/// Speaker button (click to mute) with a slider that slides out on hover.
private struct VolumeControl: View {
    @ObservedObject private var state = AppState.shared
    @Binding var expanded: Bool

    private var icon: String {
        if state.isMuted || state.volume == 0 { return "speaker.slash.fill" }
        return state.volume < 0.5 ? "speaker.wave.1.fill" : "speaker.wave.2.fill"
    }

    var body: some View {
        // Slider sits to the left of the speaker so the button doesn't move
        // out from under the pointer when the slider appears.
        HStack(spacing: 6) {
            if expanded {
                Slider(
                    value: Binding(
                        get: { state.isMuted ? 0 : state.volume },
                        set: { state.setVolume($0) }
                    ),
                    in: 0...1
                )
                .controlSize(.mini)
                .tint(accent)
                .frame(width: 72)
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            }

            BarButton(systemName: icon, help: state.isMuted ? "Unmute" : "Mute") {
                state.toggleMute()
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) { expanded = hovering }
        }
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
        .fixedSize()
    }
}

// MARK: - Round icon button

private struct BarButton: View {
    let systemName: String
    let help: String
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(hovering ? .white : Color.white.opacity(0.5))
                .frame(width: 24, height: 24)
                .background(hovering ? Color.white.opacity(0.15) : Color.white.opacity(0.07))
                .clipShape(Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .help(help)
        .onHover { hovering = $0 }
        .animation(.easeInOut(duration: 0.15), value: hovering)
    }
}
