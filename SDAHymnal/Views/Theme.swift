import SwiftUI
import UIKit

extension Color {
    init(hex: String) {
        var v: UInt64 = 0
        Scanner(string: hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)).scanHexInt64(&v)
        self.init(.sRGB, red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255, blue: Double(v & 0xFF) / 255, opacity: 1)
    }

    init(light: Color, dark: Color) {
        self.init(UIColor { $0.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light) })
    }

    static let bg = Color(light: .white, dark: .black)
    static let card = Color(light: Color(hex: "F2F6F9"), dark: Color(hex: "0F151B"))
    static let stroke = Color(light: Color(hex: "E2EAF0"), dark: Color(hex: "1E2A34"))
    static let ink = Color(light: Color(hex: "0B1A24"), dark: .white)
    static let inkSoft = Color(light: Color(hex: "5B6B77"), dark: Color(hex: "9AA7B2"))
    static let inkFaint = Color(light: Color(hex: "9AA7B2"), dark: Color(hex: "55626C"))
    /// Sea blue, the app's colour.
    static let brand = Color(light: Color(hex: "0B7DB3"), dark: Color(hex: "3AAEE6"))
    static let good = Color(hex: "22C55E")
    static let bad = Color(hex: "EF4444")
    static let sea: [Color] = [Color(hex: "0B4F75"), Color(hex: "0B6F9F"), Color(hex: "1288B8")]
}

extension Font {
    /// The reading face: Apple's New York serif.
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font { .system(size: size, weight: weight, design: .serif) }
}

extension View {
    /// Liquid Glass on iOS 26, frosted material before it.
    @ViewBuilder func glass(_ radius: CGFloat = 24) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
        } else {
            self.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))
        }
    }

    /// A round glass button background.
    @ViewBuilder func glassCircle() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.interactive(), in: Circle())
        } else {
            self.background(.ultraThinMaterial, in: Circle())
        }
    }

    func card(padding: CGFloat = 18, radius: CGFloat = 24) -> some View {
        self.padding(padding)
            .background(Color.card, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(Color.stroke, lineWidth: 1))
    }

    /// The tab bar shrinks while scrolling down on iOS 26.
    @ViewBuilder func minimizingTabBar() -> some View {
        if #available(iOS 26.0, *) { self.tabBarMinimizeBehavior(.onScrollDown) } else { self }
    }
}

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var tint: Color = .brand
    var foreground: Color = .white
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .lineLimit(1)
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(tint, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

/// The SDA logo, in any colour.
struct SDALogo: View {
    var size: CGFloat = 40
    var color: Color = .white
    var body: some View {
        Image("SDALogo").resizable().renderingMode(.template).scaledToFit()
            .foregroundStyle(color)
            .frame(width: size, height: size * 280 / 314)
            .accessibilityLabel("Seventh-day Adventist")
    }
}

/// "Made by Qortn" with the Qortn logo, at the foot of Settings and the splash.
struct MadeByQortn: View {
    var body: some View {
        HStack(spacing: 8) {
            Image("QortnMark").resizable().scaledToFit().frame(width: 20, height: 20)
            Text("Made by Qortn").font(.footnote).foregroundStyle(Color.inkSoft).lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
