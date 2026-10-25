import SwiftUI

/// One of the app's photographs (the same set as Sanctuary's), with its own colours underneath while it loads
/// or when offline, so a banner or card always looks finished.
struct Photo: View {
    let key: String
    var height: CGFloat? = nil

    static let ids: [String: (id: String, tone: [String])] = [
        "tileHymnal": ("photo-1536777525605-e146b6cef617", ["6F8FB3", "34506E", "16222F"]),
        "hymnal": ("photo-1482627988233-7c68311232ea", ["8A2440", "46205A", "1C1430"]),
        "emptyExplore": ("photo-1604223190546-a43e4c7f29d7", ["F3A65A", "A9584A", "2E2340"]),
        "hymnOfDay": ("photo-1745000769767-2198d91b750b", ["8A5A3B", "4A2C1F"]),
        "emptyMusic": ("photo-1509343456624-5e034c8f321c", ["8A6A4E", "3F2E22", "141010"]),
        "service": ("photo-1574642631319-ee4e726c5888", ["24418C", "101A38"]),
        "prayer": ("photo-1694588063491-b6dcddc85c97", ["3D2712", "120B06"]),
        "bibleStudy": ("photo-1469228252629-cbe7cb7db2c8", ["7B6A5A", "3B3440"]),
        "emptyWrite": ("photo-1456324504439-367cee3b3c32", ["CFCAC2", "8F8A83", "3B3936"]),
    ]

    var body: some View {
        let entry = Photo.ids[key] ?? Photo.ids["tileHymnal"]!
        let tone = LinearGradient(colors: entry.tone.map { Color(hex: $0) }, startPoint: .topLeading, endPoint: .bottomTrailing)
        GeometryReader { geo in
            AsyncImage(url: URL(string: "https://images.unsplash.com/\(entry.id)?auto=format&fit=crop&w=\(Int(max(geo.size.width, 300) * 3))&q=80"),
                       transaction: Transaction(animation: .easeOut(duration: 0.25))) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    tone
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .frame(height: height)
        .background(tone)
        .accessibilityHidden(true)
    }
}

/// A hymn in a list: its number, then its title (one line).
struct HymnRow: View {
    let hymn: Hymn
    var subtitle: String? = nil
    var saved = false

    var body: some View {
        HStack(spacing: 14) {
            Text("\(hymn.number)")
                .font(.serif(19, .medium))
                .monospacedDigit()
                .foregroundStyle(Color.brand)
                .frame(width: 44, alignment: .trailing)
            VStack(alignment: .leading, spacing: 2) {
                Text(hymn.title).font(.body.weight(.medium)).foregroundStyle(Color.ink).lineLimit(1)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle).font(.footnote).foregroundStyle(Color.inkSoft).lineLimit(1)
                }
            }
            Spacer(minLength: 4)
            if saved { Image(systemName: "bookmark.fill").font(.caption).foregroundStyle(Color.brand) }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// A small heading over a group of rows.
struct SectionTitle: View {
    let text: String
    var trailing: String? = nil
    var body: some View {
        HStack {
            Text(text).font(.title3.weight(.bold)).foregroundStyle(Color.ink).lineLimit(1)
            Spacer()
            if let trailing { Text(trailing).font(.subheadline).foregroundStyle(Color.inkSoft).lineLimit(1) }
        }
    }
}

/// A centred pop-up card over a dimmed screen (never a bottom sheet).
struct CenteredOverlay<Content: View>: View {
    @Binding var isPresented: Bool
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            if isPresented {
                Color.black.opacity(0.35).ignoresSafeArea()
                    .onTapGesture { withAnimation(.easeOut(duration: 0.2)) { isPresented = false } }
                    .transition(.opacity)
                content()
                    .frame(maxWidth: 360)
                    .padding(22)
                    .background(Color.bg, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .shadow(color: .black.opacity(0.25), radius: 30, y: 10)
                    .padding(24)
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isPresented)
    }
}

/// Go to a hymn by its number, like the hymn board at the front of the church.
struct NumberPad: View {
    @Binding var isPresented: Bool
    var open: (Int) -> Void
    @State private var digits = ""

    private var number: Int { Int(digits) ?? 0 }
    private var hymn: Hymn? { HymnBook.shared.hymn(number) }

    var body: some View {
        VStack(spacing: 14) {
            Text(t("pad.title")).font(.headline).foregroundStyle(Color.ink)
            VStack(spacing: 2) {
                Text(digits.isEmpty ? "—" : digits)
                    .font(.serif(58, .semibold)).monospacedDigit()
                    .foregroundStyle(digits.isEmpty ? Color.inkFaint : Color.brand)
                Text(hymn?.title ?? t("pad.range", ["n": HymnBook.shared.count]))
                    .font(.serif(17).italic()).foregroundStyle(hymn == nil ? Color.inkFaint : Color.ink).lineLimit(1)
            }
            .frame(height: 96)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(["1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", "del"], id: \.self) { k in
                    if k.isEmpty {
                        Color.clear.frame(height: 54)
                    } else {
                        Button { press(k) } label: {
                            Group {
                                if k == "del" { Image(systemName: "delete.left").font(.title3) } else { Text(k).font(.serif(26, .medium)) }
                            }
                            .foregroundStyle(Color.ink)
                            .frame(maxWidth: .infinity, minHeight: 54)
                            .background(Color.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(PressableStyle())
                        .accessibilityLabel(k == "del" ? t("pad.delete") : k)
                    }
                }
            }
            Button {
                guard let h = hymn else { return }
                isPresented = false
                digits = ""
                open(h.number)
            } label: { Text(hymn.map { t("pad.openN", ["n": $0.number]) } ?? t("pad.open")) }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(hymn == nil)
            .opacity(hymn == nil ? 0.5 : 1)
        }
    }

    private func press(_ k: String) {
        UISelectionFeedbackGenerator().selectionChanged()
        if k == "del" { digits = String(digits.dropLast()); return }
        let next = String((digits + k).drop(while: { $0 == "0" }))
        if (Int(next) ?? 0) <= HymnBook.shared.count && next.count <= 3 { digits = next }
    }
}

/// A message across the top from the console (announcement or maintenance).
struct AnnouncementBanner: View {
    let text: String
    var onClose: (() -> Void)?
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "megaphone.fill").foregroundStyle(Color.brand)
            Text(text).font(.footnote.weight(.medium)).foregroundStyle(Color.ink).lineLimit(1)
            Spacer(minLength: 0)
            if let onClose {
                Button(action: onClose) { Image(systemName: "xmark").font(.caption.weight(.bold)).foregroundStyle(Color.inkSoft) }
                    .accessibilityLabel(t("common.close"))
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .glass(18)
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }
}

/// A photo cover for a hymn, like an album cover. Each hymn always gets the same photo.
struct HymnCover: View {
    let hymn: Hymn
    var radius: CGFloat = 14
    var showsNumber = true

    static let keys = ["tileHymnal", "service", "emptyExplore", "prayer", "hymnOfDay", "bibleStudy", "emptyMusic", "hymnal", "emptyWrite"]

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Photo(key: Self.keys[hymn.number % Self.keys.count])
            LinearGradient(colors: [.clear, .black.opacity(0.65)], startPoint: .center, endPoint: .bottom)
            if showsNumber {
                Text("\(hymn.number)")
                    .font(.serif(18, .bold))
                    .foregroundStyle(.white)
                    .padding(8)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .accessibilityHidden(true)
    }
}
