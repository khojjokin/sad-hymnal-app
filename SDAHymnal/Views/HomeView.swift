import SwiftUI

/// Pages the Hymnal tab can open, besides a hymn (an Int).
enum HomeRoute: Hashable {
    case search
    case all
    case part(String)
    case theme(String)
}

struct HomeView: View {
    @EnvironmentObject private var app: AppState
    @EnvironmentObject private var library: Library
    @State private var showPad = false

    private let book = HymnBook.shared

    var body: some View {
        NavigationStack(path: $app.hymnalPath) {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        header
                        searchPill
                        hero
                        themes
                        if !recentHymns.isEmpty { recent }
                        browse
                    }
                    .padding(.top, 6)
                    .padding(.bottom, 30)
                }
                .scrollIndicators(.hidden)
                .tracksScroll()
                .background(Color.bg)

                CenteredOverlay(isPresented: $showPad) {
                    NumberPad(isPresented: $showPad) { app.hymnalPath.append($0) }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Int.self) { HymnView(number: $0) }
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .search: SearchView()
                case .all: AllHymnsView()
                case .part(let name):
                    if let part = book.parts.first(where: { $0.name == name }) { PartView(part: part) }
                case .theme(let name): ThemeView(name: name)
                }
            }
        }
    }

    // MARK: Top

    private var header: some View {
        HStack(spacing: 12) {
            SDALogo(size: 36, color: .brand)
            VStack(alignment: .leading, spacing: 0) {
                Text(t("home.title")).font(.serif(32, .bold)).foregroundStyle(Color.ink).lineLimit(1)
                Text(t("home.subtitle", ["n": book.count])).font(.footnote).foregroundStyle(Color.inkSoft).lineLimit(1)
            }
            Spacer(minLength: 8)
            circle("shuffle", label: t("home.random")) {
                if let h = book.withWords.randomElement() { app.hymnalPath.append(h.number) }
            }
            circle("number", label: t("home.byNumber")) { showPad = true }
        }
        .padding(.horizontal, 20)
    }

    private func circle(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.ink)
                .frame(width: 42, height: 42)
                .background(Color.card, in: Circle())
                .overlay(Circle().stroke(Color.stroke, lineWidth: 1))
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(label)
    }

    private var searchPill: some View {
        NavigationLink(value: HomeRoute.search) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundStyle(Color.inkSoft)
                Text(t("home.search")).foregroundStyle(Color.inkSoft).lineLimit(1)
                Spacer()
            }
            .font(.body)
            .padding(.horizontal, 16)
            .frame(height: 48)
            .background(Color.card, in: Capsule())
            .overlay(Capsule().stroke(Color.stroke, lineWidth: 1))
        }
        .buttonStyle(PressableStyle())
        .padding(.horizontal, 20)
    }

    // MARK: Hero

    private var recentHymns: [Hymn] { library.recent.compactMap { book.hymn($0) } }

    /// The last hymn opened (to carry on), or today's hymn for a first visit.
    private var hero: some View {
        let last = recentHymns.first
        let hymn = last ?? DiscoverModel.hymnOfDay(featured: app.config.featuredHymn)
        return NavigationLink(value: hymn.number) {
            ZStack(alignment: .bottomLeading) {
                Photo(key: last == nil ? "hymnOfDay" : "tileHymnal")
                LinearGradient(colors: [.clear, .black.opacity(0.25), .black.opacity(0.78)], startPoint: .top, endPoint: .bottom)
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(last == nil ? t("discover.hymnOfDay") : t("home.continue"))
                            .font(.caption.weight(.bold)).textCase(.uppercase).tracking(1.1)
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .glass(12)
                        Text("\(hymn.number)").font(.serif(40, .semibold)).foregroundStyle(.white)
                        Text(hymn.title).font(.serif(22, .semibold)).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.8)
                        if !hymn.author.isEmpty {
                            Text(hymn.author).font(.footnote).foregroundStyle(.white.opacity(0.75)).lineLimit(1)
                        }
                    }
                    Spacer(minLength: 12)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .glassCircle()
                }
                .padding(20)
            }
            .frame(height: 250)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .buttonStyle(PressableStyle())
        .padding(.horizontal, 20)
    }

    // MARK: Themes

    static let quickThemes: [(name: String, symbol: String, tint: String)] = [
        ("Sabbath", "sun.horizon.fill", "0B7DB3"),
        ("Morning Worship", "sunrise.fill", "F59E0B"),
        ("Evening Worship", "moon.stars.fill", "6366F1"),
        ("Meditation and Prayer", "hands.sparkles.fill", "0EA5A4"),
        ("Second Advent", "cloud.sun.fill", "E11D48"),
        ("Communion", "cup.and.saucer.fill", "8B5CF6"),
        ("Faith and Trust", "heart.fill", "22C55E"),
        ("Thankfulness", "leaf.fill", "16A34A"),
    ]

    private var themes: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(Self.quickThemes, id: \.name) { theme in
                    NavigationLink(value: HomeRoute.theme(theme.name)) {
                        HStack(spacing: 7) {
                            Image(systemName: theme.symbol).font(.system(size: 13, weight: .semibold)).foregroundStyle(Color(hex: theme.tint))
                            Text(theme.name).font(.subheadline.weight(.medium)).foregroundStyle(Color.ink).lineLimit(1)
                        }
                        .padding(.horizontal, 14)
                        .frame(height: 38)
                        .background(Color.card, in: Capsule())
                        .overlay(Capsule().stroke(Color.stroke, lineWidth: 1))
                    }
                    .buttonStyle(PressableStyle())
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: Recent

    private var recent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionTitle(text: t("home.recent"))
                Button(t("home.clear")) { withAnimation { library.clearRecent() } }
                    .font(.subheadline).foregroundStyle(Color.inkSoft)
            }
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(recentHymns.prefix(10)) { h in
                        NavigationLink(value: h.number) {
                            HStack(spacing: 10) {
                                Text("\(h.number)").font(.serif(18, .semibold)).foregroundStyle(Color.brand).monospacedDigit()
                                Text(h.title).font(.subheadline.weight(.medium)).foregroundStyle(Color.ink).lineLimit(1)
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 44)
                            .frame(maxWidth: 240)
                            .background(Color.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 20)
    }

    // MARK: Browse

    static let partTints = ["F59E0B", "8B5CF6", "0B7DB3", "E11D48", "F97316", "0EA5A4", "6366F1", "64748B", "14B8A6", "A855F7", "22C55E", "EC4899", "0EA5E9"]

    private var browse: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: t("home.parts")).padding(.horizontal, 20)
            VStack(spacing: 0) {
                ForEach(Array(book.parts.enumerated()), id: \.element.id) { i, part in
                    NavigationLink(value: HomeRoute.part(part.name)) {
                        browseRow(symbol: part.symbol, tint: Color(hex: Self.partTints[i % Self.partTints.count]),
                                  title: part.name, detail: "\(part.range.lowerBound)–\(part.range.upperBound)")
                    }
                    .buttonStyle(.plain)
                    Divider().padding(.leading, 62)
                }
                NavigationLink(value: HomeRoute.all) {
                    browseRow(symbol: "list.number", tint: Color.ink.opacity(0.75), title: t("home.all"), detail: "\(book.count)")
                }
                .buttonStyle(.plain)
            }
            .background(Color.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.stroke, lineWidth: 1))
            .padding(.horizontal, 20)
        }
    }

    private func browseRow(symbol: String, tint: Color, title: String, detail: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(tint.gradient, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            Text(title).font(.body.weight(.medium)).foregroundStyle(Color.ink).lineLimit(1)
            Spacer(minLength: 8)
            Text(detail).font(.subheadline).foregroundStyle(Color.inkSoft).monospacedDigit().lineLimit(1)
            Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(Color.inkFaint)
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .contentShape(Rectangle())
    }
}

// MARK: - Search

/// Search by title, words, writer or number. Opens with the keyboard up.
struct SearchView: View {
    @EnvironmentObject private var library: Library
    @State private var query = ""
    @State private var presented = true

    private let book = HymnBook.shared

    var body: some View {
        let q = query.trimmingCharacters(in: .whitespaces)
        let found = book.search(q)
        List {
            if q.isEmpty {
                let recent = library.recent.prefix(8).compactMap { book.hymn($0) }
                if recent.isEmpty {
                    Section {
                        Text(t("search.hint")).font(.subheadline).foregroundStyle(Color.inkSoft)
                    }
                } else {
                    Section(t("home.recent")) {
                        ForEach(recent) { h in NavigationLink(value: h.number) { HymnRow(hymn: h, subtitle: h.section) } }
                    }
                }
            } else {
                if let n = Int(q), let h = book.hymn(n) {
                    Section { NavigationLink(value: h.number) { HymnRow(hymn: h, subtitle: h.author) } }
                }
                if !found.titles.isEmpty {
                    Section(t("search.titles")) {
                        ForEach(found.titles.prefix(80)) { h in NavigationLink(value: h.number) { HymnRow(hymn: h, subtitle: h.section) } }
                    }
                }
                if !found.elsewhere.isEmpty {
                    Section(t("search.words")) {
                        ForEach(found.elsewhere.prefix(80)) { h in NavigationLink(value: h.number) { HymnRow(hymn: h, subtitle: h.author) } }
                    }
                }
                if found.titles.isEmpty && found.elsewhere.isEmpty && Int(q) == nil {
                    ContentUnavailableView.search(text: q)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.immediately)
        .tracksScroll()
        .navigationTitle(t("search.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .searchable(text: $query, isPresented: $presented, placement: .navigationBarDrawer(displayMode: .always), prompt: t("home.search"))
    }
}

/// Every hymn, under its heading.
struct AllHymnsView: View {
    @EnvironmentObject private var library: Library

    var body: some View {
        List {
            ForEach(HymnBook.shared.sections) { section in
                Section(section.name) {
                    ForEach(section.hymns) { h in
                        NavigationLink(value: h.number) { HymnRow(hymn: h, saved: library.isSaved(h.number)) }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .tracksScroll()
        .navigationTitle(t("home.all"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.visible, for: .navigationBar)
    }
}

/// The hymns in one part of the hymnal, grouped by heading.
struct PartView: View {
    let part: HymnPart
    @EnvironmentObject private var library: Library

    var body: some View {
        List {
            ForEach(HymnBook.shared.sections(in: part.range)) { section in
                Section(section.name) {
                    ForEach(section.hymns) { h in
                        NavigationLink(value: h.number) { HymnRow(hymn: h, saved: library.isSaved(h.number)) }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .tracksScroll()
        .navigationTitle(part.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.visible, for: .navigationBar)
    }
}

/// Every hymn under one heading of the hymnal, like Sabbath or Communion.
struct ThemeView: View {
    let name: String
    @EnvironmentObject private var library: Library

    private var hymns: [Hymn] { HymnBook.shared.sections.filter { $0.name == name }.flatMap(\.hymns) }

    var body: some View {
        List {
            Section(t("theme.count", ["n": hymns.count])) {
                ForEach(hymns) { h in
                    NavigationLink(value: h.number) { HymnRow(hymn: h, subtitle: h.author, saved: library.isSaved(h.number)) }
                }
            }
        }
        .listStyle(.insetGrouped)
        .tracksScroll()
        .navigationTitle(name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.visible, for: .navigationBar)
    }
}
