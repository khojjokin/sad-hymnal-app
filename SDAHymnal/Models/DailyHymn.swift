import SwiftUI
import UserNotifications

/// The daily hymn notification: each day's hymn of the day, at a time the member picks. On by default;
/// Settings › Daily hymn turns it off. Two weeks are scheduled ahead and topped up every time the app opens.
@MainActor
final class DailyHymn: ObservableObject {
    static let shared = DailyHymn()

    @Published var enabled: Bool { didSet { UserDefaults.standard.set(enabled, forKey: "hymnal.daily.on"); Task { await reschedule() } } }
    @Published var hour: Int { didSet { UserDefaults.standard.set(hour, forKey: "hymnal.daily.hour"); Task { await reschedule() } } }
    @Published private(set) var denied = false

    static let hours = [6, 7, 8, 12, 18, 21]
    private let prefix = "daily-hymn-"

    private init() {
        let d = UserDefaults.standard
        enabled = d.object(forKey: "hymnal.daily.on") as? Bool ?? true
        hour = d.object(forKey: "hymnal.daily.hour") as? Int ?? 7
    }

    /// Asks once (after the splash on first launch), then keeps the next two weeks scheduled.
    func start() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined && enabled {
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        }
        await reschedule()
    }

    func reschedule() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix(prefix) }
        center.removePendingNotificationRequests(withIdentifiers: pending)
        let status = await center.notificationSettings().authorizationStatus
        denied = status == .denied
        guard enabled, status == .authorized || status == .provisional else { return }

        let cal = Calendar.current
        let book = HymnBook.shared
        for offset in 0..<14 {
            guard let day = cal.date(byAdding: .day, value: offset, to: Date()),
                  var when = cal.date(bySettingHour: hour, minute: 0, second: 0, of: day) else { continue }
            if when < Date() { continue }
            when = cal.date(byAdding: .second, value: 0, to: when) ?? when
            let hymn = book.pick(book.withWords, day: HymnBook.dayNumber(day), shuffle: 0, stride: 37)
            let first = book.verses(of: hymn).first?.text.split(separator: "\n").prefix(2).joined(separator: " ") ?? ""

            let content = UNMutableNotificationContent()
            content.title = t("daily.title")
            content.subtitle = "\(hymn.number) · \(hymn.title)"
            content.body = first.isEmpty ? t("daily.body") : first
            content.sound = .default
            content.userInfo = ["hymn": hymn.number]
            content.threadIdentifier = "daily-hymn"

            let parts = cal.dateComponents([.year, .month, .day, .hour, .minute], from: when)
            let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: prefix + "\(parts.year ?? 0)-\(parts.month ?? 0)-\(parts.day ?? 0)", content: content, trigger: trigger))
        }
    }
}

/// Opens the hymn from a tapped notification.
final class NotificationRouter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationRouter()
    static let openHymn = Notification.Name("hymnal.openHymn")

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        if let n = response.notification.request.content.userInfo["hymn"] as? Int {
            await MainActor.run { NotificationCenter.default.post(name: Self.openHymn, object: n) }
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
