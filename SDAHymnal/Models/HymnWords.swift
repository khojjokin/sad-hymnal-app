import Foundation

/// Words added from the Qortn Console for hymns the app doesn't ship with, kept on the phone so they work offline.
/// Each launch (and each return to the app) asks the server only for what changed since the last time.
enum HymnWords {
    struct Entry: Codable, Equatable {
        let lyrics: String
        let credit: String?
    }

    private struct Store: Codable {
        var since: String?
        var words: [Int: Entry]
    }

    private static var file: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("hymn-words.json")
    }

    private static func load() -> Store {
        guard let d = try? Data(contentsOf: file), let s = try? JSONDecoder().decode(Store.self, from: d) else { return Store(since: nil, words: [:]) }
        return s
    }

    static func cached() -> [Int: Entry] { load().words }

    /// Fetches changes; returns true when the book changed (so screens can refresh).
    @MainActor
    static func refresh() async -> Bool {
        var store = load()
        var body: [String: Any] = [:]
        if let since = store.since { body["since"] = since }
        guard let j = try? await HymnalAPI.shared.call("words", token: nil, body) else { return false }
        let removed = (j["removed"] as? [NSNumber] ?? []).map(\.intValue)
        let rows = j["words"] as? [[String: Any]] ?? []
        var changed = false
        for n in removed where store.words[n] != nil { store.words[n] = nil; changed = true }
        for r in rows {
            guard let n = (r["hymn"] as? NSNumber)?.intValue, (1...695).contains(n), let lyrics = r["lyrics"] as? String, !lyrics.isEmpty else { continue }
            let e = Entry(lyrics: lyrics, credit: r["credit"] as? String)
            if store.words[n] != e { store.words[n] = e; changed = true }
        }
        store.since = j["now"] as? String ?? store.since
        if let d = try? JSONEncoder().encode(store) {
            try? d.write(to: file, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        }
        if changed { HymnBook.shared.apply(store.words) }
        return changed
    }
}
