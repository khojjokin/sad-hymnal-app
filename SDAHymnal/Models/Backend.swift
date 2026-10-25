import Foundation
import UIKit
import ClerkKit

/// SDA Hymnal's services. Sign-in is Clerk (its own app, like every Qortn app); the hymnal-api Edge Function
/// in the shared Qortn Supabase project checks the Clerk token and keeps each member's saved hymns.
enum Backend {
    static let url = URL(string: "https://fjnifvugmbtajelmiuuh.supabase.co")!
    static let publishableKey = "sb_publishable_CEwinwr0mVRMfG8qtbpQcA_lZHg_nfw"

    /// Live sign-in runs on clerk.hymnal.qortyn.com once its DNS records are in place.
    /// Until then the app uses SDA Hymnal's Clerk development instance, which works straight away.
    static let useLiveSignIn = false
    static var clerkPublishableKey: String {
        useLiveSignIn ? "pk_live_Y2xlcmsuaHltbmFsLnFvcnR5bi5jb20k" : "pk_test_YmVjb21pbmctYWxiYWNvcmUtNjc5NC5jbGVyay5hY2NvdW50cy5kZXYk"
    }

    /// The App Store page.
    static let appStoreURL = URL(string: "https://apps.apple.com/app/id6822432398")!
    static let privacyURL = URL(string: "https://qortyn.com/hymnal/privacy")!

    static var appVersion: String { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0" }
    static var appBuild: String { Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1" }
}

struct AdsConfig: Equatable {
    var enabled = false
    var banner = true
    var interstitial = true
    /// About one in this many hymns closed shows a full screen ad.
    var every = 6
    var bannerID = ""
    var interstitialID = ""

    init() {}
    init(_ j: [String: Any]) {
        enabled = j["enabled"] as? Bool ?? false
        banner = j["banner"] as? Bool ?? true
        interstitial = j["interstitial"] as? Bool ?? true
        every = min(20, max(2, (j["every"] as? NSNumber)?.intValue ?? 6))
        bannerID = j["bannerId"] as? String ?? ""
        interstitialID = j["interstitialId"] as? String ?? ""
    }
}

/// Settings the console can change for everyone.
struct RemoteConfig: Equatable {
    var maintenance: String?
    var announcement: String?
    var minVersion: String?
    var featuredHymn: Int?
    /// Ads, switched on and set up from the console.
    var ads = AdsConfig()

    init(_ j: [String: Any]) {
        maintenance = j["maintenance"] as? String
        announcement = j["announcement"] as? String
        minVersion = j["minVersion"] as? String
        featuredHymn = (j["featuredHymn"] as? NSNumber)?.intValue
        if let a = j["ads"] as? [String: Any] { ads = AdsConfig(a) }
    }
    init() {}
}

struct MemberNotice: Identifiable, Equatable {
    let id: Int
    let title: String
    let body: String
}

/// What the server says about the signed-in account.
struct MemberState: Equatable {
    var isAdmin = false
    var status = "active"
    var statusMessage: String?
    var notices: [MemberNotice] = []
}

enum BackendError: LocalizedError {
    case message(String)
    var errorDescription: String? { if case .message(let m) = self { return m }; return nil }
}

final class HymnalAPI {
    static let shared = HymnalAPI()
    private let http = URLSession(configuration: .default)

    /// Calls the hymnal-api Edge Function, with the member's Clerk token when there is one.
    @discardableResult
    func call(_ action: String, token: String?, _ extra: [String: Any] = [:]) async throws -> [String: Any] {
        var req = URLRequest(url: Backend.url.appendingPathComponent("functions/v1/hymnal-api"))
        req.httpMethod = "POST"
        req.timeoutInterval = 30
        req.setValue(Backend.publishableKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(token ?? Backend.publishableKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var body = extra
        body["action"] = action
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await http.data(for: req)
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            throw BackendError.message(json["error"] as? String ?? "Something went wrong (\(status)).")
        }
        return json
    }

    func config() async -> RemoteConfig? {
        guard let j = try? await call("config", token: nil), let c = j["config"] as? [String: Any] else { return nil }
        return RemoteConfig(c)
    }

    /// The most sung hymns this week (for Discover). Empty when offline.
    func trending() async -> [Int] {
        guard let j = try? await call("trending", token: nil), let rows = j["hymns"] as? [[String: Any]] else { return [] }
        return rows.compactMap { ($0["n"] as? NSNumber)?.intValue }
    }

    /// Counts opens, saves and shares so the console can see the most loved hymns. Never blocks the app.
    func track(_ kind: String, hymn: Int?, detail: String? = nil) {
        Task { @MainActor in
            var token: String?
            if Clerk.shared.user != nil { token = try? await Clerk.shared.auth.getToken() }
            var body: [String: Any] = ["kind": kind]
            if let hymn { body["hymn"] = hymn }
            if let detail { body["detail"] = detail }
            _ = try? await self.call("track", token: token, body)
        }
    }

    func me(token: String, provider: String) async throws -> MemberState {
        let device = await MainActor.run { UIDevice.current.model }
        let os = await MainActor.run { "iOS " + UIDevice.current.systemVersion }
        var body: [String: Any] = ["provider": provider, "appVersion": Backend.appVersion, "appBuild": Backend.appBuild, "device": device, "os": os]
        if let region = Locale.current.region?.identifier, region.count == 2 { body["country"] = region }
        let j = try await call("me", token: token, body)
        let notices = (j["notices"] as? [[String: Any]] ?? []).compactMap { n -> MemberNotice? in
            guard let id = (n["id"] as? NSNumber)?.intValue, let t = n["title"] as? String, let b = n["body"] as? String else { return nil }
            return MemberNotice(id: id, title: t, body: b)
        }
        return MemberState(isAdmin: j["isAdmin"] as? Bool ?? false, status: j["status"] as? String ?? "active",
                           statusMessage: j["statusMessage"] as? String, notices: notices)
    }

    func getLibrary(token: String) async throws -> LibraryData? {
        let j = try await call("getLibrary", token: token)
        guard let blob = j["data"], !(blob is NSNull) else { return nil }
        let data = try JSONSerialization.data(withJSONObject: blob)
        return try JSONDecoder().decode(LibraryData.self, from: data)
    }

    func saveLibrary(token: String, _ library: LibraryData) async throws {
        let data = try JSONEncoder().encode(library)
        let blob = try JSONSerialization.jsonObject(with: data)
        try await call("saveLibrary", token: token, ["data": blob])
    }

    func acknowledge(token: String, notice: Int) async {
        _ = try? await call("ackNotice", token: token, ["id": notice])
    }

    func deleteAccount(token: String) async throws {
        try await call("deleteAccount", token: token)
    }
}
