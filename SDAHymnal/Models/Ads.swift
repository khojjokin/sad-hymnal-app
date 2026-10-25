import SwiftUI
import UIKit
import GoogleMobileAds

/// Google AdMob ads, switched on and set up in the Qortn Console (SDA Hymnal › App settings › Ads).
/// Off until the console turns them on. Google's test units are used until real unit IDs are added there.
/// Free plan only: a single banner at the very end of a hymn, after the last verse. No full screen ads,
/// nothing on the splash, in sign in, or between verses, so worship is never interrupted.
@MainActor
final class Ads: ObservableObject {
    static let shared = Ads()

    private static let testBanner = "ca-app-pub-3940256099942544/2435281174"

    @Published private(set) var config = AdsConfig()
    @Published private(set) var ready = false

    private var started = false

    var bannerID: String { config.bannerID.isEmpty ? Self.testBanner : config.bannerID }
    var showsBanner: Bool { config.enabled && config.banner && ready && !Plus.shared.isPlus }

    /// Reads the console's settings (from the hymnal's public config).
    func apply(_ new: AdsConfig) {
        config = new
        if config.enabled { start() }
    }

    private func start() {
        guard !started else { return }
        started = true
        MobileAds.shared.start { _ in
            Task { @MainActor in Ads.shared.ready = true }
        }
    }

    static func topController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first { $0.activationState == .foregroundActive }
        var top = scene?.windows.first { $0.isKeyWindow }?.rootViewController
        while let next = top?.presentedViewController { top = next }
        return top
    }
}

/// A banner the width of the card it sits in.
private struct AdBannerView: UIViewRepresentable {
    let unitID: String
    let width: CGFloat

    func makeUIView(context: Context) -> BannerView {
        let view = BannerView(adSize: currentOrientationAnchoredAdaptiveBanner(width: width))
        view.adUnitID = unitID
        view.rootViewController = Ads.topController()
        view.load(Request())
        return view
    }

    func updateUIView(_ view: BannerView, context: Context) {}
}

/// A small sponsored card placed between sections. Shows nothing while ads are off.
struct AdCard: View {
    @ObservedObject private var ads = Ads.shared

    var body: some View {
        if ads.showsBanner {
            VStack(alignment: .leading, spacing: 6) {
                Text(t("ads.label")).font(.caption2.weight(.semibold)).textCase(.uppercase).tracking(0.8).foregroundStyle(Color.inkFaint)
                GeometryReader { geo in
                    AdBannerView(unitID: ads.bannerID, width: geo.size.width)
                }
                .frame(height: 60)
            }
            .padding(.horizontal, 20)
        }
    }
}
