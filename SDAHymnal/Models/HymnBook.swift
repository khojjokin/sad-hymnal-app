import Foundation

/// One hymn of the Seventh-day Adventist Hymnal (1985), numbered as in the printed book.
/// The words are in the app for the 502 hymns whose texts are in the public domain; the rest show their title
/// and writer and link to Hymnary.org.
struct Hymn: Identifiable, Hashable, Decodable {
    let number: Int
    let title: String
    let section: String
    let author: String
    let lyrics: String
    let publicDomain: Bool
    var id: Int { number }
    var hasWords: Bool { !lyrics.isEmpty }

    enum CodingKeys: String, CodingKey { case n, t, s, a, l, pd }
    init(from d: Decoder) throws {
        let c = try d.container(keyedBy: CodingKeys.self)
        number = try c.decode(Int.self, forKey: .n)
        title = try c.decode(String.self, forKey: .t)
        section = try c.decode(String.self, forKey: .s)
        author = try c.decode(String.self, forKey: .a)
        lyrics = try c.decode(String.self, forKey: .l)
        publicDomain = try c.decode(Bool.self, forKey: .pd)
    }
}

struct Verse: Identifiable, Hashable {
    enum Kind { case verse, refrain }
    let id: Int
    let kind: Kind
    let number: Int
    let text: String
    var isRefrain: Bool { kind == .refrain }
}

struct HymnSection: Identifiable {
    let name: String
    let hymns: [Hymn]
    var id: String { "\(hymns.first?.number ?? 0)-\(name)" }
}

struct HymnPart: Identifiable {
    let name: String
    let range: ClosedRange<Int>
    let symbol: String
    var id: String { name }
}

struct Story: Decodable, Identifiable {
    let hymn: Int
    let photo: String
    let text: String
    var id: Int { hymn }
}

struct Writer: Decodable, Identifiable {
    let name: String
    let match: String
    let years: String
    let photo: String
    let text: String
    var id: String { name }
}

final class HymnBook {
    static let shared = HymnBook()

    let hymns: [Hymn]
    let sections: [HymnSection]
    let stories: [Story]
    let writers: [Writer]
    private let searchIndex: [(hymn: Hymn, title: String, all: String)]

    let parts: [HymnPart] = [
        HymnPart(name: "Worship", range: 1...69, symbol: "sun.max.fill"),
        HymnPart(name: "Trinity", range: 70...73, symbol: "sparkles"),
        HymnPart(name: "God the Father", range: 74...114, symbol: "star.fill"),
        HymnPart(name: "Jesus Christ", range: 115...256, symbol: "heart.fill"),
        HymnPart(name: "Holy Spirit", range: 257...270, symbol: "flame.fill"),
        HymnPart(name: "Holy Scriptures", range: 271...278, symbol: "book.closed.fill"),
        HymnPart(name: "Gospel", range: 279...343, symbol: "text.book.closed.fill"),
        HymnPart(name: "Christian Church", range: 344...379, symbol: "building.columns.fill"),
        HymnPart(name: "Doctrines", range: 380...437, symbol: "graduationcap.fill"),
        HymnPart(name: "Early Advent", range: 438...454, symbol: "clock.fill"),
        HymnPart(name: "Christian Life", range: 455...649, symbol: "person.2.fill"),
        HymnPart(name: "Christian Home", range: 650...659, symbol: "house.fill"),
        HymnPart(name: "Sentences and Responses", range: 660...695, symbol: "music.note"),
    ]

    private init() {
        let decode: (String) -> Data = { name in
            guard let url = Bundle.main.url(forResource: name, withExtension: "json"), let d = try? Data(contentsOf: url) else { return Data("[]".utf8) }
            return d
        }
        hymns = (try? JSONDecoder().decode([Hymn].self, from: decode("hymns"))) ?? []
        struct StoryFile: Decodable { let stories: [Story]; let writers: [Writer] }
        let file = try? JSONDecoder().decode(StoryFile.self, from: decode("stories"))
        stories = file?.stories ?? []
        writers = file?.writers ?? []

        var groups: [HymnSection] = []
        var current: [Hymn] = []
        var name = ""
        for h in hymns {
            let s = h.section.isEmpty ? "Hymns" : h.section
            if s != name, !current.isEmpty { groups.append(HymnSection(name: name, hymns: current)); current = [] }
            name = s
            current.append(h)
        }
        if !current.isEmpty { groups.append(HymnSection(name: name, hymns: current)) }
        sections = groups
        searchIndex = hymns.map { h in
            let firstLine = h.lyrics.split(separator: "\n").first.map(String.init) ?? ""
            return (h, HymnBook.key(h.title), HymnBook.key("\(h.title) \(h.author) \(firstLine)"))
        }
    }

    var count: Int { hymns.count }

    func hymn(_ n: Int) -> Hymn? { (1...hymns.count).contains(n) ? hymns[n - 1] : nil }

    /// Lower-case letters, digits and single spaces, so "jesus' love" finds "Jesus' Love".
    static func key(_ s: String) -> String {
        let folded = s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .replacingOccurrences(of: "’", with: "").replacingOccurrences(of: "'", with: "")
        let mapped = folded.unicodeScalars.map { CharacterSet.alphanumerics.contains($0) ? Character($0) : " " }
        return String(mapped).split(separator: " ").joined(separator: " ")
    }

    /// Number search matches the start of the number; words must all appear (titles first, then writer or first line).
    func search(_ query: String) -> (titles: [Hymn], elsewhere: [Hymn]) {
        let q = query.trimmingCharacters(in: .whitespaces)
        if q.isEmpty { return ([], []) }
        if q.allSatisfy(\.isNumber) { return (hymns.filter { String($0.number).hasPrefix(q) }, []) }
        let words = HymnBook.key(q).split(separator: " ").map(String.init)
        guard !words.isEmpty else { return ([], []) }
        let titles = searchIndex.filter { e in words.allSatisfy { e.title.contains($0) } }.map(\.hymn)
        let seen = Set(titles.map(\.number))
        let rest = searchIndex.filter { e in !seen.contains(e.hymn.number) && words.allSatisfy { e.all.contains($0) } }.map(\.hymn)
        return (titles, rest)
    }

    /// The words as verses and refrains (a block starting "Refrain:" is the refrain).
    func verses(of hymn: Hymn) -> [Verse] {
        let blocks = hymn.lyrics.replacingOccurrences(of: "\r\n", with: "\n")
            .components(separatedBy: "\n\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        var out: [Verse] = []
        var n = 0
        for (i, b) in blocks.enumerated() {
            let lower = b.lowercased()
            if lower.hasPrefix("refrain") || lower.hasPrefix("chorus") {
                var text = b
                if let colon = text.firstIndex(of: ":"), text.distance(from: text.startIndex, to: colon) < 10 { text = String(text[text.index(after: colon)...]) }
                else if let nl = text.firstIndex(of: "\n") { text = String(text[text.index(after: nl)...]) }
                out.append(Verse(id: i, kind: .refrain, number: 0, text: text.trimmingCharacters(in: .whitespacesAndNewlines)))
            } else {
                n += 1
                out.append(Verse(id: i, kind: .verse, number: n, text: b))
            }
        }
        return out
    }

    func plainWords(_ hymn: Hymn) -> String {
        verses(of: hymn).map { $0.isRefrain ? "Refrain:\n\($0.text)" : "\($0.number). \($0.text)" }.joined(separator: "\n\n")
    }

    func sections(in range: ClosedRange<Int>) -> [HymnSection] {
        sections.filter { range.contains($0.hymns.first?.number ?? 0) }
    }

    // MARK: Discover

    static func dayNumber(_ date: Date = Date()) -> Int {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        let utc = Calendar(identifier: .gregorian).date(from: DateComponents(timeZone: .gmt, year: c.year, month: c.month, day: c.day)) ?? date
        return Int(utc.timeIntervalSince1970 / 86400)
    }

    /// The same pick all day for everyone, a new one each day; `shuffle` steps to another set.
    func pick<T>(_ list: [T], day: Int, shuffle: Int, stride: Int) -> T {
        list[abs(day * stride + shuffle * 3) % list.count]
    }

    var withWords: [Hymn] { hymns.filter { $0.hasWords && $0.number < 660 } }

    enum Moment { case morning, evening, sabbath, praise }

    /// The Sabbath runs from Friday 6 pm to Saturday 6 pm (sunset varies; this is the usual rule of thumb).
    static func moment(_ date: Date = Date()) -> Moment {
        let c = Calendar.current.dateComponents([.weekday, .hour], from: date)
        let d = c.weekday ?? 1, h = c.hour ?? 12
        if (d == 6 && h >= 18) || (d == 7 && h < 18) { return .sabbath }
        if h < 12 { return .morning }
        if h >= 17 { return .evening }
        return .praise
    }

    func hymns(for m: Moment) -> [Hymn] {
        let names: [String]
        switch m {
        case .morning: names = ["Morning Worship"]
        case .evening: names = ["Evening Worship"]
        case .sabbath: names = ["Sabbath"]
        case .praise: names = ["Adoration and Praise", "Glory and Praise"]
        }
        return hymns.filter { names.contains($0.section) }
    }

    func story(for n: Int) -> Story? { stories.first { $0.hymn == n } }
    func hymns(by writer: Writer) -> [Hymn] { hymns.filter { $0.author.contains(writer.match) } }
}
