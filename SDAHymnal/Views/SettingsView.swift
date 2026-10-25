import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject private var prefs: Prefs
    @EnvironmentObject private var auth: AuthStore
    @EnvironmentObject private var library: Library
    @EnvironmentObject private var app: AppState
    @Environment(\.requestReview) private var requestReview
    @State private var showAuth = false
    @State private var confirmSignOut = false

    var body: some View {
        NavigationStack {
            List {
                Section { accountRow }

                Section(t("settings.reading")) {
                    Picker(selection: $prefs.appearance) {
                        Text(t("settings.system")).tag(Prefs.Appearance.system)
                        Text(t("settings.light")).tag(Prefs.Appearance.light)
                        Text(t("settings.dark")).tag(Prefs.Appearance.dark)
                    } label: { SettingsLabel(t("settings.appearance"), symbol: "circle.lefthalf.filled", tint: Color(hex: "6366F1")) }
                    .pickerStyle(.navigationLink)

                    Picker(selection: $prefs.language) {
                        ForEach(L10n.languages, id: \.self) { Text(L10n.names[$0] ?? $0).tag($0) }
                    } label: { SettingsLabel(t("settings.language"), symbol: "globe", tint: Color(hex: "0EA5E9")) }
                    .pickerStyle(.navigationLink)

                    VStack(alignment: .leading, spacing: 10) {
                        SettingsLabel(t("settings.textSize"), symbol: "textformat.size", tint: Color(hex: "F97316"))
                        HStack(spacing: 12) {
                            Text("A").font(.system(size: 13))
                            Slider(value: $prefs.textSize, in: Prefs.textRange, step: 1)
                            Text("A").font(.system(size: 22))
                        }
                        .foregroundStyle(Color.inkSoft)
                        Text(t("settings.preview")).font(.serif(prefs.textSize)).foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.5)
                    }
                    .padding(.vertical, 4)

                    Toggle(isOn: $prefs.keepAwake) {
                        SettingsLabel(t("settings.keepAwake"), symbol: "sun.max.fill", tint: Color(hex: "EAB308"))
                    }
                }

                Section {
                    Button { app.tab = .saved } label: {
                        HStack {
                            SettingsLabel(t("settings.saved"), symbol: "bookmark.fill", tint: .brand)
                            Spacer()
                            Text("\(library.favourites.count)").foregroundStyle(Color.inkSoft)
                        }
                    }
                    ShareLink(item: Backend.appStoreURL, message: Text(t("settings.shareMessage"))) {
                        SettingsLabel(t("settings.share"), symbol: "square.and.arrow.up", tint: Color(hex: "22C55E"))
                    }
                    Button { requestReview() } label: {
                        SettingsLabel(t("settings.rate"), symbol: "star.fill", tint: Color(hex: "F59E0B"))
                    }
                }
                .foregroundStyle(Color.ink)

                Section {
                    NavigationLink { CreditsView() } label: {
                        SettingsLabel(t("settings.credits"), symbol: "music.quarternote.3", tint: Color(hex: "8B5CF6"))
                    }
                    Link(destination: Backend.privacyURL) {
                        SettingsLabel(t("settings.privacy"), symbol: "hand.raised.fill", tint: Color(hex: "64748B"))
                    }
                    .foregroundStyle(Color.ink)
                    HStack {
                        SettingsLabel(t("settings.version"), symbol: "info.circle.fill", tint: Color(hex: "94A3B8"))
                        Spacer()
                        Text(Backend.appVersion).foregroundStyle(Color.inkSoft)
                    }
                }

                if auth.isSignedIn {
                    Section {
                        Button(role: .destructive) { confirmSignOut = true } label: {
                            Text(t("account.signOut")).frame(maxWidth: .infinity)
                        }
                    }
                }

                Section {
                    MadeByQortn()
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 6)
                }
            }
            .listStyle(.insetGrouped)
            .tracksScroll()
            .navigationTitle(t("tab.settings"))
            .fullScreenCover(isPresented: $showAuth) { AuthView() }
            .alert(t("account.signOutTitle"), isPresented: $confirmSignOut) {
                Button(t("common.cancel"), role: .cancel) {}
                Button(t("account.signOut"), role: .destructive) { Task { await auth.signOut() } }
            } message: { Text(t("account.signOutBody")) }
        }
    }

    @ViewBuilder private var accountRow: some View {
        if let user = auth.currentUser {
            NavigationLink { AccountView() } label: {
                HStack(spacing: 14) {
                    Text(user.initials).font(.headline).foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(LinearGradient(colors: Color.sea, startPoint: .topLeading, endPoint: .bottomTrailing), in: Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.name).font(.headline).lineLimit(1)
                        Text(user.email).font(.footnote).foregroundStyle(Color.inkSoft).lineLimit(1)
                    }
                }
                .padding(.vertical, 4)
            }
        } else {
            Button { showAuth = true } label: {
                HStack(spacing: 14) {
                    Image(systemName: "person.crop.circle.fill").font(.system(size: 46)).foregroundStyle(Color.brand)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(t("settings.createAccount")).font(.headline).foregroundStyle(Color.ink).lineLimit(1)
                        Text(t("settings.createAccountBody")).font(.footnote).foregroundStyle(Color.inkSoft).lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Color.inkFaint)
                }
                .padding(.vertical, 4)
            }
        }
    }
}

struct SettingsLabel: View {
    let title: String
    let symbol: String
    let tint: Color
    init(_ title: String, symbol: String, tint: Color) { self.title = title; self.symbol = symbol; self.tint = tint }
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(tint, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text(title).lineLimit(1)
        }
    }
}

/// Where the hymns, words and pictures come from.
struct CreditsView: View {
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    SDALogo(size: 44, color: .brand)
                    Text(t("credits.body")).font(.serif(17)).lineSpacing(4)
                }
                .padding(.vertical, 6)
            }
            Section(t("credits.sources")) {
                Text(t("credits.words"))
                Text(t("credits.copyright"))
                Text(t("credits.photos"))
            }
            .font(.subheadline)
            .foregroundStyle(Color.inkSoft)
            Section { MadeByQortn().listRowBackground(Color.clear) }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(t("settings.credits"))
        .navigationBarTitleDisplayMode(.inline)
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
