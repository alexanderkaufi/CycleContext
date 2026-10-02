import StoreKit
import SwiftUI

struct RootTabView: View {
    @Environment(\.requestReview) private var requestReview
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store = CyclePreviewStore()
    private let reviewRequestPolicy = ReviewRequestPolicy()

    var body: some View {
        TabView(selection: $store.selectedTab) {
            DashboardView()
                .tabItem { Label(AppTab.overview.localizedTitle, systemImage: AppTab.overview.icon) }
                .tag(AppTab.overview)

            CycleOverviewView()
                .tabItem { Label(AppTab.cycleOverview.localizedTitle, systemImage: AppTab.cycleOverview.icon) }
                .tag(AppTab.cycleOverview)

            CycleCalendarView()
                .tabItem { Label(AppTab.calendar.localizedTitle, systemImage: AppTab.calendar.icon) }
                .tag(AppTab.calendar)

            EntriesView()
                .tabItem { Label(AppTab.entries.localizedTitle, systemImage: AppTab.entries.icon) }
                .tag(AppTab.entries)

            SettingsView()
                .tabItem { Label(AppTab.settings.localizedTitle, systemImage: AppTab.settings.icon) }
                .tag(AppTab.settings)
        }
        .environmentObject(store)
        .tint(.blue)
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }

            do {
                try await Task.sleep(for: .seconds(10))
            } catch {
                return
            }

            let requestDate = Date()
            reviewRequestPolicy.registerActiveDay(on: requestDate)

            let hasPersonalizedProfile = store.profiles.contains { !$0.isTemplateProfile }
            guard reviewRequestPolicy.shouldRequestReview(
                on: requestDate,
                hasPersonalizedProfile: hasPersonalizedProfile
            ) else {
                return
            }

            reviewRequestPolicy.recordRequestAttempt(on: requestDate)
            requestReview()
        }
    }
}

struct RootTabView_Previews: PreviewProvider {
    static var previews: some View {
        RootTabView()
            .previewDisplayName("Root Tabs")
    }
}
