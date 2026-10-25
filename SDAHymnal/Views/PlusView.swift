import SwiftUI
import StoreKit

/// The SDA Hymnal Plus page, full screen.
struct PlusView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var plus = Plus.shared

    private struct Feature: Identifiable {
        let id: String
        let symbol: String
        let tint: String
    }

    private let features = [
        Feature(id: "projector", symbol: "tv.and.mediabox.fill", tint: "3AAEE6"),
        Feature(id: "planner", symbol: "list.bullet.rectangle.portrait.fill", tint: "E0B354"),
        Feature(id: "studio", symbol: "paintpalette.fill", tint: "F472B6"),
        Feature(id: "noads", symbol: "nosign", tint: "34D399"),
    ]

    private static let night = Color(hex: "06121F")
    private static let deep = Color(hex: "0B2D4A")
    private static let gold = Color(hex: "E0B354")

    var body: some View {
        ZStack(alignment: .topTrailing) {
            backdrop
            ScrollView {
                content.padding(.horizontal, 22)
            }
            .scrollIndicators(.hidden)
            closeButton
        }
        .preferredColorScheme(.dark)
        .task { await plus.load() }
    }

    private var backdrop: some View {
        ZStack {
            LinearGradient(colors: [Self.night, Self.deep, Self.night], startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [Self.gold.opacity(0.28), Color.clear], center: .top, startRadius: 10, endRadius: 320)
        }
        .ignoresSafeArea()
    }

    private var content: some View {
        VStack(spacing: 26) {
            crest.padding(.top, 54)
            heading
            VStack(spacing: 12) {
                ForEach(features) { f in featureRow(f) }
            }
            purchase
            errorText
            links
        }
    }

    private var heading: some View {
        VStack(spacing: 8) {
            Text("SDA Hymnal Plus").font(.serif(34, .bold)).foregroundStyle(Color.white).lineLimit(1).minimumScaleFactor(0.8)
            Text(t("plus.tagline")).font(.subheadline).foregroundStyle(Color.white.opacity(0.75)).multilineTextAlignment(.center)
        }
    }

    @ViewBuilder private var purchase: some View {
        if plus.isPlus {
            Label(t("plus.active"), systemImage: "checkmark.seal.fill")
                .font(.headline).foregroundStyle(Color(hex: "34D399"))
                .padding(.vertical, 8)
            Button(t("plus.manage")) { manage() }
                .buttonStyle(PrimaryButtonStyle(tint: Color.white.opacity(0.14)))
        } else {
            VStack(spacing: 10) {
                Button { buy() } label: { buyLabel }
                    .buttonStyle(PrimaryButtonStyle(tint: Self.gold, foreground: Self.night))
                    .disabled(plus.busy)
                Text(t("plus.terms", ["price": plus.price]))
                    .font(.caption).foregroundStyle(Color.white.opacity(0.6)).multilineTextAlignment(.center)
            }
        }
    }

    private var buyLabel: some View {
        ZStack {
            Text(t("plus.subscribe", ["price": plus.price])).opacity(plus.busy ? 0 : 1)
            if plus.busy { ProgressView().tint(Self.night) }
        }
    }

    @ViewBuilder private var errorText: some View {
        if let e = plus.error {
            Text(e).font(.footnote).foregroundStyle(Color(hex: "FCA5A5")).multilineTextAlignment(.center)
        }
    }

    private var links: some View {
        HStack(spacing: 18) {
            Button(t("plus.restore")) { Task { await plus.restore() } }
            Link(t("plus.termsLink"), destination: Self.eula)
            Link(t("settings.privacy"), destination: Backend.privacyURL)
        }
        .font(.footnote.weight(.medium))
        .foregroundStyle(Color.white.opacity(0.75))
        .padding(.bottom, 30)
    }

    private static let eula = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    private var closeButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "xmark").font(.system(size: 15, weight: .bold)).foregroundStyle(Color.white)
                .frame(width: 40, height: 40).glassCircle()
        }
        .padding(.trailing, 18).padding(.top, 8)
        .accessibilityLabel(t("common.close"))
    }

    private func buy() {
        Task { if await plus.subscribe() { dismiss() } }
    }

    private func manage() {
        Task {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                try? await AppStore.showManageSubscriptions(in: scene)
            }
        }
    }

    private static let ring = LinearGradient(colors: [Color(hex: "F5D78E"), Color(hex: "B8862F")], startPoint: .top, endPoint: .bottom)

    private var crest: some View {
        ZStack {
            Circle().stroke(Self.ring, lineWidth: 2).frame(width: 118, height: 118)
            Circle().fill(Color.white.opacity(0.05)).frame(width: 104, height: 104)
            SDALogo(size: 54, color: Color(hex: "F5D78E"))
        }
        .shadow(color: Self.gold.opacity(0.4), radius: 24)
    }

    private func featureRow(_ f: Feature) -> some View {
        let tint = Color(hex: f.tint)
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        return HStack(alignment: .top, spacing: 14) {
            Image(systemName: f.symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 44, height: 44)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(t("plus.\(f.id).title")).font(.headline).foregroundStyle(Color.white).lineLimit(1)
                Text(t("plus.\(f.id).body")).font(.subheadline).foregroundStyle(Color.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color.white.opacity(0.06), in: shape)
        .overlay(shape.stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}
