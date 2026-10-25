import SwiftUI

/// The bottom bar's state: shrunk while scrolling down, and hidden on a hymn (each tab counts its own hymn pages).
@MainActor
final class TabBarState: ObservableObject {
    @Published var compact = false
    @Published var hiddenIn: [AppState.Tab: Int] = [:]
    @Published var current: AppState.Tab = .hymnal

    var hidden: Bool { (hiddenIn[current] ?? 0) > 0 }

    func hide(in tab: AppState.Tab) { hiddenIn[tab, default: 0] += 1 }
    func show(in tab: AppState.Tab) { hiddenIn[tab] = max(0, (hiddenIn[tab] ?? 0) - 1) }

    func setCompact(_ value: Bool) {
        guard compact != value else { return }
        // Slow and soft, like Instagram's bar settling as you scroll.
        withAnimation(.smooth(duration: 0.55)) { compact = value }
    }
}

private struct HostTabKey: EnvironmentKey { static let defaultValue: AppState.Tab = .hymnal }
extension EnvironmentValues {
    /// Which tab a screen lives in.
    var hostTab: AppState.Tab {
        get { self[HostTabKey.self] }
        set { self[HostTabKey.self] = newValue }
    }
}

/// The app's bottom bar: every tab always showing, the chosen one in sea blue (no sliding bubble).
/// Icons only. Scrolling down slowly shrinks it into a small pill; scrolling up brings it back.
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
        let compact = bar.compact
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
                    bar.setCompact(false)
                } label: {
                    // Icons only, no names under them.
                    Image(systemName: on ? item.filled : item.symbol)
                        .font(.system(size: 22, weight: on ? .semibold : .regular))
                        .scaleEffect(compact ? 0.86 : 1)
                        .foregroundStyle(on ? Color.brand : Color.inkSoft)
                        .frame(maxWidth: .infinity)
                        .frame(height: compact ? 46 : 58)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.title)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(.horizontal, 6)
        // A solid base under the glass so rows scrolling behind don't show through.
        .background(Color.bg.opacity(0.72), in: RoundedRectangle(cornerRadius: compact ? 23 : 29, style: .continuous))
        .glass(compact ? 23 : 29)
        .shadow(color: .black.opacity(0.12), radius: 16, y: 6)
        .padding(.horizontal, compact ? 70 : 24)
        .padding(.bottom, 4)
    }
}

/// Reports scrolling to the bottom bar: down by a little shrinks it, up by a little brings it back.
struct TracksScroll: ViewModifier {
    @EnvironmentObject private var bar: TabBarState
    @State private var anchor: CGFloat = 0

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.onScrollGeometryChange(for: CGFloat.self) { geo in
                geo.contentOffset.y + geo.contentInsets.top
            } action: { _, y in
                if y < 24 {
                    bar.setCompact(false)
                    anchor = y
                } else if bar.compact {
                    if y > anchor { anchor = y } else if anchor - y > 28 { bar.setCompact(false); anchor = y }
                } else {
                    if y < anchor { anchor = y } else if y - anchor > 28 { bar.setCompact(true); anchor = y }
                }
            }
        } else {
            content
        }
    }
}

extension View {
    func tracksScroll() -> some View { modifier(TracksScroll()) }

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
