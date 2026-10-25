import SwiftUI
import AVKit

/// Plus: Projector mode. One verse at a time in big type on black, for a TV or projector (AirPlay or a cable
/// mirrors it). Tap the right side or swipe for the next verse, the left side to go back.
struct ProjectorView: View {
    let hymn: Hymn
    @Environment(\.dismiss) private var dismiss
    @State private var index = 0
    @State private var chrome = true

    private struct Slide {
        let label: String
        let text: String
    }

    private var slides: [Slide] {
        var out = [Slide(label: "\(hymn.number)", text: hymn.title)]
        for v in HymnBook.shared.verses(of: hymn) {
            let label = v.isRefrain ? t("card.refrain") : t("card.verseN", ["n": v.number])
            out.append(Slide(label: label, text: v.text))
        }
        return out
    }

    var body: some View {
        GeometryReader { geo in
            let side: CGFloat = min(geo.size.width, geo.size.height)
            ZStack {
                Color.black.ignoresSafeArea()
                slideView(side: side)
                    .padding(.horizontal, geo.size.width * 0.07)
                    .padding(.vertical, 40)
                    .id(index)
                    .transition(.opacity)
                tapZones
                if chrome { chromeView.transition(.opacity) }
            }
            .gesture(DragGesture(minimumDistance: 30).onEnded { v in go(v.translation.width < 0 ? 1 : -1) })
        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            Task { try? await Task.sleep(for: .seconds(3)); withAnimation { chrome = false } }
        }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = Prefs.shared.keepAwake }
        .onLongPressGesture { withAnimation { chrome.toggle() } }
    }

    private var current: Slide {
        let all = slides
        return all[min(index, all.count - 1)]
    }

    @ViewBuilder private func slideView(side: CGFloat) -> some View {
        let slide = current
        if index == 0 {
            VStack(spacing: 22) {
                Text(slide.label).font(.serif(side * 0.16, .semibold)).foregroundStyle(Color(hex: "3AAEE6"))
                Text(slide.text).font(.serif(side * 0.08, .semibold))
                    .foregroundStyle(.white).multilineTextAlignment(.center)
                    .minimumScaleFactor(0.4)
                if !hymn.author.isEmpty {
                    Text(hymn.author).font(.serif(18).italic()).foregroundStyle(.white.opacity(0.6)).lineLimit(1)
                }
            }
        } else {
            Text(slide.text)
                .font(.serif(side * 0.075))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(10)
                .minimumScaleFactor(0.35)
        }
    }

    /// Tap left to go back, right to go on.
    private var tapZones: some View {
        HStack(spacing: 0) {
            Color.clear.contentShape(Rectangle()).onTapGesture { go(-1) }
            Color.clear.contentShape(Rectangle()).onTapGesture { go(1) }
        }
    }

    private var chromeView: some View {
        VStack {
            HStack(spacing: 12) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                        .frame(width: 40, height: 40).glassCircle()
                }
                .accessibilityLabel(t("common.close"))
                Text("\(hymn.number) · \(hymn.title)").font(.footnote.weight(.semibold)).foregroundStyle(.white.opacity(0.7)).lineLimit(1)
                Spacer()
                AirPlayButton().frame(width: 40, height: 40).glassCircle()
            }
            Spacer()
            HStack {
                Text(current.label).font(.footnote.weight(.semibold)).foregroundStyle(.white.opacity(0.6))
                Spacer()
                Text("\(index + 1) / \(slides.count)").font(.footnote.monospacedDigit()).foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(18)
    }

    private func go(_ by: Int) {
        let next = index + by
        guard next >= 0, next < slides.count else { return }
        UISelectionFeedbackGenerator().selectionChanged()
        withAnimation(.easeInOut(duration: 0.35)) { index = next }
    }
}

/// The system AirPlay picker, so the hymn can go to a TV.
struct AirPlayButton: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let v = AVRoutePickerView()
        v.tintColor = .white
        v.activeTintColor = UIColor(red: 0.23, green: 0.68, blue: 0.9, alpha: 1)
        v.prioritizesVideoDevices = true
        return v
    }
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}
