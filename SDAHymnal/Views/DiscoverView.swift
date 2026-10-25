import SwiftUI

/// What Discover shows today. The same picks all day; the shuffle button deals a fresh set.
enum DiscoverModel {
    static func hymnOfDay(shuffle: Int = 0, featured: Int? = nil) -> Hymn {
        let book = HymnBook.shared
        if shuffle == 0, let featured, let h = book.hymn(featured) { return h }
        return book.pick(book.withWords, day: HymnBook.dayNumber(), shuffle: shuffle, stride: 37)
    }
}

struct DiscoverView: View {
    @EnvironmentObject private var app: AppState
    @EnvironmentObject private var library: Library
    @State private var shuffle = 0
    @State private var spin = 0.0

    private let book = HymnBook.shared

    private var today: Hymn { DiscoverModel.hymnOfDay(shuffle: shuffle, featured: app.config.featuredHymn) }
    private var moment: HymnBook.Moment { HymnBook.moment() }
    private var momentHymns: [Hymn] {
        let list = book.hymns(for: moment)
        guard !list.isEmpty else { return [] }
        return (0..<min(6, list.count)).map { i in book.pick(list, day: HymnBook.dayNumber() + i, shuffle: shuffle, stride: 7) }
            .reduce(into: [Hymn]()) { out, h in if !out.contains(h) { out.append(h) } }
    }
    private var stories: [Story] {
        guard !book.stories.isEmpty else { return [] }
        let start = (HymnBook.dayNumber() + shuffle * 5) % book.stories.count
        return (0..<min(8, book.stories.count)).map { book.stories[(start + $0) % book.stories.count] }
    }
    private var writer: Writer? {
        book.writers.isEmpty ? nil : book.pick(book.writers, day: HymnBook.dayNumber(), shuffle: shuffle, stride: 3)
    }
    private var more: [Hymn] {
        (1...5).map { book.pick(book.withWords, day: HymnBook.dayNumber() + $0 * 11, shuffle: shuffle, stride: 53) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    header
                    hymnOfDay
                    if !momentHymns.isEmpty { momentSection }
                    if !stories.isEmpty { storySection }
                    if let writer { writerSection(writer) }
                    moreSection
                }
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .background(Color.bg)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Int.self) { HymnView(number: $0) }
            .navigationDestination(for: String.self) { name in
                if let w = book.writers.first(where: { $0.name == name }) { WriterView(writer: w) }
            }
            .animation(.easeInOut(duration: 0.3), value: shuffle)
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()).uppercased())
                    .font(.caption.weight(.semibold)).tracking(1).foregroundStyle(Color.inkSoft).lineLimit(1)
                Text(t("tab.discover")).font(.serif(34, .semibold)).foregroundStyle(Color.ink).lineLimit(1)
            }
            Spacer()
            Button {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                withAnimation(.spring(response: 0.5)) { spin += 360 }
                shuffle += 1
            } label: {
                Image(systemName: "shuffle").font(.system(size: 17, weight: .semibold)).foregroundStyle(Color.ink)
                    .rotationEffect(.degrees(spin))
                    .frame(width: 44, height: 44)
                    .glassCircle()
            }
            .accessibilityLabel(t("discover.shuffle"))
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var hymnOfDay: some View {
        NavigationLink(value: today.number) {
            ZStack(alignment: .bottomLeading) {
                Photo(key: "hymnOfDay")
                LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 8) {
                    Text(t("discover.hymnOfDay")).font(.caption.weight(.bold)).textCase(.uppercase).tracking(1.2)
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .glass(12)
                    Text("\(today.number)").font(.serif(44, .semibold)).foregroundStyle(.white)
                    Text(today.title).font(.serif(26, .semibold)).foregroundStyle(.white).lineLimit(2).multilineTextAlignment(.leading)
                    if let first = book.verses(of: today).first {
                        Text(first.text.split(separator: "\n").prefix(2).joined(separator: " "))
                            .font(.serif(15).italic()).foregroundStyle(.white.opacity(0.8)).lineLimit(2).multilineTextAlignment(.leading)
                    }
                }
                .padding(22)
            }
            .frame(height: 400)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .padding(.horizontal, 20)
        }
        .buttonStyle(PressableStyle())
        .id("today-\(today.number)")
        .transition(.opacity)
    }

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
                                Text(h.title).font(.subheadline.weight(.semibold)).foregroundStyle(.white).lineLimit(2).multilineTextAlignment(.leading)
                            }
                            .padding(16)
                            .frame(width: 160, height: 170, alignment: .leading)
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

    private func writerSection(_ w: Writer) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: t("discover.writer")).padding(.horizontal, 20)
            NavigationLink(value: w.name) {
                HStack(spacing: 16) {
                    Photo(key: w.photo).frame(width: 84, height: 84).clipShape(Circle())
                    VStack(alignment: .leading, spacing: 4) {
                        Text(w.name).font(.serif(21, .semibold)).foregroundStyle(Color.ink).lineLimit(1)
                        Text(w.years).font(.subheadline).foregroundStyle(Color.inkSoft).lineLimit(1)
                        Text(t("discover.hymnsCount", ["n": book.hymns(by: w).count])).font(.footnote.weight(.semibold)).foregroundStyle(Color.brand).lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(Color.inkFaint)
                }
                .card()
            }
            .buttonStyle(PressableStyle())
            .padding(.horizontal, 20)
        }
    }

    private var moreSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionTitle(text: t("discover.more")).padding(.horizontal, 20).padding(.bottom, 4)
            ForEach(more.reduce(into: [Hymn]()) { o, h in if !o.contains(h) { o.append(h) } }) { h in
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
