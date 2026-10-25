import SwiftUI
import UIKit
import GoogleMobileAds

/// Google AdMob ads, switched on and set up in the Qortn Console (SDA Hymnal › App settings › Ads).
/// Off until the console turns them on. Google's test units are used until real unit IDs are added there.
/// Ads never show on the splash, in sign in, or while someone is in the middle of a hymn.
@MainActor
final class Ads: ObservableObject {
    static let shared = Ads()

    private static let testBanner = "ca-app-pub-3940256099942544/2435281174"
    private static let testInterstitial = "ca-app-pub-3940256099942544/4411468910"

    @Published private(set) var config = AdsConfig()
    @Published private(set) var ready = false

    private var started = false
    private var interstitial: InterstitialAd?
    private var loading = false
    private var lastShown: Date?
    private var closedSinceLast = 0

    var bannerID: String { config.bannerID.isEmpty ? Self.testBanner : config.bannerID }
    private var interstitialID: String { config.interstitialID.isEmpty ? Self.testInterstitial : config.interstitialID }
    var showsBanner: Bool { config.enabled && config.banner && ready }

    /// Reads the console's settings (from the hymnal's public config).
    func apply(_ new: AdsConfig) {
        if new.interstitialID != config.interstitialID { interstitial = nil }
        config = new
        if config.enabled { start() }
    }

    private func start() {
        guard !started else { preload(); return }
        started = true
        MobileAds.shared.start { _ in
            Task { @MainActor in
                Ads.shared.ready = true
                Ads.shared.preload()
            }
        }
    }

    private func preload() {
        guard config.enabled, config.interstitial, ready, interstitial == nil, !loading else { return }
        loading = true
        Task {
            defer { loading = false }
            interstitial = try? await InterstitialAd.load(with: interstitialID, request: Request())
        }
    }

    /// Called when someone leaves a hymn. Now and then (never more than once every three minutes) a full screen ad shows.
    func hymnClosed() {
        guard config.enabled, config.interstitial, ready else { return }
        closedSinceLast += 1
        if let lastShown, Date().timeIntervalSince(lastShown) < 180 { return }
        guard closedSinceLast >= config.every else { preload(); return }
        guard let ad = interstitial, let root = Self.topController() else { preload(); return }
        interstitial = nil
        closedSinceLast = 0
        lastShown = Date()
        ad.present(from: root)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in self?.preload() }
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
