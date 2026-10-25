import SwiftUI

/// Decides when the splash shows: on a fresh launch, and when someone comes back after 10 minutes or more away.
/// The app's screens never show before it.
@MainActor
final class SplashGate: ObservableObject {
    @Published var showing = true
    private var leftAt: Date?
    static let awayLimit: TimeInterval = 10 * 60

    func finish() { withAnimation(.easeOut(duration: 0.45)) { showing = false } }

    func phaseChanged(_ phase: ScenePhase) {
        switch phase {
        case .background:
            leftAt = Date()
        case .active:
            if let leftAt, Date().timeIntervalSince(leftAt) >= SplashGate.awayLimit, !showing {
                showing = true
            }
            leftAt = nil
        default: break
        }
    }
}

struct SplashView: View {
    var onFinish: () -> Void
    @State private var appear = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            RadialGradient(colors: [Color(hex: "0B6F9F").opacity(0.55), .clear], center: .center, startRadius: 10, endRadius: 360)
                .ignoresSafeArea()
                .opacity(appear ? 1 : 0)
            VStack(spacing: 18) {
                Spacer()
                SDALogo(size: 92)
                    .scaleEffect(appear ? 1 : 0.86)
                    .opacity(appear ? 1 : 0)
                VStack(spacing: 6) {
                    Text("SDA Hymnal").font(.serif(34, .semibold)).foregroundStyle(.white).lineLimit(1)
                    Text(t("splash.tagline")).font(.serif(16).italic()).foregroundStyle(.white.opacity(0.7)).lineLimit(1)
                }
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 8)
                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .preferredColorScheme(.dark)
        .task {
            withAnimation(.easeOut(duration: 0.7)) { appear = true }
            try? await Task.sleep(for: .seconds(1.6))
            onFinish()
        }
    }
}
