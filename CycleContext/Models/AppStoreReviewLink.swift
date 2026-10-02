import Foundation

enum AppStoreReviewLink {
    static let appID = "6804225862"

    static var writeReviewURL: URL? {
        let normalizedAppID = appID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedAppID.isEmpty, normalizedAppID.allSatisfy(\.isNumber) else {
            return nil
        }

        var components = URLComponents(string: "https://apps.apple.com/app/id\(normalizedAppID)")
        components?.queryItems = [URLQueryItem(name: "action", value: "write-review")]
        return components?.url
    }
}
