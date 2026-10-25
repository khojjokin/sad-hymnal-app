import Foundation
import Combine
import ClerkKit

/// SDA Hymnal's own sign-in screens on top of Clerk: enter an email, get a 6-digit code, done.
/// New emails are asked for a name first. Apple sign-in shows once it's switched on in Clerk.
@MainActor
final class AuthFlow: ObservableObject {
    enum Step: Equatable {
        case email
        case name
        case code(email: String)
        case done
    }

    @Published var step: Step = .email
    @Published var busy = false
    @Published var error: String?
    @Published var email = ""
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var code = ""

    private var signIn: SignIn?
    private var signUp: SignUp?

    static var appleEnabled: Bool { Clerk.shared.environment?.userSettings.social["oauth_apple"]?.enabled ?? false }

    var trimmedEmail: String { email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
    var emailLooksValid: Bool {
        let e = trimmedEmail
        guard let at = e.firstIndex(of: "@"), at != e.startIndex else { return false }
        return e[e.index(after: at)...].contains(".")
    }

    /// Existing members get a code; a new email moves on to the name step.
    func continueWithEmail() async {
        guard emailLooksValid else { error = t("auth.badEmail"); return }
        await run {
            do {
                let attempt = try await Clerk.shared.auth.signInWithEmailCode(emailAddress: self.trimmedEmail)
                self.signIn = attempt
                self.signUp = nil
                self.code = ""
                self.step = .code(email: self.trimmedEmail)
            } catch let e as ClerkAPIError where e.code == "form_identifier_not_found" {
                self.step = .name
            }
        }
    }

    func createAccount() async {
        guard !firstName.trimmingCharacters(in: .whitespaces).isEmpty else { error = t("auth.needName"); return }
        await run {
            var attempt = try await Clerk.shared.auth.signUp(
                emailAddress: self.trimmedEmail,
                firstName: self.firstName.trimmingCharacters(in: .whitespaces),
                lastName: self.lastName.trimmingCharacters(in: .whitespaces).nilIfEmpty)
            if attempt.status == .complete { self.step = .done; return }
            attempt = try await attempt.sendEmailCode()
            self.signUp = attempt
            self.signIn = nil
            self.code = ""
            self.step = .code(email: self.trimmedEmail)
        }
    }

    func verify() async {
        let entered = code.filter(\.isNumber)
        guard entered.count == 6 else { return }
        await run {
            if let s = self.signUp {
                let result = try await s.verifyEmailCode(entered)
                guard result.status == .complete else { throw FlowError(t("auth.notFinished")) }
            } else if let s = self.signIn {
                let result = try await s.verifyCode(entered)
                guard result.status == .complete else { throw FlowError(t("auth.notFinished")) }
            } else {
                throw FlowError(t("auth.expired"))
            }
            self.step = .done
        }
        if error != nil { code = "" }
    }

    func resend() async {
        await run {
            if let s = self.signUp { self.signUp = try await s.sendEmailCode() }
            else if let s = self.signIn { self.signIn = try await s.sendEmailCode() }
        }
    }

    func continueWithApple() async {
        await run {
            let result = try await Clerk.shared.auth.signInWithApple()
            switch result {
            case .signIn(let s): if s.status == .complete { self.step = .done } else { throw FlowError(t("auth.notFinished")) }
            case .signUp(let s): if s.status == .complete { self.step = .done } else { throw FlowError(t("auth.notFinished")) }
            }
        }
    }

    func back() {
        error = nil
        code = ""
        step = .email
    }

    private func run(_ work: @escaping @MainActor () async throws -> Void) async {
        guard !busy else { return }
        busy = true
        error = nil
        defer { busy = false }
        do {
            try await work()
        } catch {
            if AuthFlow.isCancellation(error) { return }
            self.error = AuthFlow.message(for: error)
        }
    }

    static func isCancellation(_ error: Error) -> Bool {
        let ns = error as NSError
        if ns.domain == "com.apple.AuthenticationServices.AuthorizationError" && ns.code == 1001 { return true }
        return error is CancellationError
    }

    static func message(for error: Error) -> String {
        if let api = error as? ClerkAPIError {
            switch api.code {
            case "form_code_incorrect": return t("auth.wrongCode")
            case "verification_expired": return t("auth.codeExpired")
            case "form_identifier_exists": return t("auth.exists")
            case "too_many_requests", "user_locked": return t("auth.tooMany")
            default: return api.longMessage ?? api.message ?? t("auth.generic")
            }
        }
        if let flow = error as? FlowError { return flow.text }
        if (error as NSError).domain == NSURLErrorDomain { return t("auth.offline") }
        return error.localizedDescription
    }
}

struct FlowError: Error {
    let text: String
    init(_ text: String) { self.text = text }
}

extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
