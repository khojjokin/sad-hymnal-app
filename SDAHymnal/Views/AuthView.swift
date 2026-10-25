import SwiftUI

/// Create an account or sign in, full screen: email, then a 6-digit code. Optional; the app works without it.
struct AuthView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var flow = AuthFlow()
    @FocusState private var focus: Field?
    enum Field { case email, first, last, code }

    var body: some View {
        ZStack(alignment: .top) {
            Color.bg.ignoresSafeArea()
            // A quiet photo at the top that fades into the page.
            ZStack {
                Photo(key: "tileHymnal")
                LinearGradient(colors: [Color.sea[0].opacity(0.35), Color.bg.opacity(0.6), Color.bg], startPoint: .top, endPoint: .bottom)
            }
            .frame(height: 380)
            .frame(maxWidth: .infinity)
            .clipped()
            .ignoresSafeArea(edges: .top)

            ScrollView {
                VStack(spacing: 22) {
                    VStack(spacing: 14) {
                        SDALogo(size: 58, color: .white)
                            .padding(18)
                            .background(LinearGradient(colors: Color.sea, startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                            .shadow(color: Color.sea[0].opacity(0.45), radius: 18, y: 8)
                        VStack(spacing: 6) {
                            Text(title).font(.serif(32, .bold)).foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.7)
                            Text(subtitle).font(.subheadline).foregroundStyle(Color.inkSoft).multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 70)

                    VStack(spacing: 12) { content }
                        .padding(18)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(Color.stroke, lineWidth: 1))

                    if let error = flow.error {
                        Label(error, systemImage: "exclamationmark.circle.fill")
                            .font(.footnote.weight(.medium)).foregroundStyle(Color.bad)
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, 22)
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
            if AuthFlow.appleEnabled {
                Button { Task { await flow.continueWithApple() } } label: {
                    socialLabel(Image(systemName: "apple.logo").font(.system(size: 18, weight: .semibold)), t("auth.apple"))
                }
                .buttonStyle(PrimaryButtonStyle(tint: Color.ink, foreground: Color.bg))
                .disabled(flow.busy)
            }
            if AuthFlow.googleEnabled {
                Button { Task { await flow.continueWithGoogle() } } label: {
                    socialLabel(GoogleMark(), t("auth.google"))
                }
                .buttonStyle(OutlineButtonStyle())
                .disabled(flow.busy)
            }
            if AuthFlow.appleEnabled || AuthFlow.googleEnabled {
                HStack(spacing: 10) { line; Text(t("auth.or")).font(.footnote).foregroundStyle(Color.inkSoft); line }
                    .padding(.vertical, 2)
            }
            field(t("auth.email"), text: $flow.email, field: .email, keyboard: .emailAddress, content: .emailAddress)
                .onSubmit { Task { await flow.continueWithEmail() } }
            Button { Task { await flow.continueWithEmail() } } label: { busyLabel(t("auth.continueEmail")) }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(flow.busy || flow.email.isEmpty)
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

    private func socialLabel<I: View>(_ icon: I, _ text: String) -> some View {
        HStack(spacing: 10) {
            icon.frame(width: 22, height: 22)
            Text(text).lineLimit(1)
        }
    }

    private func perk(_ symbol: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.brand)
                .frame(width: 28, height: 28)
                .background(Color.brand.opacity(0.12), in: Circle())
            Text(text).font(.subheadline).foregroundStyle(Color.ink).lineLimit(1)
            Spacer()
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

/// A plain bordered button (Continue with Google).
struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .lineLimit(1)
            .foregroundStyle(Color.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Color.bg, in: Capsule())
            .overlay(Capsule().stroke(Color.stroke, lineWidth: 1.5))
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
