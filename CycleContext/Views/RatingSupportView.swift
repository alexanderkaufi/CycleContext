import StoreKit
import SwiftUI

struct RatingSupportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) private var requestReview

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 54))
                        .foregroundStyle(.pink)
                        .accessibilityHidden(true)

                    VStack(spacing: 10) {
                        Text("rating.support.title")
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)

                        Text("rating.support.message")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HStack(spacing: 8) {
                        ForEach(0..<5, id: \.self) { _ in
                            Image(systemName: "star.fill")
                        }
                    }
                    .font(.title3)
                    .foregroundStyle(.yellow)
                    .accessibilityHidden(true)

                    VStack(spacing: 10) {
                        Button(action: openRating) {
                            Label("rating.support.action", systemImage: "star.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)

                        Button("rating.support.later") {
                            dismiss()
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .frame(minHeight: 44)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            .navigationTitle("rating.support.navigationTitle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel(Text("common.close"))
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func openRating() {
        if let reviewURL = AppStoreReviewLink.writeReviewURL {
            openURL(reviewURL)
        } else {
            requestReview()
        }
        dismiss()
    }
}

#Preview("Rating Support") {
    RatingSupportView()
}
