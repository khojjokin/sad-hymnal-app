import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var app: AppState
    @EnvironmentObject private var library: Library
    @State private var query = ""
    @State private var showPad = false
    @FocusState private var searching: Bool

    private let book = HymnBook.shared

    var body: some View {
        NavigationStack(path: $app.hymnalPath) {
            ZStack {
                Group {
                    if query.trimmingCharacters(in: .whitespaces).isEmpty {
                        browse
                    } else {
                        results
                    }
                }
                CenteredOverlay(isPresented: $showPad) {
                    NumberPad(isPresented: $showPad) { app.hymnalPath.append($0) }
                }
            }
            .background(Color.bg)
            .navigationTitle(t("tab.hymnal"))
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) { searchBar }
            .navigationDestination(for: Int.self) { HymnView(number: $0) }
            .navigationDestination(for: HymnPart.ID.self) { name in
                if let part = book.parts.first(where: { $0.name == name }) { PartView(part: part) }
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(query.isEmpty && !searching ? .white.opacity(0.85) : Color.inkSoft)
                TextField("", text: $query, prompt: Text(t("home.search")).foregroundStyle(query.isEmpty && !searching ? .white.opacity(0.85) : Color.inkFaint))
                    .focused($searching)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                    .foregroundStyle(Color.ink)
                if !query.isEmpty {
                    Button { query = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(Color.inkFaint) }
                        .accessibilityLabel(t("common.clear"))
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 46)
            .glass(23)
            if searching || !query.isEmpty {
                Button(t("common.cancel")) { query = ""; searching = false }
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.brand)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .animation(.easeOut(duration: 0.2), value: searching)
    }

    // MARK: Browse

    private var browse: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                hero
                actions
                if !library.recent.isEmpty { recent }
                parts
                all
            }
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .ignoresSafeArea(edges: .top)
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            Photo(key: "tileHymnal")
            LinearGradient(colors: [.black.opacity(0.15), .black.opacity(0.05), Color.sea[0].opacity(0.85)], startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 10) {
                SDALogo(size: 46)
                Text(t("home.title")).font(.serif(46, .semibold)).foregroundStyle(.white).lineLimit(1)
                Text(t("home.subtitle", ["n": book.count])).font(.serif(17).italic()).foregroundStyle(.white.opacity(0.85)).lineLimit(1)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 26)
        }
        .frame(height: 340)
        .clipped()
    }

    private var actions: some View {
        HStack(spacing: 12) {
            ActionTile(symbol: "number", title: t("home.byNumber"), tint: .brand) { showPad = true }
            ActionTile(symbol: "shuffle", title: t("home.random"), tint: Color(hex: "7C5CFF")) {
                if let h = book.withWords.randomElement() { app.hymnalPath.append(h.number) }
            }
            ActionTile(symbol: "sun.max.fill", title: t("home.today"), tint: Color(hex: "F59E0B")) {
                app.hymnalPath.append(DiscoverModel.hymnOfDay().number)
            }
        }
        .padding(.horizontal, 20)
    }

    private var recent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle(text: t("home.recent"))
                Button(t("home.clear")) { withAnimation { library.clearRecent() } }
                    .font(.subheadline).foregroundStyle(Color.inkSoft)
            }
            .padding(.horizontal, 20)
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(library.recent.prefix(12), id: \.self) { n in
                        if let h = book.hymn(n) {
                            NavigationLink(value: n) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("\(n)").font(.serif(26, .semibold)).foregroundStyle(Color.brand)
                                    Text(h.title).font(.footnote.weight(.medium)).foregroundStyle(Color.ink).lineLimit(1)
                                }
                                .frame(width: 140, alignment: .leading)
                                .card(padding: 14, radius: 20)
                            }
                            .buttonStyle(PressableStyle())
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var parts: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: t("home.parts")).padding(.horizontal, 20)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(book.parts) { part in
                    NavigationLink(value: part.id) {
                        VStack(alignment: .leading, spacing: 10) {
                            Image(systemName: part.symbol).font(.title3).foregroundStyle(Color.brand)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(part.name).font(.subheadline.weight(.semibold)).foregroundStyle(Color.ink).lineLimit(1)
                                Text("\(part.range.lowerBound)–\(part.range.upperBound)").font(.caption).foregroundStyle(Color.inkSoft).lineLimit(1)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .card(padding: 16, radius: 20)
                    }
                    .buttonStyle(PressableStyle())
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var all: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionTitle(text: t("home.all"), trailing: "\(book.count)").padding(.horizontal, 20).padding(.bottom, 6)
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(book.hymns) { h in
                    NavigationLink(value: h.number) {
                        HymnRow(hymn: h, saved: library.isSaved(h.number))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    Divider().padding(.leading, 78)
                }
            }
        }
    }

    // MARK: Search

    private var results: some View {
        let found = book.search(query)
        return List {
            if let n = Int(query.trimmingCharacters(in: .whitespaces)), let h = book.hymn(n) {
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
            if found.titles.isEmpty && found.elsewhere.isEmpty && Int(query) == nil {
                ContentUnavailableView.search(text: query)
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.immediately)
    }
}

struct ActionTile: View {
    let symbol: String
    let title: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(tint.gradient, in: Circle())
                Text(title).font(.footnote.weight(.semibold)).foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .card(padding: 14, radius: 22)
        }
        .buttonStyle(PressableStyle())
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
        .navigationTitle(part.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.visible, for: .navigationBar)
    }
}
