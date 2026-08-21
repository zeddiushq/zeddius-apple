import Foundation
import Observation

@Observable
@MainActor
final class ProfileModel {
    private(set) var user: User?
    private(set) var isLoading = false
    var errorMessage: String?

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            user = try await api.getMe()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
