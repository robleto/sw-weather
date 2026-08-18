import StoreKit

/// StoreKit 2 wrapper around the app's single non-consumable in-app purchase.
///
/// This is the *only* place that talks to StoreKit. Entitlement is derived
/// entirely from `Transaction.currentEntitlements` on-device — there is no
/// server, no receipt-validation backend, and no login: Apple's ID is the
/// account system. `AppStore.sync()` is what "Restore Purchases" means here.
///
/// Nothing outside `Store/` should read `isPremium` directly — see
/// `PremiumGate`, which is the single per-capability decision point that
/// call sites are expected to use instead.
@Observable
@MainActor
final class PremiumStore {
    static let shared = PremiumStore()
    static let productID = "com.robleto.galacticweather.premium"

    /// The real entitlement, derived from StoreKit. Read `isPremium` instead
    /// — in debug builds it can be overridden.
    private(set) var entitlementIsActive: Bool = false

    #if DEBUG
    /// Debug-only entitlement override, driven by the toggle on the Account
    /// screen. `nil` means "defer to StoreKit".
    ///
    /// This exists because the honest paths for flipping *back* to free are
    /// tedious mid-design-iteration: Xcode's Debug > StoreKit > Manage
    /// Transactions, or deleting the app. Compiled out of release builds
    /// entirely, so it can't ship as a way to bypass paying.
    var debugPremiumOverride: Bool?
    #endif

    var isPremium: Bool {
        #if DEBUG
        if let debugPremiumOverride { return debugPremiumOverride }
        #endif
        return entitlementIsActive
    }

    private(set) var product: Product?
    private(set) var isPurchasing: Bool = false
    private(set) var isRestoring: Bool = false
    private(set) var lastErrorMessage: String?

    /// Guards `start()` so repeated calls (e.g. from a SwiftUI `.task` that
    /// re-runs on every appearance) only do the work once.
    private var didStart = false

    /// Long-lived listener for `Transaction.updates`. Held onto so it isn't
    /// deallocated (and cancelled) once `start()` returns.
    private var transactionListenerTask: Task<Void, Never>?

    private init() {}

    /// Human-facing price, e.g. "$2.99", or "—" before the product loads.
    ///
    /// Always StoreKit's own string, never a local constant: it arrives already
    /// localized and currency-converted, and it comes from App Store Connect in
    /// sandbox and production. `StoreKitConfig/Products.storekit` only supplies it
    /// in the Simulator, so the two can disagree — which is why nothing here
    /// hardcodes a number.
    var displayPrice: String {
        product?.displayPrice ?? "—"
    }

    /// Idempotent. Safe to call from a SwiftUI `.task` on every appearance.
    /// Loads the product, refreshes the entitlement, and starts the
    /// `Transaction.updates` listener exactly once.
    func start() async {
        guard !didStart else { return }
        didStart = true

        transactionListenerTask = Task { [weak self] in
            for await update in Transaction.updates {
                guard case .verified(let transaction) = update else { continue }
                await transaction.finish()
                await self?.refreshEntitlement()
            }
        }

        async let productLoad: Void = loadProduct()
        async let entitlementRefresh: Void = refreshEntitlement()
        _ = await (productLoad, entitlementRefresh)
    }

    private func loadProduct() async {
        do {
            product = try await Product.products(for: [Self.productID]).first
        } catch {
            lastErrorMessage = "Couldn't reach the App Store. Please try again later."
        }
    }

    func refreshEntitlement() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == Self.productID && transaction.revocationDate == nil {
                owned = true
            }
        }
        entitlementIsActive = owned
    }

    func purchase() async {
        guard let product, !isPurchasing else { return }
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await refreshEntitlement()
                case .unverified:
                    lastErrorMessage = "We couldn't verify that purchase. Please try again."
                }
            case .userCancelled:
                lastErrorMessage = nil
            case .pending:
                lastErrorMessage = "Your purchase is pending approval."
            @unknown default:
                lastErrorMessage = "Something unexpected happened. Please try again."
            }
        } catch {
            lastErrorMessage = "Purchase failed. Please try again."
        }
    }

    func restorePurchases() async {
        isRestoring = true
        defer { isRestoring = false }

        do {
            try await AppStore.sync()
        } catch {
            lastErrorMessage = "Couldn't restore purchases. Please try again."
            return
        }

        await refreshEntitlement()

        if !entitlementIsActive {
            lastErrorMessage = "No previous purchase found on this Apple ID."
        }
    }

    func clearError() {
        lastErrorMessage = nil
    }
}
