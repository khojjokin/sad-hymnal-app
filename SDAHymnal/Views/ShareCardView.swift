import SwiftUI
import PhotosUI

/// Make a picture of a hymn to share: pick a look, a shape and a verse.
struct ShareCardView: View {
    let hymn: Hymn
    @Environment(\.dismiss) private var dismiss
    @State private var style: CardStyle = .sea
    @State private var format: CardFormat = .post
    @State private var verseIndex: Int = 0
    @State private var rendered: UIImage?
    @State private var savedAlert = false
    @State private var font: CardFont = .serif
    @State private var photoItem: PhotosPickerItem?
    @State private var photo: UIImage?
    @State private var showPlus = false
    @ObservedObject private var plus = Plus.shared

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

                controls
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
            .onChange(of: font) { _, _ in render() }
            .onChange(of: photo) { _, _ in render() }
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self), let img = UIImage(data: data) {
                        photo = img.preparingThumbnail(of: CGSize(width: 1400, height: 1400)) ?? img
                    }
                }
            }
            .fullScreenCover(isPresented: $showPlus) { PlusView() }
        }
    }

    /// Shape, look, lettering, verse and the buttons, under the preview.
    private var controls: some View {
        VStack(spacing: 16) {
            picker(CardFormat.allCases, selection: $format) { Text($0.label) }
            styleRow
            fontRow
            if !verses.isEmpty { verseRow }
            actionRow
        }
    }

    private var styleRow: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                photoButton
                ForEach(CardStyle.allCases) { s in styleButton(s) }
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
    }

    private func styleButton(_ s: CardStyle) -> some View {
        let chosen: Bool = style == s && photo == nil
        let locked: Bool = s.premium && !plus.isPlus
        let ring: Color = chosen ? Color.brand : Color.stroke
        let width: CGFloat = chosen ? 3 : 1
        return Button {
            if locked { showPlus = true } else { withAnimation { style = s; photo = nil } }
        } label: {
            VStack(spacing: 6) {
                Circle().fill(s.background).frame(width: 46, height: 46)
                    .overlay(Circle().stroke(ring, lineWidth: width))
                    .overlay(alignment: .topTrailing) { lockBadge(locked) }
                Text(s.label).font(.caption2.weight(.medium)).foregroundStyle(chosen ? Color.ink : Color.inkSoft).lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(s.label)
    }

    @ViewBuilder private func lockBadge(_ locked: Bool) -> some View {
        if locked { PlusBadge().offset(x: 8, y: -4) }
    }

    private var fontRow: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(CardFont.allCases) { f in fontButton(f) }
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
    }

    private func fontButton(_ f: CardFont) -> some View {
        let chosen: Bool = font == f
        let locked: Bool = f.premium && !plus.isPlus
        let ink: Color = chosen ? .white : Color.ink
        let fill: Color = chosen ? Color.brand : Color.card
        return Button {
            if locked { showPlus = true } else { withAnimation { font = f } }
        } label: {
            HStack(spacing: 6) {
                Text("Aa").font(f.font(15, .semibold))
                Text(f.label).font(.subheadline.weight(.medium)).lineLimit(1)
                if locked { PlusBadge() }
            }
            .foregroundStyle(ink)
            .padding(.horizontal, 14).frame(height: 36)
            .background(fill, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var verseRow: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                chip(t("card.titleOnly"), selected: verseIndex == -1) { verseIndex = -1 }
                ForEach(verses.indices, id: \.self) { i in
                    chip(verseName(i), selected: verseIndex == i) { verseIndex = i }
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
    }

    private func verseName(_ i: Int) -> String {
        verses[i].isRefrain ? t("card.refrain") : t("card.verseN", ["n": verses[i].number])
    }

    private var actionRow: some View {
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

    private var card: some View {
        HymnCard(hymn: hymn, verse: verseIndex >= 0 ? verse : nil, style: style, format: format, font: font, photo: photo)
            .frame(width: format.size.width, height: format.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    @MainActor private func render() {
        let renderer = ImageRenderer(content: HymnCard(hymn: hymn, verse: verseIndex >= 0 ? verse : nil, style: style, format: format, font: font, photo: photo)
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

    /// Plus: your own photo behind the words.
    @ViewBuilder private var photoButton: some View {
        if plus.isPlus {
            PhotosPicker(selection: $photoItem, matching: .images) { photoLabel }
                .buttonStyle(.plain)
        } else {
            Button { showPlus = true } label: { photoLabel }.buttonStyle(.plain)
        }
    }

    private var photoLabel: some View {
        VStack(spacing: 6) {
            ZStack {
                if let photo {
                    Image(uiImage: photo).resizable().scaledToFill()
                } else {
                    Color.card
                    Image(systemName: "photo.badge.plus").font(.system(size: 18)).foregroundStyle(Color.inkSoft)
                }
            }
            .frame(width: 46, height: 46)
            .clipShape(Circle())
            .overlay(Circle().stroke(photo != nil ? Color.brand : Color.stroke, lineWidth: CGFloat(photo != nil ? 3 : 1)))
            .overlay(alignment: .topTrailing) { if !plus.isPlus { PlusBadge().offset(x: 8, y: -4) } }
            Text(t("card.photo")).font(.caption2.weight(.medium)).foregroundStyle(Color.inkSoft).lineLimit(1)
        }
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
    case sea, sunrise, night, paper, forest, gilded, rose, slate, aurora
    var id: String { rawValue }
    /// The last four come with Plus.
    var premium: Bool { [.gilded, .rose, .slate, .aurora].contains(self) }
    var label: String { t("card.style.\(rawValue)") }

    var background: LinearGradient {
        let colors: [Color]
        switch self {
        case .sea: colors = Color.sea
        case .sunrise: colors = [Color(hex: "F6A15A"), Color(hex: "D9566B"), Color(hex: "6B3A8C")]
        case .night: colors = [Color(hex: "151B2E"), Color(hex: "0A0D18")]
        case .paper: colors = [Color(hex: "FBF6EC"), Color(hex: "EFE5D2")]
        case .forest: colors = [Color(hex: "2F6B4F"), Color(hex: "163828")]
        case .gilded: colors = [Color(hex: "0B1B2E"), Color(hex: "13304D"), Color(hex: "0B1B2E")]
        case .rose: colors = [Color(hex: "F9D9D6"), Color(hex: "E9A8B3"), Color(hex: "B76E86")]
        case .slate: colors = [Color(hex: "3A4250"), Color(hex: "1F242C")]
        case .aurora: colors = [Color(hex: "0F766E"), Color(hex: "4338CA"), Color(hex: "7E22CE")]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    var ink: Color {
        switch self {
        case .paper: Color(hex: "2A2118")
        case .rose: Color(hex: "3B1424")
        case .gilded: Color(hex: "F5E6C4")
        default: .white
        }
    }
    var accent: Color {
        switch self {
        case .paper: Color(hex: "0B6F9F")
        case .night: Color(hex: "7CC4EC")
        case .gilded: Color(hex: "E0B354")
        case .rose: Color(hex: "7A2E48")
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
    var font: CardFont = .serif
    var photo: UIImage? = nil

    private var ink: Color { photo == nil ? style.ink : .white }
    private var accent: Color { photo == nil ? style.accent : .white.opacity(0.8) }

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
            if let photo {
                Image(uiImage: photo).resizable().scaledToFill()
                    .frame(width: format.size.width, height: format.size.height).clipped()
                LinearGradient(colors: [.black.opacity(0.25), .black.opacity(0.35), .black.opacity(0.7)], startPoint: .top, endPoint: .bottom)
            } else {
                style.background
                if style != .paper && style != .rose {
                    SDALogo(size: format.size.width * 0.9, color: .white.opacity(0.05))
                        .offset(x: format.size.width * 0.3, y: format.size.height * 0.22)
                }
                if style == .gilded {
                    RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "E0B354").opacity(0.55), lineWidth: 1).padding(14)
                }
            }
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    SDALogo(size: 22, color: ink)
                    Text("SDA Hymnal").font(.system(size: 12, weight: .semibold)).foregroundStyle(ink.opacity(0.85))
                    Spacer()
                    Text("\(hymn.number)").font(font.font(15, .semibold)).foregroundStyle(accent)
                }
                Spacer(minLength: 14)
                if let verse {
                    Text(verse.text)
                        .font(font.font(bodySize))
                        .italic(verse.isRefrain)
                        .foregroundStyle(ink)
                        .lineSpacing(bodySize * 0.4)
                        .minimumScaleFactor(0.6)
                    Spacer(minLength: 18)
                    Rectangle().fill(accent).frame(width: 34, height: 2).padding(.bottom, 12)
                    Text(hymn.title).font(font.font(17, .semibold)).foregroundStyle(ink).lineLimit(2)
                } else {
                    Text("\(hymn.number)").font(font.font(72, .semibold)).foregroundStyle(accent)
                    Text(hymn.title).font(font.font(32, .semibold)).foregroundStyle(ink).lineLimit(4).minimumScaleFactor(0.6)
                    Spacer(minLength: 18)
                }
                if !hymn.author.isEmpty {
                    Text(hymn.author).font(font.font(12).italic()).foregroundStyle(ink.opacity(0.7)).lineLimit(1).padding(.top, 4)
                }
            }
            .padding(28)
        }
        .environment(\.colorScheme, .light)
    }
}

/// The lettering on a card. Serif is free; the others come with Plus.
enum CardFont: String, CaseIterable, Identifiable {
    case serif, modern, rounded, typewriter
    var id: String { rawValue }
    var premium: Bool { self != .serif }
    var label: String { t("card.font.\(rawValue)") }
    func font(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        switch self {
        case .serif: .system(size: size, weight: weight, design: .serif)
        case .modern: .system(size: size, weight: weight, design: .default)
        case .rounded: .system(size: size, weight: weight, design: .rounded)
        case .typewriter: .system(size: size * 0.92, weight: weight, design: .monospaced)
        }
    }
}
