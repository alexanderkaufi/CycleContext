import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: CyclePreviewStore
    @EnvironmentObject private var purchases: PurchaseManager
    @State private var isManagingProfiles = false
    @State private var isShowingPrivacyInformation = false
    @State private var isShowingPurchases = false

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
    }

    var body: some View {
        ScreenContainer(title: "screen.settings.title") {
            SectionHeader(title: "settings.section.profile")
            Button {
                isManagingProfiles = true
            } label: {
                IOSCard {
                    SettingsRow(
                        icon: "person.2.fill",
                        tint: .blue,
                        title: "settings.profiles.manage",
                        value: "\(store.profiles.count)"
                    )
                }
            }
            .buttonStyle(.plain)
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            SectionHeader(title: "settings.section.privacy")
            Button {
                isShowingPrivacyInformation = true
            } label: {
                IOSCard {
                    SettingsRow(
                        icon: "hand.raised.fill",
                        tint: .purple,
                        title: "settings.privacy.details",
                        value: nil
                    )
                }
            }
            .buttonStyle(.plain)
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text("settings.privacy.consentHint")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            SectionHeader(verbatimTitle: PurchaseCopy.string("settings.access.section"))
            Button {
                isShowingPurchases = true
            } label: {
                IOSCard {
                    SettingsRow(
                        icon: "checkmark.seal.fill",
                        tint: .green,
                        titleText: PurchaseCopy.string("settings.access.manage"),
                        value: accessStatus
                    )
                }
            }
            .buttonStyle(.plain)
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            SectionHeader(title: "settings.section.information")
            NavigationLink {
                CycleEducationView()
            } label: {
                IOSCard {
                    SettingsRow(
                        icon: "book.pages.fill",
                        tint: .indigo,
                        title: "settings.methodologySources",
                        value: nil
                    )
                }
            }
            .buttonStyle(.plain)
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack(spacing: 8) {
                Text("settings.version")
                Text(appVersion)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 12)
            .background(Color(.systemGroupedBackground))
            .accessibilityElement(children: .combine)
        }
        .sheet(isPresented: $isManagingProfiles) {
            ProfileManagementView()
        }
        .sheet(isPresented: $isShowingPrivacyInformation) {
            PrivacyConsentView()
        }
        .sheet(isPresented: $isShowingPurchases) {
            PurchaseManagementView()
                .environmentObject(purchases)
        }
    }

    private var accessStatus: String {
        if purchases.hasLifetime {
            return PurchaseCopy.string("settings.access.lifetime")
        }
        if purchases.annualState.grantsAccess {
            return purchases.annualState.willAutoRenew == false
                ? PurchaseCopy.string("settings.access.annualCancelled")
                : PurchaseCopy.string("settings.access.annual")
        }
        if purchases.isTrialActive {
            return PurchaseCopy.string("settings.access.trial")
        }
        return PurchaseCopy.string("settings.access.locked")
    }
}

private struct SettingsRow: View {
    var icon: String
    var tint: Color
    var title: String
    var value: String?
    var showsChevron = true

    init(
        icon: String,
        tint: Color,
        title: LocalizedStringResource,
        value: String?,
        showsChevron: Bool = true
    ) {
        self.icon = icon
        self.tint = tint
        self.title = String(localized: title)
        self.value = value
        self.showsChevron = showsChevron
    }

    init(
        icon: String,
        tint: Color,
        titleText: String,
        value: String?,
        showsChevron: Bool = true
    ) {
        self.icon = icon
        self.tint = tint
        title = titleText
        self.value = value
        self.showsChevron = showsChevron
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(tint)
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

            Text(title)
                .font(.body)

            Spacer()

            if let value {
                Text(value)
                    .foregroundStyle(.secondary)
            }

            if showsChevron {
                Image(systemName: "chevron.forward")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 3)
    }
}

struct PrivacyConsentView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("privacy.introduction")
                        .foregroundStyle(.secondary)
                }

                PrivacyInformationSection(
                    icon: "iphone",
                    title: "privacy.storage.title",
                    text: "privacy.storage.body"
                )

                PrivacyInformationSection(
                    icon: "person.2.fill",
                    title: "privacy.consent.title",
                    text: "privacy.consent.body"
                )

                PrivacyInformationSection(
                    icon: "trash.fill",
                    title: "privacy.deletion.title",
                    text: "privacy.deletion.body"
                )

                PrivacyInformationSection(
                    icon: "cross.case.fill",
                    title: "privacy.medical.title",
                    text: "privacy.medical.body"
                )
            }
            .navigationTitle(String(localized: "settings.privacy.details"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct PrivacyInformationSection: View {
    var icon: String
    var title: LocalizedStringResource
    var text: LocalizedStringResource

    var body: some View {
        Section {
            Text(String(localized: text))
        } header: {
            Label(String(localized: title), systemImage: icon)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .cyclePreviewEnvironment()
            .previewDisplayName("Einstellungen")
    }
}
