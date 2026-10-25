import SwiftUI

/// The bottom bar's state: hidden on a hymn (each tab counts its own hymn pages). It never shrinks.
@MainActor
final class TabBarState: ObservableObject {
    @Published var hiddenIn: [AppState.Tab: Int] = [:]
    @Published var current: AppState.Tab = .hymnal

    var hidden: Bool { (hiddenIn[current] ?? 0) > 0 }

    func hide(in tab: AppState.Tab) { hiddenIn[tab, default: 0] += 1 }
    func show(in tab: AppState.Tab) { hiddenIn[tab] = max(0, (hiddenIn[tab] ?? 0) - 1) }
}

private struct HostTabKey: EnvironmentKey { static let defaultValue: AppState.Tab = .hymnal }
extension EnvironmentValues {
    /// Which tab a screen lives in.
    var hostTab: AppState.Tab {
        get { self[HostTabKey.self] }
        set { self[HostTabKey.self] = newValue }
    }
}

/// The app's bottom bar: every tab always showing at full size, the chosen one in sea blue (no sliding bubble).
struct HymnalTabBar: View {
    @EnvironmentObject private var app: AppState
    @EnvironmentObject private var bar: TabBarState

    /// Room kept under every page so the last rows aren't covered.
    static let reserved: CGFloat = 76

    private struct Item: Identifiable {
        let tab: AppState.Tab
        let title: String
        let symbol: String
        let filled: String
        var id: AppState.Tab { tab }
    }

    private var items: [Item] {
        [
            Item(tab: .hymnal, title: t("tab.hymnal"), symbol: "book.closed", filled: "book.closed.fill"),
            Item(tab: .discover, title: t("tab.discover"), symbol: "safari", filled: "safari.fill"),
            Item(tab: .saved, title: t("tab.saved"), symbol: "bookmark", filled: "bookmark.fill"),
            Item(tab: .settings, title: t("tab.settings"), symbol: "gearshape", filled: "gearshape.fill"),
        ]
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                let on = app.tab == item.tab
                Button {
                    if on {
                        if item.tab == .hymnal { app.hymnalPath = NavigationPath() }
                    } else {
                        UISelectionFeedbackGenerator().selectionChanged()
                        var tx = Transaction()
                        tx.disablesAnimations = true
                        withTransaction(tx) { app.tab = item.tab }
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: on ? item.filled : item.symbol)
                            .font(.system(size: 21, weight: on ? .semibold : .regular))
                            .frame(height: 24)
                        Text(item.title)
                            .font(.system(size: 10.5, weight: on ? .semibold : .medium))
                            .lineLimit(1)
                    }
                    .foregroundStyle(on ? Color.brand : Color.inkSoft)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.title)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(.horizontal, 6)
        .glass(30)
        .shadow(color: .black.opacity(0.12), radius: 16, y: 6)
        .padding(.horizontal, 14)
        .padding(.bottom, 4)
    }
}

extension View {
    /// Kept so screens compile unchanged; the bar no longer reacts to scrolling.
    func tracksScroll() -> some View { self }

    /// Hides the bottom bar while this screen shows (used by the hymn page).
    func hidesTabBar() -> some View { modifier(HidesTabBar()) }
}

private struct HidesTabBar: ViewModifier {
    @EnvironmentObject private var bar: TabBarState
    @Environment(\.hostTab) private var tab

    func body(content: Content) -> some View {
        content
            .onAppear { bar.hide(in: tab) }
            .onDisappear { bar.show(in: tab) }
    }
}
