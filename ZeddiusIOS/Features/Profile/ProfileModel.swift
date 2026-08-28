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

    func updateTargets(
        targetCalories: Int?,
        targetProteinG: Int?,
        targetWeightKg: Decimal?
    ) async -> Bool {
        errorMessage = nil
        let body = UpdateUserRequest(
            targetCalories: targetCalories,
            targetProteinG: targetProteinG,
            targetWeightKg: targetWeightKg
        )
        do {
            user = try await api.updateMe(body)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
