import SwiftUI
import StoreKit
import ClerkKit

/// Settings, laid out like Instagram's: one continuous page, no grouped cards. Small grey headings split it up,
/// each row is a plain outline icon, a title, and a value or chevron.
struct SettingsView: View {
    @EnvironmentObject private var prefs: Prefs
    @EnvironmentObject private var auth: AuthStore
    @EnvironmentObject private var library: Library
    @EnvironmentObject private var app: AppState
    @ObservedObject private var plus = Plus.shared
    @ObservedObject private var daily = DailyHymn.shared
    @State private var showAuth = false
    @State private var showPlus = false
    @State private var confirmSignOut = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    accountRow
                    plusRow.padding(.horizontal, 16).padding(.vertical, 8)

                    SettingsHeading(t("settings.sec.hymnal"))
                    Button { app.tab = .saved } label: {
                        SettingsRow(t("settings.saved"), symbol: "bookmark", value: "\(library.favourites.count)")
                    }
                    SettingsToggleRow(t("daily.setting"), symbol: "bell", isOn: $daily.enabled)
                    if daily.enabled { dailyTimes }
                    if daily.denied && daily.enabled {
                        Button(t("daily.denied")) { if let u = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(u) } }
                            .font(.footnote).padding(.horizontal, 56).padding(.bottom, 8)
                    }

                    SettingsDivider()
                    SettingsHeading(t("settings.sec.reading"))
                    NavigationLink {
                        OptionsPage(title: t("settings.appearance"), options: Prefs.Appearance.allCases.map { ($0, appearanceName($0)) }, selection: $prefs.appearance)
                    } label: { SettingsRow(t("settings.appearance"), symbol: "circle.lefthalf.filled", value: appearanceName(prefs.appearance), chevron: true) }
                    NavigationLink {
                        OptionsPage(title: t("settings.language"), options: L10n.languages.map { ($0, L10n.names[$0] ?? $0) }, selection: $prefs.language)
                    } label: { SettingsRow(t("settings.language"), symbol: "globe", value: L10n.names[prefs.language] ?? prefs.language, chevron: true) }
                    textSizeRow
                    SettingsToggleRow(t("settings.keepAwake"), symbol: "sun.max", isOn: $prefs.keepAwake)

                    SettingsDivider()
                    SettingsHeading(t("settings.sec.support"))
                    Link(destination: Self.supportEmail) { SettingsRow(t("settings.support"), symbol: "envelope", external: true) }
                    Link(destination: ReviewPrompt.writeReviewURL) { SettingsRow(t("settings.rate"), symbol: "star", external: true) }
                    ShareLink(item: Backend.appStoreURL, message: Text(t("settings.shareMessage"))) {
                        SettingsRow(t("settings.share"), symbol: "square.and.arrow.up")
                    }
                    NavigationLink { CreditsView() } label: { SettingsRow(t("settings.credits"), symbol: "music.note", chevron: true) }
                    Link(destination: Backend.privacyURL) { SettingsRow(t("settings.privacy"), symbol: "hand.raised", external: true) }
                    SettingsRow(t("settings.version"), symbol: "info.circle", value: Backend.appVersion)

                    if auth.isSignedIn {
                        SettingsDivider()
                        Button { confirmSignOut = true } label: {
                            Text(t("account.signOut")).font(.body).foregroundStyle(Color.bad)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16).frame(height: 52)
                                .contentShape(Rectangle())
                        }
                    }

                    MadeByQortn().padding(.top, 28).padding(.bottom, 24)
                }
                .buttonStyle(.plain)
            }
            .tracksScroll()
            .background(Color.bg)
            .navigationTitle(t("tab.settings"))
            .fullScreenCover(isPresented: $showAuth) { AuthView() }
            .fullScreenCover(isPresented: $showPlus) { PlusView() }
            .alert(t("account.signOutTitle"), isPresented: $confirmSignOut) {
                Button(t("common.cancel"), role: .cancel) {}
                Button(t("account.signOut"), role: .destructive) { Task { await auth.signOut() } }
            } message: { Text(t("account.signOutBody")) }
        }
    }

    /// Contact support: an email to the team, with the app version and device filled in.
    static var supportEmail: URL {
        let body = "\n\n\nSDA Hymnal \(Backend.appVersion) · \(UIDevice.current.model) · iOS \(UIDevice.current.systemVersion)"
        var c = URLComponents()
        c.scheme = "mailto"
        c.path = "support@qortyn.com"
        c.queryItems = [URLQueryItem(name: "subject", value: "SDA Hymnal"), URLQueryItem(name: "body", value: body)]
        return c.url ?? URL(string: "mailto:support@qortyn.com")!
    }

    private func appearanceName(_ a: Prefs.Appearance) -> String {
        switch a {
        case .system: t("settings.system")
        case .light: t("settings.light")
        case .dark: t("settings.dark")
        }
    }

    private var dailyTimes: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(DailyHymn.hours, id: \.self) { h in
                    let on = daily.hour == h
                    Button { daily.hour = h } label: {
                        Text(hourLabel(h)).font(.subheadline.weight(.semibold)).lineLimit(1)
                            .foregroundStyle(on ? .white : Color.ink)
                            .padding(.horizontal, 14).frame(height: 34)
                            .background(on ? Color.brand : Color.card, in: Capsule())
                    }
                }
            }
            .padding(.horizontal, 56)
        }
        .scrollIndicators(.hidden)
        .padding(.bottom, 10)
    }

    private func hourLabel(_ h: Int) -> String {
        var c = DateComponents(); c.hour = h; c.minute = 0
        return (Calendar.current.date(from: c) ?? Date()).formatted(date: .omitted, time: .shortened)
    }

    private var textSizeRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            SettingsRow(t("settings.textSize"), symbol: "textformat.size", value: "\(Int(prefs.textSize))")
            HStack(spacing: 12) {
                Text("A").font(.system(size: 13))
                Slider(value: $prefs.textSize, in: Prefs.textRange, step: 1)
                Text("A").font(.system(size: 22))
            }
            .foregroundStyle(Color.inkSoft)
            .padding(.leading, 56).padding(.trailing, 16)
            Text(t("settings.preview")).font(.serif(prefs.textSize)).foregroundStyle(Color.ink)
                .lineLimit(1).minimumScaleFactor(0.5)
                .padding(.leading, 56).padding(.trailing, 16).padding(.bottom, 10)
        }
    }

    private var plusRow: some View {
        Button { showPlus = true } label: {
            HStack(spacing: 14) {
                SDALogo(size: 20, color: Color(hex: "F5D78E"))
                    .frame(width: 40, height: 40)
                    .background(LinearGradient(colors: [Color(hex: "0B2D4A"), Color(hex: "06121F")], startPoint: .top, endPoint: .bottom),
                                in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text("SDA Hymnal Plus").font(.subheadline.weight(.semibold)).foregroundStyle(Color.ink).lineLimit(1)
                    Text(plus.isPlus ? t("plus.active") : t("plus.rowBody", ["price": plus.price]))
                        .font(.footnote).foregroundStyle(Color.inkSoft).lineLimit(1)
                }
                Spacer(minLength: 4)
                if plus.isPlus {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(Color(hex: "E0B354"))
                } else {
                    PlusBadge()
                }
            }
            .padding(12)
            .background(Color.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(Rectangle())
        }
    }

    @ViewBuilder private var accountRow: some View {
        if let user = auth.currentUser {
            NavigationLink { AccountView() } label: {
                HStack(spacing: 14) {
                    Text(user.initials).font(.headline).foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(LinearGradient(colors: Color.sea, startPoint: .topLeading, endPoint: .bottomTrailing), in: Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.name).font(.headline).foregroundStyle(Color.ink).lineLimit(1)
                        Text(user.email).font(.footnote).foregroundStyle(Color.inkSoft).lineLimit(1)
                    }
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Color.inkFaint)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .contentShape(Rectangle())
            }
        } else {
            Button { showAuth = true } label: {
                HStack(spacing: 14) {
                    Image(systemName: "person.crop.circle.fill").font(.system(size: 52)).foregroundStyle(Color.inkFaint)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(t("settings.signIn")).font(.headline).foregroundStyle(Color.ink).lineLimit(1)
                        Text(t("settings.signInBody")).font(.footnote).foregroundStyle(Color.inkSoft).lineLimit(1)
                    }
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Color.inkFaint)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .contentShape(Rectangle())
            }
        }
    }
}

/// A small grey heading between parts of the settings page.
struct SettingsHeading: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text).font(.footnote.weight(.semibold)).foregroundStyle(Color.inkSoft).lineLimit(1)
            .padding(.horizontal, 16).padding(.top, 18).padding(.bottom, 4)
    }
}

/// The thick soft line Instagram puts between parts of its settings.
struct SettingsDivider: View {
    var body: some View {
        Rectangle().fill(Color.card).frame(height: 8).padding(.top, 10)
    }
}

/// One settings row: outline icon, title, then a value, a chevron or an outward arrow.
struct SettingsRow: View {
    let title: String
    let symbol: String
    var value: String? = nil
    var chevron = false
    var external = false
    init(_ title: String, symbol: String, value: String? = nil, chevron: Bool = false, external: Bool = false) {
        self.title = title; self.symbol = symbol; self.value = value; self.chevron = chevron; self.external = external
    }
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: symbol).font(.system(size: 19, weight: .regular)).foregroundStyle(Color.ink)
                .frame(width: 24)
            Text(title).font(.body).foregroundStyle(Color.ink).lineLimit(1)
            Spacer(minLength: 8)
            if let value { Text(value).font(.subheadline).foregroundStyle(Color.inkSoft).lineLimit(1) }
            if chevron { Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Color.inkFaint) }
            if external { Image(systemName: "arrow.up.right").font(.footnote.weight(.semibold)).foregroundStyle(Color.inkFaint) }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .contentShape(Rectangle())
    }
}

struct SettingsToggleRow: View {
    let title: String
    let symbol: String
    @Binding var isOn: Bool
    init(_ title: String, symbol: String, isOn: Binding<Bool>) { self.title = title; self.symbol = symbol; _isOn = isOn }
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: symbol).font(.system(size: 19, weight: .regular)).foregroundStyle(Color.ink).frame(width: 24)
            Toggle(isOn: $isOn) { Text(title).font(.body).foregroundStyle(Color.ink).lineLimit(1) }
                .tint(Color.brand)
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
    }
}

/// Pick one of a few options (appearance, language), Instagram style: a plain list with a tick.
struct OptionsPage<Value: Hashable>: View {
    let title: String
    let options: [(Value, String)]
    @Binding var selection: Value
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(options, id: \.0) { value, name in
                    Button { selection = value; dismiss() } label: {
                        HStack {
                            Text(name).font(.body).foregroundStyle(Color.ink).lineLimit(1)
                            Spacer()
                            Image(systemName: selection == value ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 22)).foregroundStyle(selection == value ? Color.brand : Color.inkFaint)
                        }
                        .padding(.horizontal, 16).frame(height: 54)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .background(Color.bg)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Where the hymns, words and pictures come from, with credit to everyone behind them.
struct CreditsView: View {
    private let credited = HymnBook.shared.credited
    private let writers = Set(HymnBook.shared.hymns.map(\.author).filter { !$0.isEmpty }).count

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    SDALogo(size: 44, color: .brand)
                    Text(t("credits.body")).font(.serif(18)).foregroundStyle(Color.ink).lineSpacing(4)
                }
                .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 8)

                credit(t("credits.hymnalTitle"), t("credits.hymnal"), symbol: "book.closed")
                credit(t("credits.writersTitle"), t("credits.writers", ["n": writers]), symbol: "music.quarternote.3")
                credit(t("credits.photosTitle"), t("credits.photos"), symbol: "photo")
                credit(t("credits.logoTitle"), t("credits.logo"), symbol: "seal")
                if !credited.isEmpty { creditedList }
                credit(t("credits.thanksTitle"), t("credits.thanks"), symbol: "heart")

                MadeByQortn().padding(.top, 28).padding(.bottom, 24)
            }
        }
        .background(Color.bg)
        .navigationTitle(t("settings.credits"))
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Every hymn whose words are used by permission, with its own credit line.
    private var creditedList: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsDivider()
            HStack(spacing: 16) {
                Image(systemName: "c.circle").font(.system(size: 19)).foregroundStyle(Color.ink).frame(width: 24)
                Text(t("credits.permissionTitle")).font(.headline).foregroundStyle(Color.ink).lineLimit(1)
            }
            .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 8)
            ForEach(credited) { h in
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(h.number) · \(h.title)").font(.subheadline.weight(.medium)).foregroundStyle(Color.ink).lineLimit(1)
                    Text(h.credit ?? "").font(.footnote).foregroundStyle(Color.inkSoft).fixedSize(horizontal: false, vertical: true)
                }
                .padding(.leading, 56).padding(.trailing, 16).padding(.vertical, 8)
            }
        }
        .padding(.bottom, 8)
    }

    private func credit(_ title: String, _ body: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsDivider()
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: symbol).font(.system(size: 19)).foregroundStyle(Color.ink).frame(width: 24).padding(.top, 2)
                VStack(alignment: .leading, spacing: 6) {
                    Text(title).font(.headline).foregroundStyle(Color.ink).lineLimit(1)
                    Text(body).font(.subheadline).foregroundStyle(Color.inkSoft).fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 16)
        }
    }
}

/// The member's account: who they are, when their hymns last synced, and deleting the account.
struct AccountView: View {
    @EnvironmentObject private var auth: AuthStore
    @EnvironmentObject private var library: Library
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false
    @State private var deleting = false
    @State private var error: String?

    var body: some View {
        List {
            if let user = auth.currentUser {
                Section {
                    VStack(spacing: 10) {
                        Text(user.initials).font(.title.weight(.semibold)).foregroundStyle(.white)
                            .frame(width: 84, height: 84)
                            .background(LinearGradient(colors: Color.sea, startPoint: .topLeading, endPoint: .bottomTrailing), in: Circle())
                        Text(user.name).font(.title3.weight(.semibold)).lineLimit(1)
                        Text(user.email).font(.subheadline).foregroundStyle(Color.inkSoft).lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .listRowBackground(Color.clear)
                }
                Section {
                    row(t("account.signedInWith"), user.provider == "apple" ? "Apple" : t("account.email"))
                    row(t("account.memberSince"), user.createdAt.formatted(date: .abbreviated, time: .omitted))
                    row(t("account.saved"), "\(library.favourites.count)")
                    row(t("account.lists"), "\(library.lists.count)")
                    HStack {
                        Text(t("account.synced")).lineLimit(1)
                        Spacer()
                        if library.syncing {
                            ProgressView()
                        } else if let d = library.lastSynced {
                            Text(d.formatted(.relative(presentation: .named))).foregroundStyle(Color.inkSoft).lineLimit(1)
                        } else {
                            Text("—").foregroundStyle(Color.inkSoft)
                        }
                    }
                    Button(t("account.syncNow")) { Task { await library.pull() } }
                } footer: {
                    Text(t("account.syncFooter"))
                }
                Section {
                    NavigationLink {
                        PasswordView()
                    } label: {
                        Text(Clerk.shared.user?.passwordEnabled == true ? t("password.change") : t("password.set")).lineLimit(1)
                    }
                } footer: { Text(t("password.footer")) }
                Section {
                    Button(role: .destructive) { confirmDelete = true } label: {
                        HStack {
                            Text(t("account.delete"))
                            Spacer()
                            if deleting { ProgressView() }
                        }
                    }
                    .disabled(deleting)
                } footer: { Text(t("account.deleteFooter")) }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(t("account.title"))
        .navigationBarTitleDisplayMode(.inline)
        .alert(t("account.deleteTitle"), isPresented: $confirmDelete) {
            Button(t("common.cancel"), role: .cancel) {}
            Button(t("common.delete"), role: .destructive) { delete() }
        } message: { Text(t("account.deleteBody")) }
        .alert(t("auth.generic"), isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button(t("common.ok"), role: .cancel) {}
        } message: { Text(error ?? "") }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).lineLimit(1)
            Spacer()
            Text(value).foregroundStyle(Color.inkSoft).lineLimit(1)
        }
    }

    private func delete() {
        guard let id = auth.currentUser?.id else { return }
        deleting = true
        Task {
            do {
                try await auth.deleteAccount()
                library.forget(id)
                dismiss()
            } catch {
                self.error = error.localizedDescription
            }
            deleting = false
        }
    }
}


/// Change the account password, or set one for members who joined with a code, Apple or Google.
struct PasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var app: AppState
    @State private var current = ""
    @State private var new = ""
    @State private var confirm = ""
    @State private var saving = false
    @State private var error: String?
    private let hasPassword = Clerk.shared.user?.passwordEnabled == true

    private var canSave: Bool {
        !saving && new.count >= AuthFlow.minPassword && new == confirm && (!hasPassword || !current.isEmpty)
    }

    var body: some View {
        Form {
            if hasPassword {
                Section {
                    SecureField(t("password.current"), text: $current).textContentType(.password)
                }
            }
            Section {
                SecureField(t("auth.newPassword"), text: $new).textContentType(.newPassword)
                SecureField(t("password.confirm"), text: $confirm).textContentType(.newPassword)
            } footer: {
                if !confirm.isEmpty && new != confirm {
                    Text(t("password.mismatch")).foregroundStyle(Color.bad)
                } else {
                    Text(t("auth.passwordHint"))
                }
            }
            if let error {
                Section { Text(error).foregroundStyle(Color.bad).font(.footnote) }
            }
            Section {
                Button {
                    save()
                } label: {
                    HStack {
                        Text(t("auth.savePassword"))
                        Spacer()
                        if saving { ProgressView() }
                    }
                }
                .disabled(!canSave)
            } footer: { Text(t("password.signOutOthers")) }
        }
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .navigationTitle(hasPassword ? t("password.change") : t("password.set"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func save() {
        guard let user = Clerk.shared.user else { return }
        saving = true
        error = nil
        Task {
            defer { saving = false }
            do {
                _ = try await user.updatePassword(.init(currentPassword: hasPassword ? current : nil, newPassword: new, signOutOfOtherSessions: true))
                app.showToast(t("password.saved"))
                dismiss()
            } catch let e as ClerkAPIError where e.code == "session_reverification_required" {
                error = t("password.reverify")
            } catch {
                self.error = AuthFlow.message(for: error)
            }
        }
    }
}
