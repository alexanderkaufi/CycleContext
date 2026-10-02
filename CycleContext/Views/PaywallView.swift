import StoreKit
import SwiftUI

struct TrialIntroView: View {
    @EnvironmentObject private var purchases: PurchaseManager
    @State private var isShowingPrivacy = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(.blue.gradient)
                                .frame(width: 82, height: 82)
                            Image(systemName: "sparkles")
                                .font(.system(size: 38, weight: .medium))
                                .foregroundStyle(.white)
                        }
                        .accessibilityHidden(true)

                        VStack(spacing: 8) {
                            Text(PurchaseCopy.string("trialIntro.title"))
                                .font(.largeTitle.bold())
                                .multilineTextAlignment(.center)

                            Text(PurchaseCopy.string("trialIntro.subtitle"))
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            PaywallBenefitRow(
                                icon: "checkmark.circle.fill",
                                text: PurchaseCopy.string("trialIntro.benefit.fullAccess")
                            )
                            PaywallBenefitRow(
                                icon: "creditcard.fill",
                                text: PurchaseCopy.string("trialIntro.benefit.noPayment")
                            )
                            PaywallBenefitRow(
                                icon: "arrow.triangle.2.circlepath",
                                text: PurchaseCopy.string("trialIntro.benefit.noRenewal")
                            )
                        }
                        .padding(16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }

                    Button(PurchaseCopy.string("trialIntro.start.button")) {
                        purchases.startTrial()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)

                    Text(PurchaseCopy.string("trialIntro.start.hint"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    VStack(spacing: 12) {
                        Text(PurchaseCopy.string("trialIntro.purchaseNow.title"))
                            .font(.headline)
                            .multilineTextAlignment(.center)

                        PurchaseOptionsView(context: .paywall)
                    }

                    VStack(spacing: 12) {
                        Button(PurchaseCopy.string("restore.button")) {
                            Task { await purchases.restorePurchases() }
                        }
                        .disabled(purchases.isRefreshing || purchases.isPurchasing)

                        HStack(spacing: 16) {
                            Button(PurchaseCopy.string("legal.privacy")) {
                                isShowingPrivacy = true
                            }

                            Link(
                                PurchaseCopy.string("legal.terms"),
                                destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
                            )
                        }
                        .font(.footnote)

                        Text(PurchaseCopy.string("paywall.subscriptionDisclosure"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .buttonStyle(.plain)
                    .tint(.blue)
                }
                .frame(maxWidth: 620)
                .padding(.horizontal, 20)
                .padding(.vertical, 28)
                .frame(maxWidth: .infinity)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $isShowingPrivacy) {
            PrivacyConsentView()
        }
    }
}

struct PaywallView: View {
    @EnvironmentObject private var purchases: PurchaseManager
    @State private var isShowingPrivacy = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    paywallHeader
                    PurchaseOptionsView(context: .paywall)
                    legalFooter
                }
                .frame(maxWidth: 620)
                .padding(.horizontal, 20)
                .padding(.vertical, 28)
                .frame(maxWidth: .infinity)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $isShowingPrivacy) {
            PrivacyConsentView()
        }
    }

    private var paywallHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.blue.gradient)
                    .frame(width: 82, height: 82)
                Image(systemName: "circle.hexagongrid.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(PurchaseCopy.string("paywall.title"))
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)

                Text(PurchaseCopy.string("paywall.subtitle"))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 12) {
                PaywallBenefitRow(
                    icon: "heart.text.clipboard.fill",
                    text: PurchaseCopy.string("paywall.benefit.context")
                )
                PaywallBenefitRow(
                    icon: "calendar.badge.clock",
                    text: PurchaseCopy.string("paywall.benefit.cycle")
                )
                PaywallBenefitRow(
                    icon: "lock.shield.fill",
                    text: PurchaseCopy.string("paywall.benefit.privacy")
                )
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var legalFooter: some View {
        VStack(spacing: 12) {
            Button(PurchaseCopy.string("restore.button")) {
                Task { await purchases.restorePurchases() }
            }
            .disabled(purchases.isRefreshing || purchases.isPurchasing)

            HStack(spacing: 16) {
                Button(PurchaseCopy.string("legal.privacy")) {
                    isShowingPrivacy = true
                }

                Link(
                    PurchaseCopy.string("legal.terms"),
                    destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
                )
            }
            .font(.footnote)

            Text(PurchaseCopy.string("paywall.subscriptionDisclosure"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .buttonStyle(.plain)
        .tint(.blue)
    }
}

struct PurchaseManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var purchases: PurchaseManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if !purchases.hasLifetime && !purchases.annualState.grantsAccess {
                        AccessStatusCard()
                    }
                    PurchaseOptionsView(context: .management)

                    Button(PurchaseCopy.string("restore.button")) {
                        Task { await purchases.restorePurchases() }
                    }
                    .disabled(purchases.isRefreshing || purchases.isPurchasing)
                    .padding(.top, 4)
                }
                .frame(maxWidth: 620)
                .padding(20)
                .frame(maxWidth: .infinity)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(PurchaseCopy.string("management.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(PurchaseCopy.string("common.done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct PurchaseOptionsView: View {
    enum Context {
        case paywall
        case management
    }

    @EnvironmentObject private var purchases: PurchaseManager
    @State private var isShowingLifetimeSwitch = false
    @State private var isManagingSubscriptions = false

    let context: Context

    var body: some View {
        VStack(spacing: 14) {
            if purchases.hasLifetime {
                lifetimeOwnedContent
            } else if purchases.annualState.grantsAccess {
                annualSubscriberContent
            } else {
                standardOffers
            }
        }
        .manageSubscriptionsSheet(isPresented: $isManagingSubscriptions)
        .onChange(of: isManagingSubscriptions) { _, isPresented in
            guard !isPresented else { return }
            Task { await purchases.refresh() }
        }
        .sheet(isPresented: $isShowingLifetimeSwitch) {
            LifetimeSwitchView()
        }
    }

    private var standardOffers: some View {
        VStack(spacing: 14) {
            PurchaseOfferCard(
                icon: "calendar",
                tint: .blue,
                title: PurchaseCopy.string("offer.annual.title"),
                price: annualPrice,
                detail: PurchaseCopy.string("offer.annual.detail"),
                badge: PurchaseCopy.string("offer.annual.badge"),
                buttonTitle: annualButtonTitle,
                isBusy: purchases.isPurchasing,
                isDisabled: !purchases.canPurchaseAnnual || purchases.annualProduct == nil
            ) {
                Task { await purchases.purchaseAnnual() }
            }

            PurchaseOfferCard(
                icon: "infinity",
                tint: .purple,
                title: PurchaseCopy.string("offer.lifetime.title"),
                price: lifetimePrice,
                detail: PurchaseCopy.string("offer.lifetime.detail"),
                badge: PurchaseCopy.string("offer.lifetime.badge"),
                buttonTitle: lifetimeButtonTitle,
                isBusy: purchases.isPurchasing,
                isDisabled: !purchases.canPurchaseLifetimeDirectly || purchases.lifetimeProduct == nil
            ) {
                Task { await purchases.purchaseLifetime() }
            }

            if purchases.products.isEmpty {
                ProductLoadingHint()
            }
        }
    }

    private var annualSubscriberContent: some View {
        VStack(spacing: 14) {
            SubscriptionStatusCard()

            if purchases.annualState.willAutoRenew == false {
                PurchaseOfferCard(
                    icon: "infinity",
                    tint: .purple,
                    title: PurchaseCopy.string("offer.lifetime.title"),
                    price: lifetimePrice,
                    detail: cancelledSubscriptionDetail,
                    badge: PurchaseCopy.string("switch.ready.badge"),
                    buttonTitle: lifetimeButtonTitle,
                    isBusy: purchases.isPurchasing,
                    isDisabled: !purchases.canPurchaseLifetimeDirectly || purchases.lifetimeProduct == nil
                ) {
                    Task { await purchases.purchaseLifetime() }
                }
            } else {
                PurchaseOfferCard(
                    icon: "arrow.triangle.2.circlepath",
                    tint: .purple,
                    title: PurchaseCopy.string("switch.card.title"),
                    price: lifetimePrice,
                    detail: PurchaseCopy.string("switch.card.detail"),
                    badge: nil,
                    buttonTitle: PurchaseCopy.string("switch.card.button"),
                    isBusy: purchases.isRefreshing,
                    isDisabled: false
                ) {
                    isShowingLifetimeSwitch = true
                }
            }
        }
    }

    private var lifetimeOwnedContent: some View {
        VStack(spacing: 14) {
            PurchaseStateCard(
                icon: "checkmark.seal.fill",
                tint: .green,
                title: PurchaseCopy.string("status.lifetime.title"),
                detail: PurchaseCopy.string("status.lifetime.detail")
            )

            if purchases.hasLifetimeAndRenewingAnnual {
                PurchaseStateCard(
                    icon: "exclamationmark.triangle.fill",
                    tint: .orange,
                    title: PurchaseCopy.string("status.doublePayment.title"),
                    detail: PurchaseCopy.string("status.doublePayment.detail")
                )

                Button(PurchaseCopy.string("subscription.manage.button")) {
                    isManagingSubscriptions = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var annualPrice: String {
        purchases.annualProduct?.displayPrice ?? PurchaseCopy.string("offer.price.loading")
    }

    private var lifetimePrice: String {
        purchases.lifetimeProduct?.displayPrice ?? PurchaseCopy.string("offer.price.loading")
    }

    private var annualButtonTitle: String {
        guard let product = purchases.annualProduct else {
            return PurchaseCopy.string("offer.loading.button")
        }
        return String(
            format: PurchaseCopy.string("offer.annual.buttonFormat"),
            locale: Locale.current,
            product.displayPrice
        )
    }

    private var lifetimeButtonTitle: String {
        guard let product = purchases.lifetimeProduct else {
            return PurchaseCopy.string("offer.loading.button")
        }
        return String(
            format: PurchaseCopy.string("offer.lifetime.buttonFormat"),
            locale: Locale.current,
            product.displayPrice
        )
    }

    private var cancelledSubscriptionDetail: String {
        guard let date = purchases.annualState.expirationDate else {
            return PurchaseCopy.string("switch.ready.detail.noDate")
        }
        return String(
            format: PurchaseCopy.string("switch.ready.detailFormat"),
            locale: Locale.current,
            date.formatted(date: .long, time: .omitted)
        )
    }
}

private struct AccessStatusCard: View {
    @EnvironmentObject private var purchases: PurchaseManager

    var body: some View {
        if purchases.hasLifetime {
            PurchaseStateCard(
                icon: "checkmark.seal.fill",
                tint: .green,
                title: PurchaseCopy.string("status.lifetime.title"),
                detail: PurchaseCopy.string("status.lifetime.detail")
            )
        } else if purchases.annualState.grantsAccess {
            SubscriptionStatusCard()
        } else if purchases.isTrialActive {
            PurchaseStateCard(
                icon: "clock.fill",
                tint: .blue,
                title: PurchaseCopy.string("status.trial.title"),
                detail: trialDetail
            )
        } else {
            PurchaseStateCard(
                icon: "lock.fill",
                tint: .secondary,
                title: PurchaseCopy.string("status.locked.title"),
                detail: PurchaseCopy.string("status.locked.detail")
            )
        }
    }

    private var trialDetail: String {
        guard let date = purchases.trialEndsAt else {
            return PurchaseCopy.string("status.trial.detail.noDate")
        }
        return String(
            format: PurchaseCopy.string("status.trial.detailFormat"),
            locale: Locale.current,
            date.formatted(date: .long, time: .shortened)
        )
    }
}

private struct SubscriptionStatusCard: View {
    @EnvironmentObject private var purchases: PurchaseManager

    var body: some View {
        PurchaseStateCard(
            icon: purchases.annualState.willAutoRenew == false
                ? "calendar.badge.checkmark"
                : "arrow.triangle.2.circlepath.circle.fill",
            tint: purchases.annualState.willAutoRenew == false ? .green : .blue,
            title: title,
            detail: detail
        )
    }

    private var title: String {
        if purchases.annualState.isInGracePeriod {
            return PurchaseCopy.string("status.annual.grace.title")
        }
        if purchases.annualState.willAutoRenew == false {
            return PurchaseCopy.string("status.annual.cancelled.title")
        }
        return PurchaseCopy.string("status.annual.active.title")
    }

    private var detail: String {
        guard let date = purchases.annualState.expirationDate else {
            return purchases.annualState.willAutoRenew == false
                ? PurchaseCopy.string("status.annual.cancelled.noDate")
                : PurchaseCopy.string("status.annual.active.noDate")
        }

        let key: String.LocalizationValue = purchases.annualState.willAutoRenew == false
            ? "status.annual.cancelled.detailFormat"
            : "status.annual.active.detailFormat"
        return String(
            format: PurchaseCopy.string(key),
            locale: Locale.current,
            date.formatted(date: .long, time: .omitted)
        )
    }
}

private struct LifetimeSwitchView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var purchases: PurchaseManager
    @State private var isManagingSubscriptions = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: purchases.annualState.willAutoRenew == false
                        ? "checkmark.circle.fill"
                        : "arrow.triangle.2.circlepath")
                        .font(.system(size: 48))
                        .foregroundStyle(purchases.annualState.willAutoRenew == false ? .green : .purple)
                        .accessibilityHidden(true)

                    Text(title)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)

                    Text(detail)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    if purchases.annualState.willAutoRenew == false {
                        Button(lifetimePurchaseButtonTitle) {
                            Task { await purchases.purchaseLifetime() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                        .controlSize(.large)
                        .disabled(purchases.isPurchasing || purchases.lifetimeProduct == nil)
                    } else {
                        VStack(spacing: 12) {
                            Button(PurchaseCopy.string("switch.manage.button")) {
                                isManagingSubscriptions = true
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.purple)
                            .controlSize(.large)

                            Button(PurchaseCopy.string("switch.check.button")) {
                                Task { await purchases.refresh() }
                            }
                            .disabled(purchases.isRefreshing)
                        }
                    }

                    Text(PurchaseCopy.string("switch.noRefund.hint"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: 520)
                .padding(24)
                .frame(maxWidth: .infinity)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(PurchaseCopy.string("switch.navigationTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(PurchaseCopy.string("common.close")) {
                        dismiss()
                    }
                }
            }
        }
        .manageSubscriptionsSheet(isPresented: $isManagingSubscriptions)
        .onChange(of: isManagingSubscriptions) { _, isPresented in
            guard !isPresented else { return }
            Task { await purchases.refresh() }
        }
        .onChange(of: purchases.hasLifetime) { _, ownsLifetime in
            if ownsLifetime { dismiss() }
        }
    }

    private var title: String {
        purchases.annualState.willAutoRenew == false
            ? PurchaseCopy.string("switch.ready.title")
            : PurchaseCopy.string("switch.title")
    }

    private var detail: String {
        if purchases.annualState.willAutoRenew == false {
            guard let date = purchases.annualState.expirationDate else {
                return PurchaseCopy.string("switch.ready.body.noDate")
            }
            return String(
                format: PurchaseCopy.string("switch.ready.bodyFormat"),
                locale: Locale.current,
                date.formatted(date: .long, time: .omitted)
            )
        }
        return PurchaseCopy.string("switch.body")
    }

    private var lifetimePurchaseButtonTitle: String {
        guard let product = purchases.lifetimeProduct else {
            return PurchaseCopy.string("offer.loading.button")
        }
        return String(
            format: PurchaseCopy.string("offer.lifetime.buttonFormat"),
            locale: Locale.current,
            product.displayPrice
        )
    }
}

private struct PaywallBenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        Label {
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(.blue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PurchaseOfferCard: View {
    let icon: String
    let tint: Color
    let title: String
    let price: String
    let detail: String
    let badge: String?
    let buttonTitle: String
    let isBusy: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 42, height: 42)
                    .background(tint.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(title)
                            .font(.headline)
                        Spacer()
                        Text(price)
                            .font(.headline)
                    }
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let badge {
                Text(badge)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(tint.opacity(0.12))
                    .clipShape(Capsule())
            }

            Button(action: action) {
                HStack {
                    if isBusy {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(buttonTitle)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(tint)
            .controlSize(.large)
            .disabled(isDisabled || isBusy)
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct PurchaseStateCard: View {
    let icon: String
    let tint: Color
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(tint)
                .frame(width: 42, height: 42)
                .background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct ProductLoadingHint: View {
    @EnvironmentObject private var purchases: PurchaseManager

    var body: some View {
        VStack(spacing: 10) {
            if purchases.isRefreshing || !purchases.productLoadingFailed {
                ProgressView()
                Text(PurchaseCopy.string("offer.loading.hint"))
            } else {
                Label(
                    PurchaseCopy.string("offer.loading.error"),
                    systemImage: "exclamationmark.triangle.fill"
                )

                Button(PurchaseCopy.string("offer.loading.retry")) {
                    Task { await purchases.refresh() }
                }
                .buttonStyle(.bordered)
            }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
}

struct PaywallView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TrialIntroView()
                .environmentObject(PurchaseManager(previewState: .trialNotStarted))
                .previewDisplayName("Trial Intro")

            PaywallView()
                .environmentObject(PurchaseManager(previewState: .locked))
                .previewDisplayName("Hard Paywall")

            PurchaseManagementView()
                .environmentObject(PurchaseManager(previewState: .annualRenewing))
                .previewDisplayName("Annual Switch")
        }
    }
}
