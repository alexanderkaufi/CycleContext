import SwiftUI

struct ScreenContainer<Content: View>: View {
    let title: LocalizedStringResource
    let titleAccessory: AnyView?
    let actionIcon: String?
    let actionTitle: LocalizedStringResource?
    let action: (() -> Void)?
    let embedsInNavigationStack: Bool
    @ViewBuilder var content: Content

    init(
        title: LocalizedStringResource,
        titleAccessory: AnyView? = nil,
        actionIcon: String? = nil,
        actionTitle: LocalizedStringResource? = nil,
        action: (() -> Void)? = nil,
        embedsInNavigationStack: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.titleAccessory = titleAccessory
        self.actionIcon = actionIcon
        self.actionTitle = actionTitle
        self.action = action
        self.embedsInNavigationStack = embedsInNavigationStack
        self.content = content()
    }

    var body: some View {
        if embedsInNavigationStack {
            NavigationStack {
                screenContent
            }
        } else {
            screenContent
        }
    }

    private var screenContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                content
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(titleAccessory == nil ? String(localized: title) : "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let titleAccessory {
                ToolbarItem(placement: .topBarLeading) {
                    titleAccessory
                }
                ToolbarItem(placement: .principal) {
                    Text(String(localized: title))
                        .font(.headline)
                }
            }

            if let actionTitle {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: actionTitle), action: action ?? {})
                }
            } else if let actionIcon {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: action ?? {}) {
                        Image(systemName: actionIcon)
                    }
                }
            }
        }
    }
}

struct IOSCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct SectionHeader: View {
    private var title: String

    init(title: LocalizedStringResource) {
        self.title = String(localized: title)
    }

    init(verbatimTitle: String) {
        title = verbatimTitle
    }

    var body: some View {
        Text(title.uppercased(with: Locale.current))
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
    }
}

struct MetricPill: View {
    var title: LocalizedStringResource
    var value: String
    var tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(String(localized: title))
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .foregroundStyle(tint)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct AdviceRow: View {
    var card: AdviceCard

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: card.icon)
                .font(.title3)
                .foregroundStyle(card.tint)
                .frame(width: 32, height: 32)
                .background(card.tint.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(card.title)
                    .font(.headline)
                Text(card.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct Components_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "preview.section")
                IOSCard {
                    AdviceRow(card: AdviceCard(
                        title: String(localized: "preview.advice.title"),
                        subtitle: String(localized: "preview.advice.body"),
                        icon: "hands.sparkles.fill",
                        tint: .blue
                    ))
                }
                HStack(spacing: 12) {
                    MetricPill(title: "entry.energy", value: String(localized: "preview.energy.value"), tint: .orange)
                    MetricPill(title: "cycle.phase.label", value: String(localized: "preview.phase.value"), tint: .blue)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .previewDisplayName("Komponenten")
    }
}
