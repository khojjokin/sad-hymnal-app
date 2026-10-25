import SwiftUI
import StoreKit

/// SDA Hymnal Plus: £2 a month. The whole hymnal stays free; Plus adds extras for people who lead worship
/// and love to share: Projector mode, the Service planner, Card studio, and no ads.
@MainActor
final class Plus: ObservableObject {
    static let shared = Plus()
    static let monthlyID = "com.mojo.sdahymnal.plus.monthly"

    @Published private(set) var isPlus = false
    @Published private(set) var product: Product?
    @Published private(set) var busy = false
    @Published var error: String?
    @Published private(set) var renews: Date?

    private var updates: Task<Void, Never>?

    init() {
        isPlus = UserDefaults.standard.bool(forKey: "hymnal.plus")
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let t) = result { await t.finish() }
                await self?.refresh()
            }
        }
    }

    var price: String { product?.displayPrice ?? "£1.99" }

    func load() async {
        if product == nil { product = try? await Product.products(for: [Self.monthlyID]).first }
        await refresh()
    }

    /// Checks what the App Store says this Apple account owns.
    func refresh() async {
        var active = false
        var until: Date?
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result, t.productID == Self.monthlyID, t.revocationDate == nil {
                active = true
                until = t.expirationDate
            }
        }
        isPlus = active
        renews = until
        UserDefaults.standard.set(active, forKey: "hymnal.plus")
    }

    func subscribe() async -> Bool {
        guard !busy else { return false }
        busy = true
        error = nil
        defer { busy = false }
        if product == nil { await load() }
        guard let product else { error = t("plus.unavailable"); return false }
        do {
            switch try await product.purchase() {
            case .success(let result):
                if case .verified(let t) = result { await t.finish() }
                await refresh()
                return isPlus
            case .pending, .userCancelled: return false
            @unknown default: return false
            }
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func restore() async {
        busy = true
        defer { busy = false }
        try? await AppStore.sync()
        await refresh()
        if !isPlus { error = t("plus.nothingToRestore") }
    }
}

/// Shows Plus extras to members and the Plus page to everyone else.
struct PlusGate: ViewModifier {
    @Binding var showPaywall: Bool
    func body(content: Content) -> some View {
        content.fullScreenCover(isPresented: $showPaywall) { PlusView() }
    }
}

/// A small "PLUS" tag for locked extras.
struct PlusBadge: View {
    var body: some View {
        Text("PLUS")
            .font(.system(size: 9, weight: .heavy, design: .rounded))
            .tracking(0.6)
            .foregroundStyle(.white)
            .padding(.horizontal, 6).padding(.vertical, 3)
            .background(LinearGradient(colors: [Color(hex: "E0B354"), Color(hex: "B8862F")], startPoint: .topLeading, endPoint: .bottomTrailing), in: Capsule())
            .accessibilityLabel("Plus")
    }
}
