import Foundation
import SwiftUI

struct SavedHymn: Codable, Hashable {
    var n: Int
    var at: String
}

struct HymnList: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var hymns: [Int]
    var createdAt: String
    var updatedAt: String
}

/// Everything a member saves: hymns, their own lists (for a service, a choir, a Sabbath) and what they opened lately.
struct LibraryData: Codable, Equatable {
    var favourites: [SavedHymn] = []
    var lists: [HymnList] = []
    var recent: [Int] = []
    var updatedAt: String = Library.now()
}

/// The saved hymns and lists. Always kept on this iPhone; with an account they're also saved to the member's
/// SDA Hymnal account and come back on any device they sign in to.
@MainActor
final class Library: ObservableObject {
    @Published private(set) var data = LibraryData()
    @Published private(set) var syncing = false
    @Published private(set) var lastSynced: Date?
    @Published var syncError: String?

    private var profile = "guest"
    private weak var auth: AuthStore?
    private var pushTask: Task<Void, Never>?

    nonisolated static func now() -> String { ISO8601DateFormatter().string(from: Date()) }
    nonisolated private static func date(_ s: String) -> Date { ISO8601DateFormatter().date(from: s) ?? .distantPast }
    private func key(_ profile: String) -> String { "hymnal.library.\(profile)" }

    init() { data = load("guest") }

    // MARK: Reading

    var favourites: [SavedHymn] { data.favourites }
    var lists: [HymnList] { data.lists }
    var recent: [Int] { data.recent }
    func isSaved(_ n: Int) -> Bool { data.favourites.contains { $0.n == n } }
    func list(_ id: String) -> HymnList? { data.lists.first { $0.id == id } }

    // MARK: Changes

    func toggleSave(_ n: Int) {
        if let i = data.favourites.firstIndex(where: { $0.n == n }) {
            data.favourites.remove(at: i)
        } else {
            data.favourites.insert(SavedHymn(n: n, at: Library.now()), at: 0)
            HymnalAPI.shared.track("save", hymn: n)
        }
        changed()
    }

    func unsave(_ numbers: [Int]) {
        data.favourites.removeAll { numbers.contains($0.n) }
        changed()
    }

    func opened(_ n: Int) {
        guard data.recent.first != n else { return }
        data.recent.removeAll { $0 == n }
        data.recent.insert(n, at: 0)
        if data.recent.count > 30 { data.recent.removeLast(data.recent.count - 30) }
        changed()
    }

    func clearRecent() { data.recent = []; changed() }

    @discardableResult
    func createList(_ name: String, with hymn: Int? = nil) -> String {
        let now = Library.now()
        let list = HymnList(id: UUID().uuidString, name: String(name.prefix(60)), hymns: hymn.map { [$0] } ?? [], createdAt: now, updatedAt: now)
        data.lists.insert(list, at: 0)
        changed()
        return list.id
    }

    func rename(_ id: String, to name: String) { edit(id) { $0.name = String(name.prefix(60)) } }
    func deleteList(_ id: String) { data.lists.removeAll { $0.id == id }; changed() }
    func toggle(_ n: Int, in id: String) { edit(id) { l in if let i = l.hymns.firstIndex(of: n) { l.hymns.remove(at: i) } else { l.hymns.append(n) } } }
    func add(_ numbers: [Int], to id: String) { edit(id) { l in for n in numbers where !l.hymns.contains(n) { l.hymns.append(n) } } }
    func remove(at offsets: IndexSet, from id: String) { edit(id) { $0.hymns.remove(atOffsets: offsets) } }
    func move(from: IndexSet, to: Int, in id: String) { edit(id) { $0.hymns.move(fromOffsets: from, toOffset: to) } }

    private func edit(_ id: String, _ change: (inout HymnList) -> Void) {
        guard let i = data.lists.firstIndex(where: { $0.id == id }) else { return }
        change(&data.lists[i])
        data.lists[i].updatedAt = Library.now()
        changed()
    }

    private func changed() {
        data.updatedAt = Library.now()
        save()
        schedulePush()
    }

    // MARK: On this iPhone

    private func load(_ profile: String) -> LibraryData {
        guard let raw = UserDefaults.standard.data(forKey: key(profile)), let d = try? JSONDecoder().decode(LibraryData.self, from: raw) else { return LibraryData() }
        return d
    }

    private func save() {
        if let raw = try? JSONEncoder().encode(data) { UserDefaults.standard.set(raw, forKey: key(profile)) }
    }

    // MARK: With an account

    func attach(_ auth: AuthStore) { self.auth = auth }

    /// Switches between the guest library and a member's. Hymns saved as a guest move into the account
    /// the first time someone signs in, so nothing they saved is lost.
    func switchProfile(to userId: String?) async {
        let next = userId.map { "user.\($0)" } ?? "guest"
        guard next != profile else { return }
        let guest = profile == "guest" ? data : nil
        profile = next
        data = load(next)
        if let guest, next != "guest", !(guest.favourites.isEmpty && guest.lists.isEmpty) {
            data = Library.merge(data, guest)
            save()
            UserDefaults.standard.removeObject(forKey: key("guest"))
        }
        if next != "guest" { await pull() } else { lastSynced = nil }
    }

    /// Brings down the account's copy: the newer of the two wins, and anything only one side has is kept.
    func pull() async {
        guard profile != "guest", let token = await auth?.validToken() else { return }
        syncing = true
        defer { syncing = false }
        do {
            if let server = try await HymnalAPI.shared.getLibrary(token: token) {
                let merged = Library.merge(server, data, preferFirst: Library.date(server.updatedAt) >= Library.date(data.updatedAt))
                if merged != data { data = merged; save() }
            }
            try await HymnalAPI.shared.saveLibrary(token: token, data)
            lastSynced = Date()
            syncError = nil
        } catch {
            syncError = error.localizedDescription
        }
    }

    private func schedulePush() {
        guard profile != "guest" else { return }
        pushTask?.cancel()
        pushTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.2))
            guard !Task.isCancelled else { return }
            await self?.push()
        }
    }

    func push() async {
        guard profile != "guest", let token = await auth?.validToken() else { return }
        do {
            try await HymnalAPI.shared.saveLibrary(token: token, data)
            lastSynced = Date()
            syncError = nil
        } catch {
            syncError = error.localizedDescription
        }
    }

    /// Forgets this member's copy on this iPhone (after they delete their account).
    func forget(_ userId: String) {
        UserDefaults.standard.removeObject(forKey: key("user.\(userId)"))
        profile = "guest"
        data = load("guest")
        lastSynced = nil
    }

    nonisolated static func merge(_ a: LibraryData, _ b: LibraryData, preferFirst: Bool = true) -> LibraryData {
        let (first, second) = preferFirst ? (a, b) : (b, a)
        var out = first
        let have = Set(first.favourites.map(\.n))
        out.favourites += second.favourites.filter { !have.contains($0.n) }
        out.favourites.sort { $0.at > $1.at }
        var lists = Dictionary(uniqueKeysWithValues: first.lists.map { ($0.id, $0) })
        for l in second.lists {
            if let mine = lists[l.id] { if date(l.updatedAt) > date(mine.updatedAt) { lists[l.id] = l } } else { lists[l.id] = l }
        }
        out.lists = lists.values.sorted { $0.createdAt > $1.createdAt }
        var seen = Set<Int>()
        out.recent = (first.recent + second.recent).filter { seen.insert($0).inserted }.prefix(30).map { $0 }
        out.updatedAt = max(first.updatedAt, second.updatedAt)
        return out
    }
}
