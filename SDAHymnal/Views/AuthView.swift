import SwiftUI

/// Create an account or sign in, full screen: email, then a 6-digit code. Optional; the app works without it.
struct AuthView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var flow = AuthFlow()
    @FocusState private var focus: Field?
    enum Field { case email, first, last, code }

    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [Color.sea[0], Color.sea[1], Color.bg], startPoint: .top, endPoint: .center)
                .ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    SDALogo(size: 52)
                        .padding(.top, 60)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(title).font(.serif(32, .semibold)).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.7)
                        Text(subtitle).font(.body).foregroundStyle(.white.opacity(0.85))
                    }
                    VStack(spacing: 14) { content }
                        .padding(20)
                        .background(Color.bg, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .shadow(color: .black.opacity(0.12), radius: 20, y: 8)
                    if let error = flow.error {
                        Label(error, systemImage: "exclamationmark.circle.fill")
                            .font(.footnote.weight(.medium)).foregroundStyle(Color.bad)
                            .transition(.opacity)
                    }
                    Text(t("auth.optional")).font(.footnote).foregroundStyle(Color.inkSoft).frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 40)
                .animation(.easeOut(duration: 0.2), value: flow.step)
                .animation(.easeOut(duration: 0.2), value: flow.error)
            }
            .scrollDismissesKeyboard(.interactively)
            HStack {
                if flow.step != .email && flow.step != .done {
                    circleButton("chevron.left", label: t("common.back")) { flow.back(); focus = .email }
                }
                Spacer()
                circleButton("xmark", label: t("common.close")) { dismiss() }
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
        }
        .onAppear { focus = .email }
        .onChange(of: flow.step) { _, step in
            switch step {
            case .name: focus = .first
            case .code: focus = .code
            case .done:
                Task { try? await Task.sleep(for: .seconds(1.2)); dismiss() }
            case .email: break
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
            field(t("auth.email"), text: $flow.email, field: .email, keyboard: .emailAddress, content: .emailAddress)
                .onSubmit { Task { await flow.continueWithEmail() } }
            Button { Task { await flow.continueWithEmail() } } label: { busyLabel(t("auth.continue")) }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(flow.busy)
            if AuthFlow.appleEnabled {
                HStack { line; Text(t("auth.or")).font(.footnote).foregroundStyle(Color.inkSoft); line }
                Button { Task { await flow.continueWithApple() } } label: {
                    Label(t("auth.apple"), systemImage: "apple.logo")
                }
                .buttonStyle(PrimaryButtonStyle(tint: Color.ink, foreground: Color.bg))
                .disabled(flow.busy)
            }
        case .name:
            field(t("auth.firstName"), text: $flow.firstName, field: .first, content: .givenName)
                .onSubmit { focus = .last }
            field(t("auth.lastName"), text: $flow.lastName, field: .last, content: .familyName)
                .onSubmit { Task { await flow.createAccount() } }
            Button { Task { await flow.createAccount() } } label: { busyLabel(t("auth.create")) }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(flow.busy)
        case .code:
            CodeField(code: $flow.code)
                .focused($focus, equals: .code)
                .onChange(of: flow.code) { _, c in
                    if c.count == 6 { Task { await flow.verify() } }
                }
            Button { Task { await flow.verify() } } label: { busyLabel(t("auth.verify")) }
                .buttonStyle(PrimaryButtonStyle())
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
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(Color.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(focus == field ? Color.brand : Color.stroke, lineWidth: focus == field ? 2 : 1))
    }

    private func circleButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                .frame(width: 40, height: 40).glassCircle()
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
