import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var purchases = PurchaseManager()

    var body: some View {
        Group {
            if !purchases.isReady {
                PurchaseLoadingView()
            } else if purchases.hasAccess {
                RootTabView()
            } else if !purchases.isTrialStarted {
                TrialIntroView()
            } else {
                PaywallView()
            }
        }
        .environmentObject(purchases)
        .task {
            await purchases.prepare()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            Task { await purchases.refresh() }
        }
        .alert(
            purchases.message?.title ?? "",
            isPresented: Binding(
                get: { purchases.message != nil },
                set: { isPresented in
                    if !isPresented { purchases.dismissMessage() }
                }
            )
        ) {
            Button(PurchaseCopy.string("common.ok")) {
                purchases.dismissMessage()
            }
        } message: {
            Text(purchases.message?.body ?? "")
        }
    }
}

private struct PurchaseLoadingView: View {
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            VStack(spacing: 14) {
                ProgressView()
                    .controlSize(.large)
                Text(PurchaseCopy.string("access.checking"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDisplayName("ContentView")
    }
}
