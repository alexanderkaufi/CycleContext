import SwiftUI

@MainActor
extension CyclePreviewStore {
    static var preview: CyclePreviewStore {
        CyclePreviewStore()
    }
}

extension View {
    @MainActor
    func cyclePreviewEnvironment() -> some View {
        environmentObject(CyclePreviewStore.preview)
            .environmentObject(PurchaseManager(previewState: .trial))
    }
}
