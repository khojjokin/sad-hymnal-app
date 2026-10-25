import SwiftUI

/// Settings › Contact support: a chat with the SDA Hymnal team. Replies come from the Qortn Console.
/// Works with or without an account (guests are known by a random id on this device).
struct SupportView: View {
    @EnvironmentObject private var auth: AuthStore
    @Environment(\.dismiss) private var dismiss
    @State private var messages: [SupportMessage] = []
    @State private var input = ""
    @State private var sending = false
    @State private var error: String?
    @FocusState private var focused: Bool

    private let poll = Timer.publish(every: 6, on: .main, in: .common).autoconnect()
    private static let email = URL(string: "mailto:support@qortyn.com?subject=SDA%20Hymnal")!

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        intro
                        ForEach(messages) { m in bubble(m).id(m.id) }
                        if let error {
                            Text(error).font(.footnote).foregroundStyle(Color.bad).frame(maxWidth: .infinity)
                        }
                    }
                    .padding(16)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: messages) { _, m in withAnimation { proxy.scrollTo(m.last?.id, anchor: .bottom) } }
            }
            inputBar
        }
        .background(Color.bg.ignoresSafeArea())
        .task { await load(initial: true) }
        .onReceive(poll) { _ in Task { await load(initial: false) } }
    }

    private var header: some View {
        HStack(spacing: 12) {
            SDALogo(size: 20, color: .white)
                .frame(width: 40, height: 40)
                .background(LinearGradient(colors: Color.sea, startPoint: .topLeading, endPoint: .bottomTrailing), in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(t("support.team")).font(.headline).foregroundStyle(Color.ink).lineLimit(1)
                Text(t("support.reply")).font(.caption).foregroundStyle(Color.inkSoft).lineLimit(1)
            }
            Spacer(minLength: 8)
            Button { dismiss() } label: {
                Image(systemName: "xmark").font(.system(size: 14, weight: .bold)).foregroundStyle(Color.inkSoft)
                    .frame(width: 34, height: 34).background(Color.card, in: Circle())
            }
            .accessibilityLabel(t("common.close"))
        }
        .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 10)
        .overlay(alignment: .bottom) { Divider().opacity(0.5) }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(t("support.intro")).font(.subheadline).foregroundStyle(Color.inkSoft)
            Link(t("support.email"), destination: Self.email).font(.subheadline.weight(.semibold))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.bottom, 6)
    }

    private func bubble(_ m: SupportMessage) -> some View {
        HStack {
            if !m.fromTeam { Spacer(minLength: 50) }
            VStack(alignment: m.fromTeam ? .leading : .trailing, spacing: 3) {
                Text(m.body)
                    .font(.body)
                    .foregroundStyle(m.fromTeam ? Color.ink : .white)
                    .textSelection(.enabled)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(m.fromTeam ? Color.card : Color.brand, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                Text(m.at.formatted(date: .omitted, time: .shortened)).font(.caption2).foregroundStyle(Color.inkFaint)
            }
            if m.fromTeam { Spacer(minLength: 50) }
        }
    }

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField(t("support.placeholder"), text: $input, axis: .vertical)
                .lineLimit(1...5)
                .focused($focused)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(Color.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            Button { Task { await send() } } label: {
                ZStack {
                    if sending { ProgressView().tint(.white) } else { Image(systemName: "arrow.up").font(.system(size: 16, weight: .bold)) }
                }
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(canSend ? Color.brand : Color.inkFaint, in: Circle())
            }
            .disabled(!canSend)
            .accessibilityLabel(t("support.send"))
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(.bar)
    }

    private var canSend: Bool { !sending && !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    private func token() async -> String? { auth.isSignedIn ? await auth.validToken() : nil }

    private func load(initial: Bool) async {
        do {
            let new = try await HymnalAPI.shared.supportMessages(token: await token(), after: initial ? nil : messages.last?.id)
            if initial { messages = new } else if !new.isEmpty { messages.append(contentsOf: new.filter { n in !messages.contains { $0.id == n.id } }) }
            error = nil
        } catch {
            if initial && !messages.isEmpty { self.error = error.localizedDescription }
        }
    }

    private func send() async {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        sending = true
        defer { sending = false }
        do {
            try await HymnalAPI.shared.sendSupport(token: await token(), text: text)
            input = ""
            await load(initial: false)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
