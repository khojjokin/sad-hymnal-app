import SwiftUI
import ClerkKit

/// Create an account or sign in, full screen: email, then a 6-digit code. Optional; the app works without it.
struct AuthView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var app: AppState
    @EnvironmentObject private var auth: AuthStore
    @EnvironmentObject private var library: Library
    @StateObject private var flow = AuthFlow()
    @FocusState private var focus: Field?
    enum Field { case email, first, last, code }

    var body: some View {
        ZStack(alignment: .top) {
            backdrop
            ScrollView {
                VStack(spacing: 0) {
                    heading
                        .padding(.top, 84)
                        .padding(.bottom, 36)
                    VStack(spacing: 12) { content }
                    if let error = flow.error {
                        Label(error, systemImage: "exclamationmark.circle.fill")
                            .font(.footnote.weight(.medium)).foregroundStyle(Color.bad)
                            .lineLimit(2).multilineTextAlignment(.center)
                            .padding(.top, 14)
                            .transition(.opacity)
                    }
                    if flow.step == .email {
                        Link(destination: Backend.privacyURL) {
                            Text(t("auth.terms")).font(.caption).foregroundStyle(Color.inkFaint)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 22)
                    }
                }
                .frame(maxWidth: 440)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .animation(.easeOut(duration: 0.2), value: flow.step)
                .animation(.easeOut(duration: 0.2), value: flow.error)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollIndicators(.hidden)

            HStack {
                if flow.step != .email && flow.step != .done {
                    circleButton("chevron.left", label: t("common.back")) { flow.back(); focus = nil }
                }
                Spacer()
                circleButton("xmark", label: t("common.close")) { dismiss() }
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
        }
        .onChange(of: flow.step) { _, step in
            switch step {
            case .name: focus = .first
            case .code: focus = .code
            case .done:
                // Straight back into the app, with a quick "You're in" over it.
                auth.update(from: Clerk.shared.user)
                let id = auth.currentUser?.id
                Task { await library.switchProfile(to: id) }
                app.showToast(t("auth.toast"))
                dismiss()
            case .email: break
            }
        }
    }

    /// Plain page with a soft sea glow at the top: no photo, nothing behind the words.
    private var backdrop: some View {
        ZStack(alignment: .top) {
            Color.bg
            RadialGradient(colors: [Color.brand.opacity(0.16), Color.clear], center: .top, startRadius: 0, endRadius: 420)
                .frame(height: 520)
        }
        .ignoresSafeArea()
    }

    private var heading: some View {
        VStack(spacing: 18) {
            SDALogo(size: 40, color: .white)
                .frame(width: 76, height: 76)
                .background(LinearGradient(colors: Color.sea, startPoint: .topLeading, endPoint: .bottomTrailing),
                            in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: Color.sea[1].opacity(0.35), radius: 16, y: 8)
            VStack(spacing: 8) {
                Text(title).font(.serif(30, .semibold)).foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.7)
                Text(subtitle).font(.subheadline).foregroundStyle(Color.inkSoft)
                    .multilineTextAlignment(.center).lineLimit(2)
            }
        }
    }

    private var title: String {
        switch flow.step {
        case .email: t("auth.title")
        case .name: t("auth.nameTitle")
        case .code: t("auth.codeTitle")
        case .done: t("auth.doneTitle")
        }
    }

    private var subtitle: String {
        switch flow.step {
        case .email: t("auth.subtitle")
        case .name: t("auth.nameSubtitle")
        case .code(let email): t("auth.codeSubtitle", ["email": email])
        case .done: t("auth.doneSubtitle")
        }
    }

    @ViewBuilder private var content: some View {
        switch flow.step {
        case .email:
            if AuthFlow.appleEnabled {
                Button { Task { await flow.continueWithApple() } } label: {
                    socialLabel(Image(systemName: "apple.logo").font(.system(size: 17, weight: .semibold)), t("auth.apple"))
                }
                .buttonStyle(AuthButtonStyle(fill: Color.ink, text: Color.bg))
                .disabled(flow.busy)
            }
            if AuthFlow.googleEnabled {
                Button { Task { await flow.continueWithGoogle() } } label: {
                    socialLabel(GoogleMark(), t("auth.google"))
                }
                .buttonStyle(AuthButtonStyle(fill: Color.bg, text: Color.ink, border: true))
                .disabled(flow.busy)
            }
            if AuthFlow.appleEnabled || AuthFlow.googleEnabled {
                HStack(spacing: 12) { line; Text(t("auth.or")).font(.footnote).foregroundStyle(Color.inkFaint); line }
                    .padding(.vertical, 6)
            }
            field(t("auth.email"), text: $flow.email, field: .email, keyboard: .emailAddress, content: .emailAddress)
                .onSubmit { Task { await flow.continueWithEmail() } }
            Button { Task { await flow.continueWithEmail() } } label: { busyLabel(t("auth.continueEmail")) }
                .buttonStyle(AuthButtonStyle(fill: Color.brand, text: .white))
                .disabled(flow.busy || flow.email.isEmpty)
        case .name:
            field(t("auth.firstName"), text: $flow.firstName, field: .first, content: .givenName)
                .onSubmit { focus = .last }
            field(t("auth.lastName"), text: $flow.lastName, field: .last, content: .familyName)
                .onSubmit { Task { await flow.createAccount() } }
            Button { Task { await flow.createAccount() } } label: { busyLabel(t("auth.create")) }
                .buttonStyle(AuthButtonStyle(fill: Color.brand, text: .white))
                .disabled(flow.busy)
        case .code:
            CodeField(code: $flow.code)
                .focused($focus, equals: .code)
                .onChange(of: flow.code) { _, c in
                    if c.count == 6 { Task { await flow.verify() } }
                }
            Button { Task { await flow.verify() } } label: { busyLabel(t("auth.verify")) }
                .buttonStyle(AuthButtonStyle(fill: Color.brand, text: .white))
                .disabled(flow.busy || flow.code.count < 6)
            Button(t("auth.resend")) { Task { await flow.resend() } }
                .font(.subheadline.weight(.medium))
                .disabled(flow.busy)
        case .done:
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 54)).foregroundStyle(Color.good)
                Text(t("auth.doneBody")).font(.subheadline).foregroundStyle(Color.inkSoft).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
    }

    private func socialLabel<I: View>(_ icon: I, _ text: String) -> some View {
        HStack(spacing: 8) {
            icon.frame(width: 20, height: 20)
            Text(text).lineLimit(1)
        }
    }

    private var line: some View { Rectangle().fill(Color.stroke).frame(height: 1) }

    private func busyLabel(_ text: String) -> some View {
        ZStack {
            Text(text).opacity(flow.busy ? 0 : 1)
            if flow.busy { ProgressView().tint(.white) }
        }
    }

    private func field(_ placeholder: String, text: Binding<String>, field: Field, keyboard: UIKeyboardType = .default, content: UITextContentType) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(keyboard)
            .textContentType(content)
            .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
            .autocorrectionDisabled()
            .submitLabel(.continue)
            .focused($focus, equals: field)
            .font(.body)
            .padding(.horizontal, 16)
            .frame(height: 50)
            .background(Color.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(focus == field ? Color.brand : Color.clear, lineWidth: 1.5))
    }

    private func circleButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 14, weight: .bold)).foregroundStyle(Color.inkSoft)
                .frame(width: 36, height: 36)
                .background(Color.card, in: Circle())
        }
        .accessibilityLabel(label)
    }
}

/// Six boxes for the email code, backed by one hidden field so paste and autofill work.
struct CodeField: View {
    @Binding var code: String
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            TextField("", text: Binding(get: { code }, set: { code = String($0.filter(\.isNumber).prefix(6)) }))
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($focused)
                .opacity(0.02)
                .accessibilityLabel(t("auth.code"))
            HStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { i in
                    let chars = Array(code)
                    Text(i < chars.count ? String(chars[i]) : "")
                        .font(.serif(26, .semibold)).monospacedDigit()
                        .foregroundStyle(Color.ink)
                        .frame(maxWidth: .infinity).frame(height: 58)
                        .background(Color.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(i == chars.count ? Color.brand : Color.stroke, lineWidth: i == chars.count ? 2 : 1))
                }
            }
            .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .onTapGesture { focused = true }
        .onAppear { focused = true }
    }
}

/// The sign in buttons: 50 pt tall, rounded, 17 pt semibold (Apple's Sign in with Apple proportions).
struct AuthButtonStyle: ButtonStyle {
    var fill: Color
    var text: Color
    var border = false
    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        return configuration.label
            .font(.system(size: 17, weight: .semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .foregroundStyle(text)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(fill, in: shape)
            .overlay(shape.stroke(border ? Color.stroke : Color.clear, lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

/// Google's "G" for the Google button: the official artwork from Google's sign in branding kit, added to the
/// asset catalogue as "GoogleG". Until it's added, a plain "G" stands in.
struct GoogleMark: View {
    var body: some View {
        if UIImage(named: "GoogleG") != nil {
            Image("GoogleG").resizable().scaledToFit().frame(width: 20, height: 20).accessibilityHidden(true)
        } else {
            Text("G")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(Color.ink)
                .frame(width: 22, height: 22)
                .accessibilityHidden(true)
        }
    }
}
