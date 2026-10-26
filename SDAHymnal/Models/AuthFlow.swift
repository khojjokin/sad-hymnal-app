import Foundation
import Combine
import ClerkKit

/// SDA Hymnal's own sign-in screens on top of Clerk. Members choose how to get in: an email code, a password,
/// or Apple and Google. New emails are asked for a name (and an optional password) first.
/// Forgot password sends a reset code by email, then sets the new password.
@MainActor
final class AuthFlow: ObservableObject {
    enum Step: Equatable {
        case email
        case name
        case code(email: String)
        case password(email: String)
        case reset(email: String)
        case done
    }

    @Published var step: Step = .email
    @Published var busy = false
    @Published var error: String?
    @Published var email = ""
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var code = ""
    @Published var password = ""
    @Published var newPassword = ""
    /// Sign in or create an account: the first page switches between them.
    @Published var creating = false

    static let minPassword = 8

    private var signIn: SignIn?
    private var signUp: SignUp?

    /// Apple and Google show unless the sign-in service has them switched off.
    static var appleEnabled: Bool { Clerk.shared.environment?.userSettings.social["oauth_apple"]?.enabled ?? true }
    static var googleEnabled: Bool { Clerk.shared.environment?.userSettings.social["oauth_google"]?.enabled ?? true }

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

    /// Create account: email first, then name and an optional password.
    func startAccount() {
        guard emailLooksValid else { error = t("auth.badEmail"); return }
        error = nil
        password = ""
        step = .name
    }

    func toggleMode() {
        error = nil
        creating.toggle()
    }

    /// Email first, then the password page.
    func usePassword() {
        guard emailLooksValid else { error = t("auth.badEmail"); return }
        error = nil
        password = ""
        step = .password(email: trimmedEmail)
    }

    func signInWithPassword() async {
        guard !password.isEmpty else { return }
        await run {
            let attempt = try await Clerk.shared.auth.signInWithPassword(identifier: self.trimmedEmail, password: self.password)
            guard attempt.status == .complete else { throw FlowError(t("auth.notFinished")) }
            self.step = .done
        }
        if error != nil { password = "" }
    }

    /// Sends a reset code to the email; the next page takes the code and the new password.
    func forgotPassword() async {
        guard emailLooksValid else { error = t("auth.badEmail"); return }
        await run {
            var attempt = try await Clerk.shared.auth.signIn(self.trimmedEmail)
            guard attempt.supportedFirstFactors?.contains(where: { $0.strategy == .resetPasswordEmailCode }) == true else {
                throw FlowError(t("auth.noPassword"))
            }
            attempt = try await attempt.sendResetPasswordEmailCode()
            self.signIn = attempt
            self.signUp = nil
            self.code = ""
            self.newPassword = ""
            self.step = .reset(email: self.trimmedEmail)
        }
    }

    func resetPassword() async {
        let entered = code.filter(\.isNumber)
        guard entered.count == 6 else { error = t("auth.needCode"); return }
        guard newPassword.count >= Self.minPassword else { error = t("auth.shortPassword"); return }
        await run {
            guard var attempt = self.signIn else { throw FlowError(t("auth.expired")) }
            attempt = try await attempt.verifyCode(entered)
            if attempt.status == .needsNewPassword {
                attempt = try await attempt.resetPassword(newPassword: self.newPassword, signOutOfOtherSessions: true)
            }
            guard attempt.status == .complete else { throw FlowError(t("auth.notFinished")) }
            self.step = .done
        }
    }

    func createAccount() async {
        guard !firstName.trimmingCharacters(in: .whitespaces).isEmpty else { error = t("auth.needName"); return }
        guard password.isEmpty || password.count >= Self.minPassword else { error = t("auth.shortPassword"); return }
        await run {
            var attempt = try await Clerk.shared.auth.signUp(
                emailAddress: self.trimmedEmail,
                password: self.password.isEmpty ? nil : self.password,
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
            else if let s = self.signIn {
                if case .reset = self.step { self.signIn = try await s.sendResetPasswordEmailCode() }
                else { self.signIn = try await s.sendEmailCode() }
            }
        }
    }

    /// Apple: the native Sign in with Apple sheet.
    func continueWithApple() async {
        await run {
            let result = try await Clerk.shared.auth.signInWithApple()
            try self.finish(result)
        }
    }

    func continueWithGoogle() async {
        await run {
            let result = try await Clerk.shared.auth.signInWithOAuth(provider: .google)
            try self.finish(result)
        }
    }

    private func finish(_ result: TransferFlowResult) throws {
        switch result {
        case .signIn(let s): if s.status == .complete { step = .done } else { throw FlowError(t("auth.notFinished")) }
        case .signUp(let s): if s.status == .complete { step = .done } else { throw FlowError(t("auth.notFinished")) }
        }
    }

    func back() {
        error = nil
        code = ""
        if case .reset(let email) = step { step = .password(email: email); return }
        password = ""
        step = .email
    }

    private func run(_ work: @escaping @MainActor () async throws -> Void) async {
        guard !busy else { return }
        busy = true
        error = nil
        defer { busy = false }
        do {
            try await work()
        } catch let e as ClerkAPIError where e.code == "session_exists" {
            // Clerk already holds a session on this phone: that's a sign in, so finish instead of showing an error.
            self.step = .done
        } catch {
            if AuthFlow.isCancellation(error) { return }
            self.error = AuthFlow.message(for: error)
        }
    }

    static func isCancellation(_ error: Error) -> Bool {
        let ns = error as NSError
        if ns.domain == "com.apple.AuthenticationServices.AuthorizationError" && ns.code == 1001 { return true }
        if ns.domain == "com.apple.AuthenticationServices.WebAuthenticationSession" && ns.code == 1 { return true }
        return error is CancellationError
    }

    static func message(for error: Error) -> String {
        if let api = error as? ClerkAPIError {
            switch api.code {
            case "form_code_incorrect": return t("auth.wrongCode")
            case "verification_expired": return t("auth.codeExpired")
            case "form_identifier_exists": return t("auth.exists")
            case "form_identifier_not_found": return t("auth.noAccount")
            case "form_password_incorrect": return t("auth.wrongPassword")
            case "strategy_for_user_invalid": return t("auth.noPassword")
            case "form_password_pwned": return t("auth.pwned")
            case "form_password_length_too_short", "form_password_size_in_bytes_exceeded": return t("auth.shortPassword")
            case "form_password_validation_failed", "form_password_not_strong_enough": return t("auth.weakPassword")
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
