import SwiftUI

/// The look, the language and how hymns read. Kept on this iPhone.
@MainActor
final class Prefs: ObservableObject {
    static let shared = Prefs()

    enum Appearance: String, CaseIterable, Identifiable {
        case system, light, dark
        var id: String { rawValue }
        var colorScheme: ColorScheme? { self == .light ? .light : self == .dark ? .dark : nil }
    }

    @Published var appearance: Appearance { didSet { UserDefaults.standard.set(appearance.rawValue, forKey: "hymnal.appearance") } }
    @Published var language: String { didSet { UserDefaults.standard.set(language, forKey: "hymnal.language"); L10n.language = language } }
    @Published var textSize: Double { didSet { UserDefaults.standard.set(textSize, forKey: "hymnal.textSize") } }
    @Published var keepAwake: Bool { didSet { UserDefaults.standard.set(keepAwake, forKey: "hymnal.keepAwake") } }

    static let textRange: ClosedRange<Double> = 15...34

    private init() {
        let d = UserDefaults.standard
        appearance = Appearance(rawValue: d.string(forKey: "hymnal.appearance") ?? "") ?? .system
        let lang = d.string(forKey: "hymnal.language") ?? L10n.deviceLanguage
        language = L10n.languages.contains(lang) ? lang : "en"
        let size = d.double(forKey: "hymnal.textSize")
        textSize = size == 0 ? 20 : min(max(size, Prefs.textRange.lowerBound), Prefs.textRange.upperBound)
        keepAwake = d.object(forKey: "hymnal.keepAwake") as? Bool ?? true
        L10n.language = language
    }
}

/// The app's words in six languages (Settings › Language). Menus and buttons change; the hymns, their titles
/// and the stories behind them stay in English.
enum L10n {
    static let languages = ["en", "es", "fr", "pt", "de", "sw"]
    static let names: [String: String] = ["en": "English", "es": "Español", "fr": "Français", "pt": "Português", "de": "Deutsch", "sw": "Kiswahili"]
    static var language = "en"

    static var deviceLanguage: String {
        let code = Locale.preferredLanguages.first.map { String($0.prefix(2)) } ?? "en"
        return languages.contains(code) ? code : "en"
    }

    private static let table: [String: [String: String]] = {
        guard let url = Bundle.main.url(forResource: "strings", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let t = try? JSONDecoder().decode([String: [String: String]].self, from: data) else { return [:] }
        return t
    }()

    static func t(_ key: String, _ args: [String: CustomStringConvertible] = [:]) -> String {
        var text = table[language]?[key] ?? table["en"]?[key] ?? key
        for (k, v) in args { text = text.replacingOccurrences(of: "{\(k)}", with: v.description) }
        return text
    }
}

/// Shorthand used throughout the views.
func t(_ key: String, _ args: [String: CustomStringConvertible] = [:]) -> String { L10n.t(key, args) }
