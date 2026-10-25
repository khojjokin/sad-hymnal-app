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
                    .padding(.vertical, 70)
                    .id(index)
                    .transition(.opacity)
                tapZones
                chromeView.opacity(chrome ? 1 : 0)
                // The way out is always there, even when the rest hides.
                if !chrome { quietClose }
            }
            .gesture(DragGesture(minimumDistance: 30).onEnded { v in
                if v.translation.height > 120 && abs(v.translation.width) < 80 { dismiss(); return }
                if abs(v.translation.width) > 40 { go(v.translation.width < 0 ? 1 : -1) }
            })
        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            hideSoon()
        }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = Prefs.shared.keepAwake }
    }

    private func hideSoon() {
        Task {
            try? await Task.sleep(for: .seconds(4))
            withAnimation(.easeOut(duration: 0.4)) { chrome = false }
        }
    }

    private func showChrome() {
        withAnimation(.easeOut(duration: 0.25)) { chrome = true }
        hideSoon()
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

    /// Tap the left side to go back, the right side to go on, the middle to show the controls.
    private var tapZones: some View {
        HStack(spacing: 0) {
            Color.clear.contentShape(Rectangle()).onTapGesture { go(-1) }
            Color.clear.contentShape(Rectangle()).onTapGesture { if chrome { withAnimation { chrome = false } } else { showChrome() } }
            Color.clear.contentShape(Rectangle()).onTapGesture { go(1) }
        }
    }

    /// A faint close button that stays while the controls are hidden.
    private var quietClose: some View {
        VStack {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 14, weight: .bold)).foregroundStyle(.white.opacity(0.6))
                        .frame(width: 40, height: 40).background(Color.white.opacity(0.08), in: Circle())
                }
                .accessibilityLabel(t("common.close"))
                Spacer()
            }
            Spacer()
        }
        .padding(18)
    }

    private var chromeView: some View {
        VStack {
            HStack(spacing: 12) {
                Button { dismiss() } label: {
                    Label(t("common.back"), systemImage: "chevron.left")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                        .padding(.horizontal, 14).frame(height: 40).glass(20)
                }
                .accessibilityLabel(t("common.close"))
                Text("\(hymn.number) · \(hymn.title)").font(.footnote.weight(.semibold)).foregroundStyle(.white.opacity(0.7)).lineLimit(1)
                Spacer()
                AirPlayButton().frame(width: 40, height: 40).glassCircle()
            }
            Spacer()
            HStack(spacing: 14) {
                Button { go(-1) } label: {
                    Image(systemName: "chevron.left").font(.system(size: 18, weight: .bold)).foregroundStyle(.white)
                        .frame(width: 52, height: 52).glassCircle()
                }
                .disabled(index == 0).opacity(index == 0 ? 0.4 : 1)
                .accessibilityLabel(t("hymn.previous"))
                VStack(spacing: 2) {
                    Text(current.label).font(.footnote.weight(.semibold)).foregroundStyle(.white.opacity(0.8)).lineLimit(1)
                    Text("\(index + 1) / \(slides.count)").font(.caption.monospacedDigit()).foregroundStyle(.white.opacity(0.55))
                }
                .frame(minWidth: 90)
                Button { go(1) } label: {
                    Image(systemName: "chevron.right").font(.system(size: 18, weight: .bold)).foregroundStyle(.white)
                        .frame(width: 52, height: 52).glassCircle()
                }
                .disabled(index >= slides.count - 1).opacity(index >= slides.count - 1 ? 0.4 : 1)
                .accessibilityLabel(t("hymn.next"))
            }
        }
        .padding(18)
        .allowsHitTesting(chrome)
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
