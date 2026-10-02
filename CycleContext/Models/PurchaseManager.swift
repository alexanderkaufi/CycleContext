import Combine
import Foundation
import Security
import StoreKit

enum PurchaseProductID {
    static let annual = "com.bentosoftware.CycleContext.annual"
    static let lifetime = "com.bentosoftware.CycleContext.lifetime"

    static let all = [annual, lifetime]
}

enum AnnualSubscriptionState: Equatable {
    case none
    case active(willAutoRenew: Bool?, expirationDate: Date?, isInGracePeriod: Bool)
    case inactive

    var grantsAccess: Bool {
        if case .active = self { return true }
        return false
    }

    var willAutoRenew: Bool? {
        guard case .active(let willAutoRenew, _, _) = self else { return nil }
        return willAutoRenew
    }

    var expirationDate: Date? {
        guard case .active(_, let expirationDate, _) = self else { return nil }
        return expirationDate
    }

    var isInGracePeriod: Bool {
        guard case .active(_, _, let isInGracePeriod) = self else { return false }
        return isInGracePeriod
    }
}

struct PurchaseMessage: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let body: String
}

@MainActor
final class PurchaseManager: ObservableObject {
    static let trialDuration: TimeInterval = 7 * 24 * 60 * 60

    @Published private(set) var isReady = false
    @Published private(set) var isRefreshing = false
    @Published private(set) var isPurchasing = false
    @Published private(set) var hasLifetime = false
    @Published private(set) var annualState: AnnualSubscriptionState = .none
    @Published private(set) var isTrialStarted = false
    @Published private(set) var trialEndsAt: Date?
    @Published private(set) var isTrialActive = false
    @Published private(set) var products: [Product] = []
    @Published private(set) var productLoadingFailed = false
    @Published var message: PurchaseMessage?

    private let isPreview: Bool
    private var updatesTask: Task<Void, Never>?
    private var trialExpirationTask: Task<Void, Never>?

    init(previewState: PreviewAccessState? = nil) {
        isPreview = previewState != nil

        guard let previewState else { return }
        isReady = true
        switch previewState {
        case .trialNotStarted:
            isTrialStarted = false
        case .trial:
            isTrialStarted = true
            isTrialActive = true
            trialEndsAt = Date().addingTimeInterval(Self.trialDuration)
        case .locked:
            isTrialStarted = true
            isTrialActive = false
            trialEndsAt = Date().addingTimeInterval(-1)
        case .annualRenewing:
            annualState = .active(
                willAutoRenew: true,
                expirationDate: Calendar.current.date(byAdding: .year, value: 1, to: Date()),
                isInGracePeriod: false
            )
        case .annualCancelled:
            annualState = .active(
                willAutoRenew: false,
                expirationDate: Calendar.current.date(byAdding: .month, value: 5, to: Date()),
                isInGracePeriod: false
            )
        case .lifetime:
            hasLifetime = true
        }
    }

    deinit {
        updatesTask?.cancel()
        trialExpirationTask?.cancel()
    }

    var hasAccess: Bool {
        hasLifetime || annualState.grantsAccess || isTrialActive
    }

    var annualProduct: Product? {
        products.first { $0.id == PurchaseProductID.annual }
    }

    var lifetimeProduct: Product? {
        products.first { $0.id == PurchaseProductID.lifetime }
    }

    var canPurchaseAnnual: Bool {
        !hasLifetime && !annualState.grantsAccess && !isPurchasing && !isRefreshing
    }

    var canPurchaseLifetimeDirectly: Bool {
        guard !hasLifetime, !isPurchasing, !isRefreshing else { return false }
        guard annualState.grantsAccess else { return true }
        return annualState.willAutoRenew == false
    }

    var needsGuidedLifetimeSwitch: Bool {
        !hasLifetime && annualState.grantsAccess && annualState.willAutoRenew != false
    }

    var hasLifetimeAndRenewingAnnual: Bool {
        hasLifetime && annualState.grantsAccess && annualState.willAutoRenew != false
    }

    func prepare() async {
        guard !isPreview, !isReady else { return }
        startTransactionListener()
        await refresh()
    }

    func refresh() async {
        guard !isPreview, !isRefreshing else { return }
        isRefreshing = true
        defer {
            isRefreshing = false
            isReady = true
        }

        refreshTrial()

        if products.isEmpty {
            do {
                products = try await Product.products(for: PurchaseProductID.all)
                    .sorted { $0.price < $1.price }
                productLoadingFailed = products.isEmpty
            } catch {
                productLoadingFailed = true
            }
        } else {
            productLoadingFailed = false
        }

        var lifetimeEntitlement = false
        var annualEntitlementExpiration: Date?

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            switch transaction.productID {
            case PurchaseProductID.lifetime:
                lifetimeEntitlement = true
            case PurchaseProductID.annual:
                annualEntitlementExpiration = transaction.expirationDate
            default:
                break
            }
        }

        hasLifetime = lifetimeEntitlement
        annualState = await loadAnnualState(
            fallbackEntitlementExpiration: annualEntitlementExpiration
        )
    }

    func purchaseAnnual() async {
        await ensureFreshState()

        guard !hasLifetime else {
            message = PurchaseMessage(
                title: PurchaseCopy.string("purchase.alreadyLifetime.title"),
                body: PurchaseCopy.string("purchase.alreadyLifetime.body")
            )
            return
        }
        guard !annualState.grantsAccess else {
            message = PurchaseMessage(
                title: PurchaseCopy.string("purchase.alreadyAnnual.title"),
                body: PurchaseCopy.string("purchase.alreadyAnnual.body")
            )
            return
        }
        guard let annualProduct else {
            showProductUnavailableMessage()
            return
        }

        await purchase(annualProduct)
    }

    func startTrial() {
        guard !isTrialStarted, !hasLifetime, !annualState.grantsAccess else { return }

        if isPreview {
            isTrialStarted = true
            isTrialActive = true
            trialEndsAt = Date().addingTimeInterval(Self.trialDuration)
            scheduleTrialExpirationIfNeeded()
            return
        }

        applyTrialDates(TrialDateStore.start())
    }

    func purchaseLifetime() async {
        await ensureFreshState()

        guard !hasLifetime else {
            message = PurchaseMessage(
                title: PurchaseCopy.string("purchase.alreadyLifetime.title"),
                body: PurchaseCopy.string("purchase.alreadyLifetime.body")
            )
            return
        }

        if annualState.grantsAccess, annualState.willAutoRenew != false {
            message = PurchaseMessage(
                title: PurchaseCopy.string("switch.required.title"),
                body: PurchaseCopy.string("switch.required.body")
            )
            return
        }

        guard let lifetimeProduct else {
            showProductUnavailableMessage()
            return
        }

        await purchase(lifetimeProduct)
    }

    func restorePurchases() async {
        guard !isPreview else { return }
        do {
            try await AppStore.sync()
            await ensureFreshState()
            message = PurchaseMessage(
                title: PurchaseCopy.string("restore.complete.title"),
                body: hasLifetime || annualState.grantsAccess
                    ? PurchaseCopy.string("restore.complete.found")
                    : PurchaseCopy.string("restore.complete.none")
            )
        } catch {
            message = PurchaseMessage(
                title: PurchaseCopy.string("purchase.error.title"),
                body: PurchaseCopy.string("restore.error.body")
            )
        }
    }

    func dismissMessage() {
        message = nil
    }

    private func startTransactionListener() {
        guard updatesTask == nil else { return }
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard !Task.isCancelled else { break }
                guard case .verified(let transaction) = result else { continue }
                await transaction.finish()
                await self?.refresh()
            }
        }
    }

    private func purchase(_ product: Product) async {
        guard !isPurchasing else { return }
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    message = PurchaseMessage(
                        title: PurchaseCopy.string("purchase.error.title"),
                        body: PurchaseCopy.string("purchase.error.verification")
                    )
                    return
                }
                await transaction.finish()
                await refresh()
            case .pending:
                message = PurchaseMessage(
                    title: PurchaseCopy.string("purchase.pending.title"),
                    body: PurchaseCopy.string("purchase.pending.body")
                )
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            message = PurchaseMessage(
                title: PurchaseCopy.string("purchase.error.title"),
                body: error.localizedDescription
            )
        }
    }

    private func ensureFreshState() async {
        while isRefreshing {
            try? await Task.sleep(for: .milliseconds(25))
        }
        await refresh()
    }

    private func loadAnnualState(
        fallbackEntitlementExpiration: Date?
    ) async -> AnnualSubscriptionState {
        guard let subscription = annualProduct?.subscription else {
            if let fallbackEntitlementExpiration {
                return .active(
                    willAutoRenew: nil,
                    expirationDate: fallbackEntitlementExpiration,
                    isInGracePeriod: false
                )
            }
            return .none
        }

        guard let statuses = try? await subscription.status else {
            if let fallbackEntitlementExpiration {
                return .active(
                    willAutoRenew: nil,
                    expirationDate: fallbackEntitlementExpiration,
                    isInGracePeriod: false
                )
            }
            return .none
        }

        for status in statuses {
            guard case .verified(let transaction) = status.transaction,
                  transaction.productID == PurchaseProductID.annual,
                  case .verified(let renewalInfo) = status.renewalInfo else {
                continue
            }

            switch status.state {
            case .subscribed:
                return .active(
                    willAutoRenew: renewalInfo.willAutoRenew,
                    expirationDate: transaction.expirationDate ?? renewalInfo.renewalDate,
                    isInGracePeriod: false
                )
            case .inGracePeriod:
                return .active(
                    willAutoRenew: renewalInfo.willAutoRenew,
                    expirationDate: renewalInfo.gracePeriodExpirationDate
                        ?? transaction.expirationDate
                        ?? renewalInfo.renewalDate,
                    isInGracePeriod: true
                )
            case .expired, .inBillingRetryPeriod, .revoked:
                continue
            default:
                continue
            }
        }

        if let fallbackEntitlementExpiration {
            return .active(
                willAutoRenew: nil,
                expirationDate: fallbackEntitlementExpiration,
                isInGracePeriod: false
            )
        }
        return statuses.isEmpty ? .none : .inactive
    }

    private func refreshTrial() {
        guard let dates = TrialDateStore.load() else {
            isTrialStarted = false
            isTrialActive = false
            trialEndsAt = nil
            trialExpirationTask?.cancel()
            return
        }

        applyTrialDates(dates)
    }

    private func applyTrialDates(_ dates: TrialDateStore.Dates) {
        isTrialStarted = true
        trialEndsAt = dates.start.addingTimeInterval(Self.trialDuration)
        isTrialActive = dates.effectiveNow < trialEndsAt!
        scheduleTrialExpirationIfNeeded()
    }

    private func scheduleTrialExpirationIfNeeded() {
        trialExpirationTask?.cancel()
        guard isTrialActive, let trialEndsAt else { return }

        let delay = max(0, trialEndsAt.timeIntervalSinceNow)
        trialExpirationTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            await self?.refresh()
        }
    }

    private func showProductUnavailableMessage() {
        message = PurchaseMessage(
            title: PurchaseCopy.string("purchase.error.title"),
            body: PurchaseCopy.string("purchase.error.products")
        )
    }
}

extension PurchaseManager {
    enum PreviewAccessState {
        case trialNotStarted
        case trial
        case locked
        case annualRenewing
        case annualCancelled
        case lifetime
    }
}

private enum TrialDateStore {
    private static let service = "com.bentosoftware.CycleContext.trial"
    private static let startAccount = "trial-start-v1"
    private static let lastSeenAccount = "trial-last-seen-v1"
    private static var didApplyDebugReset = false

    struct Dates {
        let start: Date
        let effectiveNow: Date
    }

    static func load(now: Date = Date()) -> Dates? {
        #if DEBUG
        if !didApplyDebugReset,
           ProcessInfo.processInfo.arguments.contains("--reset-cyclecontext-trial") {
            didApplyDebugReset = true
            delete(account: startAccount)
            delete(account: lastSeenAccount)
            UserDefaults.standard.removeObject(forKey: startAccount)
            UserDefaults.standard.removeObject(forKey: lastSeenAccount)
        }
        if ProcessInfo.processInfo.arguments.contains("--force-cyclecontext-paywall") {
            return Dates(
                start: now.addingTimeInterval(-PurchaseManager.trialDuration - 60),
                effectiveNow: now
            )
        }
        #endif

        guard let start = readDate(account: startAccount)
            ?? fallbackDate(account: startAccount) else {
            return nil
        }

        let previousLastSeen = readDate(account: lastSeenAccount)
            ?? fallbackDate(account: lastSeenAccount)
            ?? now
        let effectiveNow = max(now, previousLastSeen)
        persist(effectiveNow, account: lastSeenAccount)

        return Dates(start: start, effectiveNow: effectiveNow)
    }

    static func start(now: Date = Date()) -> Dates {
        persist(now, account: startAccount)
        persist(now, account: lastSeenAccount)
        return Dates(start: now, effectiveNow: now)
    }

    private static func persist(_ date: Date, account: String) {
        if !writeDate(date, account: account) {
            UserDefaults.standard.set(date.timeIntervalSince1970, forKey: account)
        }
    }

    private static func fallbackDate(account: String) -> Date? {
        let value = UserDefaults.standard.double(forKey: account)
        return value > 0 ? Date(timeIntervalSince1970: value) : nil
    }

    private static func readDate(account: String) -> Date? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8),
              let interval = TimeInterval(value) else {
            return nil
        }
        return Date(timeIntervalSince1970: interval)
    }

    @discardableResult
    private static func writeDate(_ date: Date, account: String) -> Bool {
        let data = Data(String(date.timeIntervalSince1970).utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let attributes: [String: Any] = [kSecValueData as String: data]

        let updateStatus = SecItemUpdate(
            query as CFDictionary,
            attributes as CFDictionary
        )
        if updateStatus == errSecSuccess { return true }

        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        return SecItemAdd(addQuery as CFDictionary, nil) == errSecSuccess
    }

    private static func delete(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

enum PurchaseCopy {
    static func string(_ key: String.LocalizationValue) -> String {
        String(localized: key, table: "Paywall")
    }
}
