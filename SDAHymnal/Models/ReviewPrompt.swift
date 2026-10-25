import SwiftUI
import StoreKit

/// Asks for an App Store rating with Apple's own review prompt, at a calm moment: after someone has
/// finished a hymn, once they've opened at least 8 hymns over 3 or more days. At most once per app
/// version and never more than every 120 days (Apple also limits it to three times a year).
@MainActor
enum ReviewPrompt {
    private static let d = UserDefaults.standard
    private static let opensKey = "hymnal.review.opens"
    private static let firstKey = "hymnal.review.first"
    private static let askedVersionKey = "hymnal.review.version"
    private static let askedAtKey = "hymnal.review.at"

    static func hymnOpened() {
        d.set(d.integer(forKey: opensKey) + 1, forKey: opensKey)
        if d.object(forKey: firstKey) == nil { d.set(Date(), forKey: firstKey) }
    }

    /// Called when a hymn closes. Shows the prompt a moment later, back on the list, if it's time.
    static func hymnClosed() {
        guard d.integer(forKey: opensKey) >= 8,
              let first = d.object(forKey: firstKey) as? Date, Date().timeIntervalSince(first) >= 3 * 86400,
              d.string(forKey: askedVersionKey) != Backend.appVersion else { return }
        if let last = d.object(forKey: askedAtKey) as? Date, Date().timeIntervalSince(last) < 120 * 86400 { return }
        d.set(Backend.appVersion, forKey: askedVersionKey)
        d.set(Date(), forKey: askedAtKey)
        Task {
            try? await Task.sleep(for: .seconds(0.8))
            guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }) else { return }
            if #available(iOS 18.0, *) {
                AppStore.requestReview(in: scene)
            } else {
                SKStoreReviewController.requestReview(in: scene)
            }
        }
    }

    /// Settings › Rate this app: straight to the App Store's "Write a Review" page.
    static let writeReviewURL = URL(string: "https://apps.apple.com/app/id6822432398?action=write-review")!
}
