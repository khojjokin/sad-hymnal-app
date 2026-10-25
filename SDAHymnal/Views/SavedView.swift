import SwiftUI

struct SavedView: View {
    @EnvironmentObject private var library: Library
    @EnvironmentObject private var auth: AuthStore
    @State private var tab = 0
    @State private var newList = false
    @State private var newName = ""
    @State private var showAuth = false

    private let book = HymnBook.shared

    var body: some View {
        NavigationStack {
            List {
                if !auth.isSignedIn {
                    Section { accountPrompt }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
                Section {
                    Picker("", selection: $tab) {
                        Text(t("saved.hymns")).tag(0)
                        Text(t("saved.lists")).tag(1)
                    }
                    .pickerStyle(.segmented)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                if tab == 0 { hymns } else { lists }
            }
            .listStyle(.insetGrouped)
            .tracksScroll()
            .navigationTitle(t("tab.saved"))
            .toolbar {
                if tab == 1 {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { newName = ""; newList = true } label: { Image(systemName: "plus") }
                            .accessibilityLabel(t("lists.create"))
                    }
                }
            }
            .navigationDestination(for: Int.self) { HymnView(number: $0) }
            .navigationDestination(for: String.self) { ListDetailView(listId: $0) }
            .alert(t("lists.newTitle"), isPresented: $newList) {
                TextField(t("lists.newPlaceholder"), text: $newName)
                Button(t("common.cancel"), role: .cancel) {}
                Button(t("lists.create")) {
                    let name = newName.trimmingCharacters(in: .whitespaces)
                    if !name.isEmpty { library.createList(name) }
                }
            }
            .fullScreenCover(isPresented: $showAuth) { AuthView() }
            .refreshable { await library.pull() }
        }
    }

    private var accountPrompt: some View {
        Button { showAuth = true } label: {
            HStack(spacing: 14) {
                Image(systemName: "icloud.fill").font(.title2).foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(Color.white.opacity(0.18), in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(t("saved.keepTitle")).font(.headline).foregroundStyle(.white).lineLimit(1)
                    Text(t("saved.keepBody")).font(.footnote).foregroundStyle(.white.opacity(0.85)).lineLimit(1)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.7))
            }
            .padding(18)
            .background(LinearGradient(colors: Color.sea, startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(PressableStyle())
    }

    @ViewBuilder private var hymns: some View {
        if library.favourites.isEmpty {
            Section {
                EmptyState(symbol: "bookmark", title: t("saved.emptyTitle"), message: t("saved.emptyBody"))
            }
        } else {
            Section(t("saved.count", ["n": library.favourites.count])) {
                ForEach(library.favourites, id: \.n) { saved in
                    if let h = book.hymn(saved.n) {
                        NavigationLink(value: h.number) { HymnRow(hymn: h, subtitle: h.author) }
                            .swipeActions {
                                Button(role: .destructive) { withAnimation { library.unsave([h.number]) } } label: {
                                    Label(t("hymn.unsave"), systemImage: "bookmark.slash")
                                }
                            }
                    }
                }
            }
        }
    }

    @ViewBuilder private var lists: some View {
        if library.lists.isEmpty {
            Section {
                EmptyState(symbol: "music.note.list", title: t("lists.emptyTitle"), message: t("lists.emptyBody"))
                Button { newName = ""; newList = true } label: { Label(t("lists.create"), systemImage: "plus") }
            }
        } else {
            Section {
                ForEach(library.lists) { list in
                    NavigationLink(value: list.id) {
                        HStack(spacing: 14) {
                            Image(systemName: "music.note.list").foregroundStyle(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.brand.gradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(list.name).font(.body.weight(.medium)).lineLimit(1)
                                Text(t("lists.hymnsCount", ["n": list.hymns.count])).font(.footnote).foregroundStyle(Color.inkSoft).lineLimit(1)
                            }
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) { withAnimation { library.deleteList(list.id) } } label: {
                            Label(t("common.delete"), systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
}

struct EmptyState: View {
    let symbol: String
    let title: String
    let message: String
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: symbol).font(.system(size: 34)).foregroundStyle(Color.brand)
            Text(title).font(.headline).lineLimit(1)
            Text(message).font(.subheadline).foregroundStyle(Color.inkSoft).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
    }
}

/// One list: its hymns in order. Drag to reorder, swipe to remove.
struct ListDetailView: View {
    let listId: String
    @EnvironmentObject private var library: Library
    @Environment(\.dismiss) private var dismiss
    @State private var renaming = false
    @State private var name = ""
    @State private var confirmDelete = false
    @State private var adding = false

    private var list: HymnList? { library.list(listId) }

    var body: some View {
        Group {
            if let list {
                List {
                    if list.hymns.isEmpty {
                        EmptyState(symbol: "plus.circle", title: t("lists.emptyListTitle"), message: t("lists.emptyListBody"))
                    }
                    ForEach(Array(list.hymns.enumerated()), id: \.offset) { item in
                        if let h = HymnBook.shared.hymn(item.element) {
                            NavigationLink(value: item.element) { HymnRow(hymn: h, subtitle: h.author) }
                        }
                    }
                    .onDelete { library.remove(at: $0, from: listId) }
                    .onMove { library.move(from: $0, to: $1, in: listId) }
                    Button { adding = true } label: { Label(t("lists.addHymns"), systemImage: "plus") }
                }
                .listStyle(.insetGrouped)
                .navigationTitle(list.name)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        if !list.hymns.isEmpty { EditButton() }
                        ShareLink(item: shareText(list)) { Image(systemName: "square.and.arrow.up") }
                            .accessibilityLabel(t("lists.share"))
                        Button { name = list.name; renaming = true } label: { Image(systemName: "pencil") }
                            .accessibilityLabel(t("lists.rename"))
                        Button { confirmDelete = true } label: { Image(systemName: "trash") }
                            .accessibilityLabel(t("lists.delete"))
                    }
                }
                .alert(t("lists.rename"), isPresented: $renaming) {
                    TextField(t("lists.newPlaceholder"), text: $name)
                    Button(t("common.cancel"), role: .cancel) {}
                    Button(t("common.save")) {
                        let n = name.trimmingCharacters(in: .whitespaces)
                        if !n.isEmpty { library.rename(listId, to: n) }
                    }
                }
                .alert(t("lists.deleteTitle"), isPresented: $confirmDelete) {
                    Button(t("common.cancel"), role: .cancel) {}
                    Button(t("common.delete"), role: .destructive) { dismiss(); library.deleteList(listId) }
                } message: { Text(t("lists.deleteBody")) }
                .fullScreenCover(isPresented: $adding) { HymnPicker(listId: listId) }
            } else {
                EmptyState(symbol: "music.note.list", title: t("lists.gone"), message: "")
            }
        }
    }

    private func shareText(_ list: HymnList) -> String {
        let lines = list.hymns.compactMap { HymnBook.shared.hymn($0) }.map { "\($0.number) · \($0.title)" }
        return ([list.name, ""] + lines + ["", t("share.footer")]).joined(separator: "\n")
    }
}

/// Pick hymns to add to a list.
struct HymnPicker: View {
    let listId: String
    @EnvironmentObject private var library: Library
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var picked: [Int] = []

    private var hymns: [Hymn] {
        let q = query.trimmingCharacters(in: .whitespaces)
        if q.isEmpty { return HymnBook.shared.hymns }
        if let n = Int(q), let h = HymnBook.shared.hymn(n) { return [h] }
        let r = HymnBook.shared.search(q)
        return r.titles + r.elsewhere
    }

    var body: some View {
        NavigationStack {
            List(hymns) { h in
                let already = library.list(listId)?.hymns.contains(h.number) ?? false
                Button {
                    if let i = picked.firstIndex(of: h.number) { picked.remove(at: i) } else if !already { picked.append(h.number) }
                } label: {
                    HStack {
                        HymnRow(hymn: h)
                        Image(systemName: already || picked.contains(h.number) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(already ? Color.inkFaint : picked.contains(h.number) ? Color.brand : Color.inkFaint)
                    }
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: t("home.search"))
            .navigationTitle(t("lists.addHymns"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(t("common.cancel")) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(picked.isEmpty ? t("common.done") : t("lists.addN", ["n": picked.count])) {
                        if !picked.isEmpty { library.add(picked, to: listId) }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
