import SwiftUI

/// Make a picture of a hymn to share: pick a look, a shape and a verse.
struct ShareCardView: View {
    let hymn: Hymn
    @Environment(\.dismiss) private var dismiss
    @State private var style: CardStyle = .sea
    @State private var format: CardFormat = .post
    @State private var verseIndex: Int = 0
    @State private var rendered: UIImage?
    @State private var savedAlert = false

    private var verses: [Verse] { HymnBook.shared.verses(of: hymn) }
    private var verse: Verse? { verses.indices.contains(verseIndex) ? verses[verseIndex] : nil }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                GeometryReader { geo in
                    let fit = min(geo.size.width / format.size.width, geo.size.height / format.size.height)
                    card
                        .scaleEffect(fit, anchor: .center)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .shadow(color: .black.opacity(0.25), radius: 24, y: 10)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: format)

                VStack(spacing: 16) {
                    picker(CardFormat.allCases, selection: $format) { Text($0.label) }
                    ScrollView(.horizontal) {
                        HStack(spacing: 12) {
                            ForEach(CardStyle.allCases) { s in
                                Button { withAnimation { style = s } } label: {
                                    VStack(spacing: 6) {
                                        Circle().fill(s.background).frame(width: 46, height: 46)
                                            .overlay(Circle().stroke(style == s ? Color.brand : Color.stroke, lineWidth: style == s ? 3 : 1))
                                        Text(s.label).font(.caption2.weight(.medium)).foregroundStyle(style == s ? Color.ink : Color.inkSoft).lineLimit(1)
                                    }
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(s.label)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .scrollIndicators(.hidden)
                    if !verses.isEmpty {
                        ScrollView(.horizontal) {
                            HStack(spacing: 8) {
                                chip(t("card.titleOnly"), selected: verseIndex == -1) { verseIndex = -1 }
                                ForEach(verses.indices, id: \.self) { i in
                                    chip(verses[i].isRefrain ? t("card.refrain") : t("card.verseN", ["n": verses[i].number]), selected: verseIndex == i) { verseIndex = i }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .scrollIndicators(.hidden)
                    }
                    HStack(spacing: 12) {
                        Button { save() } label: {
                            Label(t("card.save"), systemImage: "arrow.down.to.line")
                        }
                        .buttonStyle(PrimaryButtonStyle(tint: Color.card, foreground: Color.ink))
                        if let image = rendered {
                            ShareLink(item: Image(uiImage: image), preview: SharePreview("\(hymn.number) · \(hymn.title)", image: Image(uiImage: image))) {
                                Label(t("card.share"), systemImage: "square.and.arrow.up")
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .simultaneousGesture(TapGesture().onEnded { HymnalAPI.shared.track("card", hymn: hymn.number, detail: "\(style.rawValue)/\(format.rawValue)") })
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 10)
            }
            .background(Color.bg)
            .navigationTitle(t("card.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }.accessibilityLabel(t("common.close"))
                }
            }
            .alert(t("card.saved"), isPresented: $savedAlert) { Button(t("common.ok"), role: .cancel) {} }
            .onAppear {
                if !hymn.hasWords { verseIndex = -1 }
                render()
            }
            .onChange(of: style) { _, _ in render() }
            .onChange(of: format) { _, _ in render() }
            .onChange(of: verseIndex) { _, _ in render() }
        }
    }

    private var card: some View {
        HymnCard(hymn: hymn, verse: verseIndex >= 0 ? verse : nil, style: style, format: format)
            .frame(width: format.size.width, height: format.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    @MainActor private func render() {
        let renderer = ImageRenderer(content: HymnCard(hymn: hymn, verse: verseIndex >= 0 ? verse : nil, style: style, format: format)
            .frame(width: format.size.width, height: format.size.height))
        renderer.scale = 1080 / format.size.width
        rendered = renderer.uiImage
    }

    private func save() {
        render()
        guard let image = rendered else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        HymnalAPI.shared.track("card", hymn: hymn.number, detail: "saved")
        savedAlert = true
    }

    private func chip(_ text: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: { withAnimation { action() } }) {
            Text(text).font(.subheadline.weight(.medium)).lineLimit(1)
                .foregroundStyle(selected ? .white : Color.ink)
                .padding(.horizontal, 14).frame(height: 36)
                .background(selected ? Color.brand : Color.card, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func picker<T: Hashable & Identifiable, L: View>(_ items: [T], selection: Binding<T>, label: @escaping (T) -> L) -> some View {
        Picker("", selection: selection) {
            ForEach(items) { label($0).tag($0) }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 20)
    }
}

enum CardFormat: String, CaseIterable, Identifiable {
    case square, post, story
    var id: String { rawValue }
    var size: CGSize {
        switch self {
        case .square: CGSize(width: 360, height: 360)
        case .post: CGSize(width: 360, height: 450)
        case .story: CGSize(width: 360, height: 640)
        }
    }
    var label: String { t("card.\(rawValue)") }
}

enum CardStyle: String, CaseIterable, Identifiable {
    case sea, sunrise, night, paper, forest
    var id: String { rawValue }
    var label: String { t("card.style.\(rawValue)") }

    var background: LinearGradient {
        let colors: [Color]
        switch self {
        case .sea: colors = Color.sea
        case .sunrise: colors = [Color(hex: "F6A15A"), Color(hex: "D9566B"), Color(hex: "6B3A8C")]
        case .night: colors = [Color(hex: "151B2E"), Color(hex: "0A0D18")]
        case .paper: colors = [Color(hex: "FBF6EC"), Color(hex: "EFE5D2")]
        case .forest: colors = [Color(hex: "2F6B4F"), Color(hex: "163828")]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    var ink: Color { self == .paper ? Color(hex: "2A2118") : .white }
    var accent: Color {
        switch self {
        case .paper: Color(hex: "0B6F9F")
        case .night: Color(hex: "7CC4EC")
        default: .white.opacity(0.75)
        }
    }
}

/// The picture itself.
struct HymnCard: View {
    let hymn: Hymn
    let verse: Verse?
    let style: CardStyle
    let format: CardFormat

    private var bodySize: CGFloat {
        guard let verse else { return 18 }
        let lines = verse.text.split(separator: "\n").count
        let longest = verse.text.split(separator: "\n").map(\.count).max() ?? 30
        let byHeight = (format.size.height - 200) / CGFloat(max(lines, 4)) / 1.55
        let byWidth = (format.size.width - 60) / CGFloat(max(longest, 18)) * 1.9
        return min(22, byHeight, byWidth)
    }

    var body: some View {
        ZStack {
            style.background
            if style != .paper {
                SDALogo(size: format.size.width * 0.9, color: .white.opacity(0.05))
                    .offset(x: format.size.width * 0.3, y: format.size.height * 0.22)
            }
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    SDALogo(size: 22, color: style.ink)
                    Text("SDA Hymnal").font(.system(size: 12, weight: .semibold)).foregroundStyle(style.ink.opacity(0.85))
                    Spacer()
                    Text("\(hymn.number)").font(.serif(15, .semibold)).foregroundStyle(style.accent)
                }
                Spacer(minLength: 14)
                if let verse {
                    Text(verse.text)
                        .font(.serif(bodySize))
                        .italic(verse.isRefrain)
                        .foregroundStyle(style.ink)
                        .lineSpacing(bodySize * 0.4)
                        .minimumScaleFactor(0.6)
                    Spacer(minLength: 18)
                    Rectangle().fill(style.accent).frame(width: 34, height: 2).padding(.bottom, 12)
                    Text(hymn.title).font(.serif(17, .semibold)).foregroundStyle(style.ink).lineLimit(2)
                } else {
                    Text("\(hymn.number)").font(.serif(72, .semibold)).foregroundStyle(style.accent)
                    Text(hymn.title).font(.serif(32, .semibold)).foregroundStyle(style.ink).lineLimit(4).minimumScaleFactor(0.6)
                    Spacer(minLength: 18)
                }
                if !hymn.author.isEmpty {
                    Text(hymn.author).font(.serif(12).italic()).foregroundStyle(style.ink.opacity(0.7)).lineLimit(1).padding(.top, 4)
                }
            }
            .padding(28)
        }
        .environment(\.colorScheme, .light)
    }
}
