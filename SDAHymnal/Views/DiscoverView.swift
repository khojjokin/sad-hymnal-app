import SwiftUI

/// What Discover shows today. The same picks all day; the shuffle button deals a fresh set.
enum DiscoverModel {
    static func hymnOfDay(shuffle: Int = 0, featured: Int? = nil) -> Hymn {
        let book = HymnBook.shared
        if shuffle == 0, let featured, let h = book.hymn(featured) { return h }
        return book.pick(book.withWords, day: HymnBook.dayNumber(), shuffle: shuffle, stride: 37)
    }

    /// Hymns from one heading of the hymnal (falls back to any hymn with words).
    static func from(_ sections: [String], shuffle: Int, stride: Int, offset: Int = 0) -> Hymn {
        let book = HymnBook.shared
        let list = book.sections.filter { sections.contains($0.name) }.flatMap(\.hymns).filter(\.hasWords)
        return book.pick(list.isEmpty ? book.withWords : list, day: HymnBook.dayNumber() + offset, shuffle: shuffle, stride: stride)
    }

    /// Short true notes about the hymnal and its writers.
    static let facts: [(symbol: String, text: String)] = [
        ("book.closed.fill", "The Seventh-day Adventist Hymnal was published in 1985 and holds 695 numbers."),
        ("music.note", "Numbers 660 to 695 are short sentences and responses for prayers, offerings and benedictions."),
        ("eye.slash.fill", "Fanny Crosby lost her sight as a baby, yet wrote thousands of hymns, including Blessed Assurance."),
        ("pencil.and.scribble", "Isaac Watts is often called the father of English hymnody."),
        ("music.quarternote.3", "Charles Wesley wrote around 6,000 hymns in his lifetime."),
        ("clock.fill", "The Early Advent section keeps songs sung by believers waiting for Christ's return in the 1840s."),
    ]
}

enum DiscoverRoute: Hashable {
    case writer(String)
    case theme(String)
}

struct DiscoverView: View {
    @EnvironmentObject private var app: AppState
    @EnvironmentObject private var library: Library
    @State private var shuffle = 0
    @State private var spin = 0.0
    @State private var page: Int? = 1
    @State private var trending: [Int] = []
    @State private var shareHymn: Hymn?

    private let book = HymnBook.shared

    private struct DayPick: Identifiable {
        let id: Int
        let label: String
        let photo: String
        let hymn: Hymn
    }

    /// The hymns of the day: one for the morning, the hymn of the day, and one for the evening.
    private var dayPicks: [DayPick] {
        [
            DayPick(id: 0, label: t("discover.morningHymn"), photo: "emptyExplore",
                    hymn: DiscoverModel.from(["Morning Worship", "Adoration and Praise"], shuffle: shuffle, stride: 5)),
            DayPick(id: 1, label: t("discover.hymnOfDay"), photo: "hymnOfDay",
                    hymn: DiscoverModel.hymnOfDay(shuffle: shuffle, featured: app.config.featuredHymn)),
            DayPick(id: 2, label: t("discover.eveningHymn"), photo: "prayer",
                    hymn: DiscoverModel.from(["Evening Worship", "Meditation and Prayer"], shuffle: shuffle, stride: 7)),
        ]
    }

    private var verseHymn: Hymn { DiscoverModel.from(["Faith and Trust", "Hope and Comfort", "Joy and Peace", "Love of God", "Guidance"], shuffle: shuffle, stride: 13, offset: 3) }
    private var moment: HymnBook.Moment { HymnBook.moment() }
    private var momentHymns: [Hymn] {
        let list = book.hymns(for: moment)
        guard !list.isEmpty else { return [] }
        return unique((0..<min(6, list.count)).map { i in book.pick(list, day: HymnBook.dayNumber() + i, shuffle: shuffle, stride: 7) })
    }
    private var stories: [Story] {
        guard !book.stories.isEmpty else { return [] }
        let start = (HymnBook.dayNumber() + shuffle * 5) % book.stories.count
        return (0..<min(8, book.stories.count)).map { book.stories[(start + $0) % book.stories.count] }
    }
    private var more: [Hymn] {
        unique((1...6).map { book.pick(book.withWords, day: HymnBook.dayNumber() + $0 * 11, shuffle: shuffle, stride: 53) })
    }
    private func unique(_ hymns: [Hymn]) -> [Hymn] { hymns.reduce(into: [Hymn]()) { o, h in if !o.contains(h) { o.append(h) } } }

    static let themes: [(name: String, symbol: String, tint: String)] = [
        ("Love of God", "heart.fill", "E11D48"),
        ("Hope and Comfort", "sun.max.fill", "F59E0B"),
        ("Joy and Peace", "bird.fill", "0EA5A4"),
        ("Guidance", "location.north.circle.fill", "0B7DB3"),
        ("Eternal Life", "infinity", "8B5CF6"),
        ("Mission of the Church", "globe.europe.africa.fill", "16A34A"),
        ("Holy Spirit", "flame.fill", "F97316"),
        ("Second Advent", "cloud.sun.fill", "6366F1"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 34) {
                    header
                    hymnsOfDay
                    verseCard
                    if !trending.isEmpty { trendingSection }
                    if !momentHymns.isEmpty { momentSection }
                    themeSection
                    if !stories.isEmpty { storySection }
                    if !book.writers.isEmpty { writersSection }
                    factsSection
                    moreSection
                }
                .padding(.top, 6)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
            .tracksScroll()
            .background(Color.bg)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Int.self) { HymnView(number: $0) }
            .navigationDestination(for: DiscoverRoute.self) { route in
                switch route {
                case .writer(let name):
                    if let w = book.writers.first(where: { $0.name == name }) { WriterView(writer: w) }
                case .theme(let name):
                    ThemeView(name: name)
                }
            }
            .fullScreenCover(item: $shareHymn) { ShareCardView(hymn: $0) }
            .animation(.easeInOut(duration: 0.3), value: shuffle)
            .task { trending = await HymnalAPI.shared.trending().filter { book.hymn($0) != nil } }
            .refreshable { trending = await HymnalAPI.shared.trending().filter { book.hymn($0) != nil } }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()).uppercased())
                    .font(.caption.weight(.semibold)).tracking(1).foregroundStyle(Color.inkSoft).lineLimit(1)
                Text(t("tab.discover")).font(.serif(34, .bold)).foregroundStyle(Color.ink).lineLimit(1)
            }
            Spacer()
            Button {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                withAnimation(.spring(response: 0.5)) { spin += 360 }
                shuffle += 1
            } label: {
                Image(systemName: "shuffle").font(.system(size: 16, weight: .semibold)).foregroundStyle(Color.ink)
                    .rotationEffect(.degrees(spin))
                    .frame(width: 42, height: 42)
                    .background(Color.card, in: Circle())
                    .overlay(Circle().stroke(Color.stroke, lineWidth: 1))
            }
            .accessibilityLabel(t("discover.shuffle"))
        }
        .padding(.horizontal, 20)
    }

    // MARK: Hymns of the day

    private var hymnsOfDay: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: t("discover.hymnsOfDay")).padding(.horizontal, 20)
            ScrollView(.horizontal) {
                LazyHStack(spacing: 12) {
                    ForEach(dayPicks) { pick in
                        NavigationLink(value: pick.hymn.number) { dayCard(pick) }
                            .buttonStyle(PressableStyle())
                            .containerRelativeFrame(.horizontal)
                            .id(pick.id)
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, 20, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $page)
            .scrollIndicators(.hidden)
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    Capsule().fill(i == (page ?? 1) ? Color.brand : Color.stroke)
                        .frame(width: i == (page ?? 1) ? 18 : 6, height: 6)
                }
            }
            .frame(maxWidth: .infinity)
            .animation(.easeOut(duration: 0.2), value: page)
        }
    }

    private func dayCard(_ pick: DayPick) -> some View {
        let first = book.verses(of: pick.hymn).first?.text.split(separator: "\n").prefix(2).joined(separator: " ") ?? ""
        return ZStack(alignment: .bottomLeading) {
            Photo(key: pick.photo)
            LinearGradient(colors: [.clear, .black.opacity(0.2), .black.opacity(0.85)], startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 8) {
                Text(pick.label).font(.caption.weight(.bold)).textCase(.uppercase).tracking(1.1)
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .glass(12)
                Spacer()
                Text("\(pick.hymn.number)").font(.serif(46, .semibold)).foregroundStyle(.white)
                Text(pick.hymn.title).font(.serif(26, .semibold)).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.7)
                if !first.isEmpty {
                    Text(first).font(.serif(15).italic()).foregroundStyle(.white.opacity(0.8)).lineLimit(1)
                }
            }
            .padding(22)
        }
        .frame(height: 400)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
    }

    // MARK: Verse

    private var verseCard: some View {
        let hymn = verseHymn
        let verse = book.verses(of: hymn).first?.text ?? ""
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "quote.opening").font(.title2).foregroundStyle(.white.opacity(0.6))
                Spacer()
                Text(t("discover.verse")).font(.caption.weight(.bold)).textCase(.uppercase).tracking(1.1).foregroundStyle(.white.opacity(0.8)).lineLimit(1)
            }
            Text(verse).font(.serif(20)).foregroundStyle(.white).lineSpacing(6)
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(hymn.number) · \(hymn.title)").font(.subheadline.weight(.semibold)).foregroundStyle(.white).lineLimit(1)
                    if !hymn.author.isEmpty { Text(hymn.author).font(.caption).foregroundStyle(.white.opacity(0.7)).lineLimit(1) }
                }
                Spacer(minLength: 8)
                Button { shareHymn = hymn } label: {
                    Image(systemName: "square.and.arrow.up").font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                        .frame(width: 40, height: 40).glassCircle()
                }
                .accessibilityLabel(t("hymn.shareCard"))
                NavigationLink(value: hymn.number) {
                    Image(systemName: "arrow.right").font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                        .frame(width: 40, height: 40).glassCircle()
                }
                .accessibilityLabel(t("pad.open"))
            }
        }
        .padding(22)
        .background(LinearGradient(colors: Color.sea, startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(.horizontal, 20)
    }

    // MARK: Trending

    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: t("discover.trending"), trailing: t("discover.thisWeek")).padding(.horizontal, 20)
            VStack(spacing: 0) {
                ForEach(Array(trending.prefix(5).enumerated()), id: \.offset) { i, n in
                    if let h = book.hymn(n) {
                        NavigationLink(value: n) {
                            HStack(spacing: 14) {
                                Text("\(i + 1)").font(.serif(22, .bold)).foregroundStyle(i < 3 ? Color.brand : Color.inkFaint).frame(width: 26)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(h.title).font(.body.weight(.medium)).foregroundStyle(Color.ink).lineLimit(1)
                                    Text("\(h.number) · \(h.section)").font(.caption).foregroundStyle(Color.inkSoft).lineLimit(1)
                                }
                                Spacer(minLength: 6)
                                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(Color.inkFaint)
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 60)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if i < min(5, trending.count) - 1 { Divider().padding(.leading, 56) }
                    }
                }
            }
            .background(Color.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.stroke, lineWidth: 1))
            .padding(.horizontal, 20)
        }
    }

    // MARK: For this moment

    private var momentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: momentTitle).padding(.horizontal, 20)
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(momentHymns) { h in
                        NavigationLink(value: h.number) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("\(h.number)").font(.serif(30, .semibold)).foregroundStyle(.white)
                                Spacer()
                                Text(h.title).font(.subheadline.weight(.semibold)).foregroundStyle(.white).lineLimit(1)
                            }
                            .padding(16)
                            .frame(width: 160, height: 160, alignment: .leading)
                            .background(LinearGradient(colors: momentColors, startPoint: .topLeading, endPoint: .bottomTrailing),
                                        in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var momentTitle: String {
        switch moment {
        case .morning: t("discover.morning")
        case .evening: t("discover.evening")
        case .sabbath: t("discover.sabbath")
        case .praise: t("discover.praise")
        }
    }

    private var momentColors: [Color] {
        switch moment {
        case .morning: [Color(hex: "F59E0B"), Color(hex: "E3643B")]
        case .evening: [Color(hex: "4338CA"), Color(hex: "1E1B4B")]
        case .sabbath: Color.sea
        case .praise: [Color(hex: "0EA5A4"), Color(hex: "0B6F9F")]
        }
    }

    // MARK: Themes

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: t("discover.themes")).padding(.horizontal, 20)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(Self.themes, id: \.name) { theme in
                    let count = book.sections.filter { $0.name == theme.name }.reduce(0) { $0 + $1.hymns.count }
                    NavigationLink(value: DiscoverRoute.theme(theme.name)) {
                        HStack(spacing: 12) {
                            Image(systemName: theme.symbol)
                                .font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(Color(hex: theme.tint).gradient, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(theme.name).font(.subheadline.weight(.semibold)).foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.85)
                                Text(t("lists.hymnsCount", ["n": count])).font(.caption).foregroundStyle(Color.inkSoft).lineLimit(1)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(12)
                        .background(Color.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.stroke, lineWidth: 1))
                    }
                    .buttonStyle(PressableStyle())
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: Stories

    private var storySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: t("discover.stories")).padding(.horizontal, 20)
            ScrollView(.horizontal) {
                HStack(spacing: 14) {
                    ForEach(stories) { story in
                        if let h = book.hymn(story.hymn) {
                            NavigationLink(value: h.number) {
                                VStack(alignment: .leading, spacing: 0) {
                                    Photo(key: story.photo).frame(height: 150).clipped()
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(h.title).font(.headline).foregroundStyle(Color.ink).lineLimit(1)
                                        Text(story.text).font(.footnote).foregroundStyle(Color.inkSoft).lineLimit(3).multilineTextAlignment(.leading)
                                    }
                                    .padding(14)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .frame(width: 260, height: 260, alignment: .top)
                                .background(Color.card)
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.stroke, lineWidth: 1))
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

    // MARK: Writers

    private var writersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: t("discover.writers")).padding(.horizontal, 20)
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(book.writers) { w in
                        NavigationLink(value: DiscoverRoute.writer(w.name)) {
                            VStack(spacing: 8) {
                                Photo(key: w.photo)
                                    .frame(width: 84, height: 84)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.brand.opacity(0.6), lineWidth: 2).padding(-3))
                                Text(w.name).font(.caption.weight(.semibold)).foregroundStyle(Color.ink).lineLimit(1)
                                Text(t("discover.hymnsCount", ["n": book.hymns(by: w).count])).font(.caption2).foregroundStyle(Color.inkSoft).lineLimit(1)
                            }
                            .frame(width: 96)
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: Did you know

    private var factsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: t("discover.didYouKnow")).padding(.horizontal, 20)
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(Array(DiscoverModel.facts.enumerated()), id: \.offset) { _, fact in
                        VStack(alignment: .leading, spacing: 12) {
                            Image(systemName: fact.symbol).font(.title3).foregroundStyle(Color.brand)
                            Text(fact.text).font(.serif(16)).foregroundStyle(Color.ink).lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                        .padding(18)
                        .frame(width: 250, height: 170, alignment: .topLeading)
                        .background(Color.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.stroke, lineWidth: 1))
                    }
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: More

    private var moreSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionTitle(text: t("discover.more")).padding(.horizontal, 20).padding(.bottom, 4)
            ForEach(more) { h in
                NavigationLink(value: h.number) { HymnRow(hymn: h, subtitle: h.section, saved: library.isSaved(h.number)) }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
            }
        }
    }
}

/// A hymn writer: their story and their hymns in the book.
struct WriterView: View {
    let writer: Writer
    @EnvironmentObject private var library: Library

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 16) {
                        Photo(key: writer.photo).frame(width: 72, height: 72).clipShape(Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(writer.name).font(.serif(22, .semibold)).lineLimit(1)
                            Text(writer.years).font(.subheadline).foregroundStyle(Color.inkSoft).lineLimit(1)
                        }
                    }
                    Text(writer.text).font(.serif(17)).lineSpacing(5)
                }
                .padding(.vertical, 6)
            }
            Section(t("discover.theirHymns")) {
                ForEach(HymnBook.shared.hymns(by: writer)) { h in
                    NavigationLink(value: h.number) { HymnRow(hymn: h, saved: library.isSaved(h.number)) }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(writer.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }
}
