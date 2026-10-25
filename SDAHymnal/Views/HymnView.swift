import SwiftUI

struct HymnView: View {
    let number: Int
    @EnvironmentObject private var library: Library
    @EnvironmentObject private var prefs: Prefs
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var current: Int
    @State private var showShare = false
    @State private var showLists = false
    @State private var showActions = false
    @State private var showProjector = false
    @State private var showPlus = false
    @State private var showStory = false
    @State private var copied = false

    private let book = HymnBook.shared

    init(number: Int) {
        self.number = number
        _current = State(initialValue: number)
    }

    private var hymn: Hymn { book.hymn(current) ?? book.hymns[0] }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    if hymn.hasWords { words } else { noWords }
                    if let story = book.story(for: hymn.number) { storyCard(story) }
                    footer
                    // Free plan: one quiet banner at the very end, after the words, never in the middle of a hymn.
                    AdCard().padding(.top, 28)
                }
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
            .background(Color.bg)
            .id(current)

            CenteredOverlay(isPresented: $showActions) {
                HymnActions(hymn: hymn, shareText: shareText) { action in
                    showActions = false
                    switch action {
                    case .share: showShare = true
                    case .list: showLists = true
                    case .copy: UIPasteboard.general.string = shareText; copied = true
                    case .projector: if Plus.shared.isPlus { showProjector = true } else { showPlus = true }
                    }
                }
            }
            CenteredOverlay(isPresented: $showLists) {
                AddToListCard(hymn: hymn.number, isPresented: $showLists)
            }
        }
        .safeAreaInset(edge: .bottom) { controls }
        .navigationTitle("\(hymn.number)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .hidesTabBar()
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { withAnimation(.spring(response: 0.3)) { library.toggleSave(hymn.number) }; UIImpactFeedbackGenerator(style: .light).impactOccurred() } label: {
                    Image(systemName: library.isSaved(hymn.number) ? "bookmark.fill" : "bookmark")
                        .contentTransition(.symbolEffect(.replace))
                }
                .accessibilityLabel(library.isSaved(hymn.number) ? t("hymn.unsave") : t("hymn.save"))
                Button { showActions = true } label: { Image(systemName: "ellipsis") }
                    .accessibilityLabel(t("hymn.more"))
            }
        }
        .fullScreenCover(isPresented: $showShare) { ShareCardView(hymn: hymn) }
        .fullScreenCover(isPresented: $showProjector) { ProjectorView(hymn: hymn) }
        .fullScreenCover(isPresented: $showPlus) { PlusView() }
        .fullScreenCover(isPresented: $showStory) {
            if let story = book.story(for: hymn.number) { StoryView(story: story) }
        }
        .alert(t("hymn.copied"), isPresented: $copied) { Button(t("common.ok"), role: .cancel) {} }
        .onAppear { opened() }
        .onChange(of: current) { _, _ in opened() }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            ReviewPrompt.hymnClosed()
        }
    }

    private func opened() {
        library.opened(hymn.number)
        ReviewPrompt.hymnOpened()
        HymnalAPI.shared.track("open", hymn: hymn.number)
        UIApplication.shared.isIdleTimerDisabled = prefs.keepAwake
    }

    private var shareText: String {
        var s = "\(hymn.number) · \(hymn.title)\n"
        if hymn.hasWords { s += "\n" + book.plainWords(hymn) + "\n" }
        if !hymn.author.isEmpty { s += "\n\(hymn.author)" }
        s += "\n\n" + t("share.footer")
        return s
    }

    // MARK: Parts

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text("\(hymn.number)")
                    .font(.serif(20, .semibold)).monospacedDigit()
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14).frame(height: 36)
                    .background(LinearGradient(colors: Color.sea, startPoint: .topLeading, endPoint: .bottomTrailing), in: Capsule())
                Text(hymn.section.isEmpty ? t("hymn.hymn") : hymn.section)
                    .font(.caption.weight(.semibold)).textCase(.uppercase).tracking(1.1)
                    .foregroundStyle(Color.inkSoft).lineLimit(1)
            }
            Text(hymn.title).font(.serif(32, .semibold)).foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.6)
            if !hymn.author.isEmpty {
                Text(hymn.author).font(.serif(16).italic()).foregroundStyle(Color.inkSoft).lineLimit(1)
            }
            Capsule().fill(Color.brand.opacity(0.35)).frame(width: 44, height: 3).padding(.top, 4)
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .padding(.bottom, 28)
    }

    private var words: some View {
        VStack(alignment: .leading, spacing: 26) {
            ForEach(book.verses(of: hymn)) { v in
                HStack(alignment: .top, spacing: 14) {
                    Text(v.isRefrain ? "℟" : "\(v.number)")
                        .font(.serif(prefs.textSize * 0.8, .semibold))
                        .foregroundStyle(Color.brand)
                        .frame(width: 26, alignment: .trailing)
                    Text(v.text)
                        .font(.serif(prefs.textSize, v.isRefrain ? .regular : .regular))
                        .italic(v.isRefrain)
                        .foregroundStyle(v.isRefrain ? Color.inkSoft : Color.ink)
                        .lineSpacing(prefs.textSize * 0.45)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(v.isRefrain ? 14 : 0)
                .background(v.isRefrain ? Color.brand.opacity(0.07) : .clear, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(.horizontal, 20)
    }

    private var noWords: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "music.note").font(.title2).foregroundStyle(Color.brand)
            Text(t("hymn.copyrightTitle")).font(.headline).foregroundStyle(Color.ink).lineLimit(1)
            Text(t("hymn.copyrightBody")).font(.subheadline).foregroundStyle(Color.inkSoft)
            Link(destination: hymn.hymnaryURL) {
                Label(t("hymn.hymnary"), systemImage: "safari").font(.subheadline.weight(.semibold))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
        .padding(.horizontal, 20)
    }

    private func storyCard(_ story: Story) -> some View {
        Button { showStory = true } label: {
            ZStack(alignment: .bottomLeading) {
                Photo(key: story.photo)
                LinearGradient(colors: [.clear, .black.opacity(0.75)], startPoint: .top, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 4) {
                    Text(t("hymn.storyBehind")).font(.caption.weight(.semibold)).textCase(.uppercase).tracking(1).foregroundStyle(.white.opacity(0.8)).lineLimit(1)
                    Text(story.text).font(.serif(17)).foregroundStyle(.white).lineLimit(1)
                }
                .padding(18)
            }
            .frame(height: 190)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(PressableStyle())
        .padding(.horizontal, 20)
        .padding(.top, 34)
    }

    private var footer: some View {
        VStack(spacing: 12) {
            Button { showShare = true } label: {
                Label(t("hymn.shareCard"), systemImage: "square.and.arrow.up")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 34)
    }

    /// Previous / next and text size, in a glass bar at the bottom.
    private var controls: some View {
        HStack(spacing: 6) {
            roundButton("chevron.left", label: t("hymn.previous"), disabled: current <= 1) { step(-1) }
            Spacer()
            if hymn.hasWords {
                HStack(spacing: 2) {
                    Button { prefs.textSize = max(Prefs.textRange.lowerBound, prefs.textSize - 2) } label: {
                        Text("A").font(.system(size: 14, weight: .semibold)).frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(t("hymn.smaller"))
                    Divider().frame(height: 20)
                    Button { prefs.textSize = min(Prefs.textRange.upperBound, prefs.textSize + 2) } label: {
                        Text("A").font(.system(size: 20, weight: .semibold)).frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(t("hymn.larger"))
                }
                .foregroundStyle(Color.ink)
                .padding(.horizontal, 6)
                .glass(22)
            }
            Spacer()
            roundButton("chevron.right", label: t("hymn.next"), disabled: current >= book.count) { step(1) }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 6)
    }

    private func roundButton(_ symbol: String, label: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 17, weight: .semibold)).foregroundStyle(Color.ink)
                .frame(width: 48, height: 48)
                .glassCircle()
        }
        .disabled(disabled)
        .opacity(disabled ? 0.4 : 1)
        .accessibilityLabel(label)
    }

    private func step(_ by: Int) {
        UISelectionFeedbackGenerator().selectionChanged()
        withAnimation(.easeOut(duration: 0.2)) { current = min(max(1, current + by), book.count) }
    }
}

/// Add a hymn to one of the member's lists, or start a new list with it.
struct AddToListCard: View {
    let hymn: Int
    @Binding var isPresented: Bool
    @EnvironmentObject private var library: Library
    @State private var newName = ""
    @FocusState private var typing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(t("lists.addTitle")).font(.headline).foregroundStyle(Color.ink).frame(maxWidth: .infinity)
            if library.lists.isEmpty {
                Text(t("lists.noneYet")).font(.subheadline).foregroundStyle(Color.inkSoft).frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(library.lists) { list in
                            let inList = list.hymns.contains(hymn)
                            Button { library.toggle(hymn, in: list.id) } label: {
                                HStack {
                                    Image(systemName: inList ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(inList ? Color.brand : Color.inkFaint)
                                    Text(list.name).foregroundStyle(Color.ink).lineLimit(1)
                                    Spacer()
                                    Text("\(list.hymns.count)").font(.footnote).foregroundStyle(Color.inkSoft)
                                }
                                .padding(.horizontal, 14).frame(height: 46)
                                .background(Color.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxHeight: 240)
            }
            HStack(spacing: 8) {
                TextField(t("lists.newPlaceholder"), text: $newName)
                    .focused($typing)
                    .submitLabel(.done)
                    .onSubmit(create)
                    .padding(.horizontal, 14).frame(height: 46)
                    .background(Color.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                Button(action: create) {
                    Image(systemName: "plus").font(.headline).foregroundStyle(.white).frame(width: 46, height: 46)
                        .background(Color.brand, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityLabel(t("lists.create"))
            }
            Button(t("common.done")) { isPresented = false }.buttonStyle(PrimaryButtonStyle())
        }
    }

    private func create() {
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        library.createList(name, with: hymn)
        newName = ""
        typing = false
    }
}

/// The story behind a hymn, full screen.
struct StoryView: View {
    let story: Story
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ZStack(alignment: .bottomLeading) {
                        Photo(key: story.photo)
                        LinearGradient(colors: [.clear, Color.bg], startPoint: .center, endPoint: .bottom)
                    }
                    .frame(height: 360)
                    VStack(alignment: .leading, spacing: 14) {
                        if let h = HymnBook.shared.hymn(story.hymn) {
                            Text(t("hymn.storyBehind")).font(.caption.weight(.semibold)).textCase(.uppercase).tracking(1.2).foregroundStyle(Color.brand)
                            Text("\(h.number) · \(h.title)").font(.serif(28, .semibold)).foregroundStyle(Color.ink)
                            if !h.author.isEmpty { Text(h.author).font(.serif(16).italic()).foregroundStyle(Color.inkSoft).lineLimit(1) }
                        }
                        Text(story.text).font(.serif(19)).foregroundStyle(Color.ink).lineSpacing(7).padding(.top, 6)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 60)
                }
            }
            .ignoresSafeArea(edges: .top)
            .background(Color.bg)
            Button { dismiss() } label: {
                Image(systemName: "xmark").font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                    .frame(width: 40, height: 40).glassCircle()
            }
            .padding(.trailing, 18).padding(.top, 8)
            .accessibilityLabel(t("common.close"))
        }
    }
}

/// The hymn's options, in a card in the middle of the screen.
struct HymnActions: View {
    enum Action { case share, list, copy, projector }
    let hymn: Hymn
    let shareText: String
    let pick: (Action) -> Void

    var body: some View {
        VStack(spacing: 6) {
            VStack(spacing: 2) {
                Text("\(hymn.number)").font(.serif(28, .semibold)).foregroundStyle(Color.brand)
                Text(hymn.title).font(.headline).foregroundStyle(Color.ink).lineLimit(1)
            }
            .padding(.bottom, 10)
            row("square.and.arrow.up", t("hymn.shareCard")) { pick(.share) }
            if hymn.hasWords {
                Button { pick(.projector) } label: {
                    rowLabel("tv.and.mediabox", t("plus.projector.title"))
                        .overlay(alignment: .trailing) { if !Plus.shared.isPlus { PlusBadge().padding(.trailing, 16) } }
                }
                .buttonStyle(.plain)
            }
            ShareLink(item: shareText) { rowLabel("text.quote", t("hymn.shareText")) }
                .buttonStyle(.plain)
            row("text.badge.plus", t("hymn.addToList")) { pick(.list) }
            if hymn.hasWords { row("doc.on.doc", t("hymn.copy")) { pick(.copy) } }
            Link(destination: hymn.hymnaryURL) { rowLabel("safari", t("hymn.hymnary")) }
                .buttonStyle(.plain)
        }
    }

    private func row(_ symbol: String, _ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { rowLabel(symbol, title) }.buttonStyle(.plain)
    }

    private func rowLabel(_ symbol: String, _ title: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol).font(.system(size: 16, weight: .semibold)).foregroundStyle(Color.brand).frame(width: 24)
            Text(title).font(.body.weight(.medium)).foregroundStyle(Color.ink).lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 50)
        .background(Color.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .contentShape(Rectangle())
    }
}
