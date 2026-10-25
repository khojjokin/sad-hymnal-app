import Foundation
import Combine
import ClerkKit

/// The signed-in member (from Clerk). Accounts are optional in SDA Hymnal: everything works without one,
/// and an account keeps saved hymns and lists safe on every device.
struct Account: Equatable {
    let id: String
    var name: String
    var email: String
    var provider: String
    var createdAt: Date

    var initials: String {
        let letters = name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined()
        return letters.isEmpty ? String(email.prefix(1)).uppercased() : letters.uppercased()
    }
}

@MainActor
final class AuthStore: ObservableObject {
    @Published private(set) var currentUser: Account?
    @Published private(set) var state = MemberState()

    private let api = HymnalAPI.shared
    var isSignedIn: Bool { currentUser != nil }

    /// Called whenever Clerk's user changes.
    func update(from user: User?) {
        guard let user else {
            if currentUser != nil { currentUser = nil; state = MemberState() }
            return
        }
        let email = user.primaryEmailAddress?.emailAddress ?? ""
        let full = [user.firstName, user.lastName].compactMap { $0 }.joined(separator: " ").trimmingCharacters(in: .whitespaces)
        let name = full.isEmpty ? (email.split(separator: "@").first.map(String.init) ?? "Friend") : full
        let provider = user.externalAccounts.first.map { String(describing: $0.provider) }?.replacingOccurrences(of: "oauth_", with: "") ?? "email"
        let account = Account(id: user.id, name: name, email: email, provider: provider, createdAt: user.createdAt)
        let isNew = currentUser?.id != account.id
        currentUser = account
        if isNew { Task { await refresh() } }
    }

    func validToken() async -> String? {
        guard currentUser != nil else { return nil }
        return try? await Clerk.shared.auth.getToken()
    }

    /// Registers the member with the hymnal server and reads their account state and notices.
    func refresh() async {
        guard let user = currentUser, let token = await validToken() else { return }
        if let s = try? await api.me(token: token, provider: user.provider) { state = s }
    }

    func acknowledge(_ notice: MemberNotice) async {
        state.notices.removeAll { $0.id == notice.id }
        if let token = await validToken() { await api.acknowledge(token: token, notice: notice.id) }
    }

    func signOut() async {
        try? await Clerk.shared.auth.signOut()
        currentUser = nil
        state = MemberState()
    }

    /// Deletes the account's saved hymns from the server, then the Clerk account itself.
    func deleteAccount() async throws {
        guard currentUser != nil else { return }
        guard let token = await validToken() else { throw BackendError.message(t("account.offline")) }
        try await api.deleteAccount(token: token)
        _ = try await Clerk.shared.user?.delete()
        currentUser = nil
        state = MemberState()
    }
}
