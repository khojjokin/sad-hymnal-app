import SwiftUI
import ClerkKit
import UserNotifications

@main
struct SDAHymnalApp: App {
    @StateObject private var prefs = Prefs.shared
    @StateObject private var auth = AuthStore()
    @StateObject private var library = Library()
    @StateObject private var app = AppState()
    @StateObject private var splash = SplashGate()
    @StateObject private var bar = TabBarState()
    init() {
        Clerk.configure(publishableKey: Backend.clerkPublishableKey)
        Task.detached(priority: .background) { await Backend.checkLiveSignIn() }
        UNUserNotificationCenter.current().delegate = NotificationRouter.shared
    }

    var body: some Scene {
        WindowGroup {
            AppHost(splash: splash)
                .environmentObject(prefs)
                .environmentObject(auth)
                .environmentObject(library)
                .environmentObject(app)
                .environmentObject(bar)
                .environment(Clerk.shared)
                .tint(.brand)
        }
    }
}

/// Holds the splash over the app and keeps the account, saved hymns and console settings in step.
struct AppHost: View {
    @ObservedObject var splash: SplashGate
    @EnvironmentObject private var prefs: Prefs
    @EnvironmentObject private var auth: AuthStore
    @EnvironmentObject private var library: Library
    @EnvironmentObject private var app: AppState
    @Environment(Clerk.self) private var clerk
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            if !splash.showing {
                RootView().transition(.opacity)
            }
            if splash.showing {
                SplashView { splash.finish() }
                    .transition(.opacity)
                    .zIndex(1)
            } else if splash.covered {
                SplashCover().zIndex(2)
            }
            if let toast = app.toast, !splash.showing {
                Toast(text: toast).transition(.scale(scale: 0.9).combined(with: .opacity)).zIndex(3)
            }
        }
        .preferredColorScheme(splash.showing ? .dark : prefs.appearance.colorScheme)
        .task {
            // Clerk can restore the session before this view exists, so read it now as well as on changes.
            syncAccount()
            library.attach(auth)
            await Plus.shared.load()
            await app.loadConfig()
        }
        .onChange(of: splash.showing) { _, showing in
            // Ask about the daily hymn once the app itself is on screen.
            if !showing { Task { await DailyHymn.shared.start() } }
        }
        .onReceive(NotificationCenter.default.publisher(for: NotificationRouter.openHymn)) { note in
            if let n = note.object as? Int { app.open(n) }
        }
        .onChange(of: clerk.user?.id) { _, _ in syncAccount() }
        .onChange(of: clerk.isLoaded) { _, loaded in if loaded { syncAccount() } }
        .onChange(of: scenePhase) { _, phase in
            splash.phaseChanged(phase)
            if phase == .active {
                Task {
                    await app.loadConfig()
                    await auth.refresh()
                    await library.pull()
                    await Plus.shared.refresh()
                    await DailyHymn.shared.reschedule()
                }
            }
        }
        .onOpenURL { url in app.handle(url) }
    }

    private func syncAccount() {
        auth.update(from: clerk.user)
        Task { await library.switchProfile(to: auth.currentUser?.id) }
    }
}

/// App-wide state: which tab is showing, the console's settings, and hymns opened from a link.
@MainActor
final class AppState: ObservableObject {
    enum Tab: Hashable { case hymnal, discover, saved, settings }
    @Published var tab: Tab = .hymnal
    @Published var config = RemoteConfig()
    @Published var hiddenAnnouncement: String?
    @Published var hymnalPath = NavigationPath()
    /// A short centred message over the app (like "You're in" after signing in).
    @Published var toast: String?

    func showToast(_ text: String) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { toast = text }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.8))
            withAnimation(.easeOut(duration: 0.3)) { if self.toast == text { self.toast = nil } }
        }
    }

    /// Goes up when hymn words arrive from the console, so open screens show them.
    @Published var wordsVersion = 0

    func loadConfig() async {
        if let c = await HymnalAPI.shared.config() {
            config = c
            Ads.shared.apply(c.ads)
        }
        if await HymnWords.refresh() { wordsVersion += 1 }
    }

    var needsUpdate: Bool {
        guard let min = config.minVersion, !min.isEmpty else { return false }
        return Backend.appVersion.compare(min, options: .numeric) == .orderedAscending
    }

    /// sdahymnal://hymn/100 opens that hymn.
    func handle(_ url: URL) {
        guard url.scheme == "sdahymnal" else { return }
        let parts = ([url.host ?? ""] + url.pathComponents).filter { $0 != "/" && !$0.isEmpty }
        if parts.first == "hymn", let n = parts.dropFirst().first.flatMap({ Int($0) }), HymnBook.shared.hymn(n) != nil {
            tab = .hymnal
            hymnalPath = NavigationPath([n])
        }
    }

    func open(_ n: Int) {
        tab = .hymnal
        hymnalPath = NavigationPath([n])
    }
}

struct RootView: View {
    @EnvironmentObject private var app: AppState
    @EnvironmentObject private var auth: AuthStore
    @EnvironmentObject private var prefs: Prefs
    @EnvironmentObject private var bar: TabBarState

    var body: some View {
        Group {
            if let message = app.config.maintenance, !message.isEmpty {
                Blocker(symbol: "wrench.and.screwdriver.fill", title: t("maintenance.title"), message: message)
            } else if app.needsUpdate {
                Blocker(symbol: "arrow.down.app.fill", title: t("update.title"), message: t("update.body"), actionTitle: t("update.action")) {
                    UIApplication.shared.open(Backend.appStoreURL)
                }
            } else {
                tabs
            }
        }
        .id("\(prefs.language)-\(app.wordsVersion)")
    }

    /// The four tabs stay alive (so each keeps its place) under one custom bar: all tabs always shown,
    /// no sliding bubble, and it shrinks while you scroll down, like Instagram.
    private var tabs: some View {
        ZStack {
            page(.hymnal) { HomeView() }
            page(.discover) { DiscoverView() }
            page(.saved) { SavedView() }
            page(.settings) { SettingsView() }
        }
        .overlay(alignment: .bottom) {
            if !bar.hidden {
                HymnalTabBar()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.2), value: bar.hidden)
        .ignoresSafeArea(.keyboard)
        .safeAreaInset(edge: .top, spacing: 0) {
            if let text = app.config.announcement, !text.isEmpty, app.hiddenAnnouncement != text {
                AnnouncementBanner(text: text) { withAnimation { app.hiddenAnnouncement = text } }
            }
        }
        .alert(auth.state.notices.first?.title ?? "", isPresented: Binding(
            get: { !auth.state.notices.isEmpty },
            set: { _ in })) {
            Button(t("common.ok")) {
                if let n = auth.state.notices.first { Task { await auth.acknowledge(n) } }
            }
        } message: {
            Text(auth.state.notices.first?.body ?? "")
        }
        .onChange(of: app.tab) { _, tab in bar.current = tab; bar.setCompact(false) }
    }

    private func page<V: View>(_ tab: AppState.Tab, @ViewBuilder _ content: () -> V) -> some View {
        let on = app.tab == tab
        return content()
            .safeAreaInset(edge: .bottom, spacing: 0) { Color.clear.frame(height: bar.hidden ? 0 : HymnalTabBar.reserved) }
            .environment(\.hostTab, tab)
            .opacity(on ? 1 : 0)
            .allowsHitTesting(on)
            .accessibilityHidden(!on)
            .zIndex(on ? 1 : 0)
    }
}

/// A small centred confirmation, gone by itself after a moment.
struct Toast: View {
    let text: String
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 40)).foregroundStyle(Color.good)
            Text(text).font(.headline).foregroundStyle(Color.ink).lineLimit(1)
        }
        .padding(.horizontal, 30).padding(.vertical, 22)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 24, y: 10)
        .allowsHitTesting(false)
        .accessibilityAddTraits(.isStaticText)
    }
}

/// A full screen message (maintenance, or an update that must be installed).
struct Blocker: View {
    let symbol: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: symbol).font(.system(size: 52)).foregroundStyle(Color.brand)
            Text(title).font(.serif(28, .semibold)).foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.8)
            Text(message).font(.body).foregroundStyle(Color.inkSoft).multilineTextAlignment(.center)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action).buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bg)
    }
}
