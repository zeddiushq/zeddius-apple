import Foundation

@Observable
@MainActor
final class APIClient {
    private let baseURL: URL = {
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
              let url = URL(string: urlString) else {
            fatalError("API_BASE_URL missing or invalid in Info.plist — check Config/*.xcconfig")
        }
        return url
    }()
    private let session = URLSession.shared
    private let auth: AuthService

    init(auth: AuthService = .shared) {
        self.auth = auth
    }

    func getMe() async throws -> User {
        try await request("GET", path: "/users/me")
    }

    func updateMe(_ body: UpdateUserRequest) async throws -> User {
        let encoded = try APICoding.encoder.encode(body)
        return try await requestDecoded("PATCH", path: "/users/me", body: encoded, retrying: true)
    }

    func getWeightLogs() async throws -> [WeightLog] {
        let logs: [WeightLog] = try await request("GET", path: "/weight-logs")
        return logs.sorted { $0.recordedAt > $1.recordedAt }
    }

    func createWeightLog(_ body: CreateWeightLogRequest) async throws -> WeightLog {
        let encoded = try APICoding.encoder.encode(body)
        return try await requestDecoded("POST", path: "/weight-logs", body: encoded, retrying: true)
    }

    func deleteWeightLog(id: UUID) async throws {
        try await requestNoContent("DELETE", path: "/weight-logs/\(id.uuidString)", body: nil, retrying: true)
    }

    func getSleepLogs(from: Date? = nil, to: Date? = nil) async throws -> [SleepLog] {
        let logs: [SleepLog] = try await request("GET", path: "/sleep-logs", queryItems: Self.rangeQueryItems(from: from, to: to))
        return logs.sorted { $0.bedTime > $1.bedTime }
    }

    func createSleepLog(_ body: CreateSleepLogRequest) async throws -> SleepLog {
        let encoded = try APICoding.encoder.encode(body)
        return try await requestDecoded("POST", path: "/sleep-logs", body: encoded, retrying: true)
    }

    func deleteSleepLog(id: UUID) async throws {
        try await requestNoContent("DELETE", path: "/sleep-logs/\(id.uuidString)", body: nil, retrying: true)
    }

    func getFoodEntries(from: Date? = nil, to: Date? = nil) async throws -> [FoodEntry] {
        let entries: [FoodEntry] = try await request(
            "GET", path: "/food-entries", queryItems: Self.rangeQueryItems(from: from, to: to)
        )
        return entries.sorted { $0.consumedAt > $1.consumedAt }
    }

    func createFoodEntry(_ body: CreateFoodEntryRequest) async throws -> FoodEntry {
        let encoded = try APICoding.encoder.encode(body)
        return try await requestDecoded("POST", path: "/food-entries", body: encoded, retrying: true)
    }

    func deleteFoodEntry(id: UUID) async throws {
        try await requestNoContent("DELETE", path: "/food-entries/\(id.uuidString)", body: nil, retrying: true)
    }

    func getExercises() async throws -> [Exercise] {
        try await request("GET", path: "/exercises")
    }

    func getWorkouts(from: Date? = nil, to: Date? = nil) async throws -> [Workout] {
        let workouts: [Workout] = try await request(
            "GET", path: "/workouts", queryItems: Self.rangeQueryItems(from: from, to: to)
        )
        return workouts.sorted { $0.startedAt > $1.startedAt }
    }

    func createWorkout(_ body: CreateWorkoutRequest) async throws -> Workout {
        let encoded = try APICoding.encoder.encode(body)
        return try await requestDecoded("POST", path: "/workouts", body: encoded, retrying: true)
    }

    func createLiftSets(workoutId: UUID, _ body: BulkCreateLiftSetsRequest) async throws -> [LiftSet] {
        let encoded = try APICoding.encoder.encode(body)
        return try await requestDecoded(
            "POST", path: "/workouts/\(workoutId.uuidString)/lift-sets", body: encoded, retrying: true
        )
    }

    func updateLiftSet(id: UUID, _ body: UpdateLiftSetRequest) async throws -> LiftSet {
        let encoded = try APICoding.encoder.encode(body)
        return try await requestDecoded("PATCH", path: "/lift-sets/\(id.uuidString)", body: encoded, retrying: true)
    }

    func getWorkout(id: UUID) async throws -> Workout {
        try await request("GET", path: "/workouts/\(id.uuidString)")
    }

    func deleteWorkout(id: UUID) async throws {
        try await requestNoContent("DELETE", path: "/workouts/\(id.uuidString)", body: nil, retrying: true)
    }

    func createRunSession(workoutId: UUID, _ body: CreateRunSessionRequest) async throws -> RunSession {
        let encoded = try APICoding.encoder.encode(body)
        return try await requestDecoded(
            "POST", path: "/workouts/\(workoutId.uuidString)/run-session", body: encoded, retrying: true
        )
    }

    func getTasks() async throws -> [DailyTask] {
        try await request("GET", path: "/tasks")
    }

    func createTask(_ body: CreateTaskRequest) async throws -> DailyTask {
        let encoded = try APICoding.encoder.encode(body)
        return try await requestDecoded("POST", path: "/tasks", body: encoded, retrying: true)
    }

    func updateTask(id: UUID, _ body: UpdateTaskRequest) async throws -> DailyTask {
        let encoded = try APICoding.encoder.encode(body)
        return try await requestDecoded("PATCH", path: "/tasks/\(id.uuidString)", body: encoded, retrying: true)
    }

    func deleteTask(id: UUID) async throws {
        try await requestNoContent("DELETE", path: "/tasks/\(id.uuidString)", body: nil, retrying: true)
    }

    /// `from`/`to` are required server-side — no default range without the
    /// server knowing "today" in the caller's timezone.
    func getTaskCompletions(from: Date, to: Date) async throws -> [TaskCompletion] {
        try await request(
            "GET", path: "/task-completions",
            queryItems: [
                URLQueryItem(name: "from", value: APICoding.dateOnlyString(from: from)),
                URLQueryItem(name: "to", value: APICoding.dateOnlyString(from: to)),
            ]
        )
    }

    func completeTask(id: UUID, date: Date) async throws {
        let encoded = try APICoding.encoder.encode(CompleteTaskRequest(completedDate: APICoding.dateOnlyString(from: date)))
        try await requestNoContent("POST", path: "/tasks/\(id.uuidString)/complete", body: encoded, retrying: true)
    }

    func uncompleteTask(id: UUID, date: Date) async throws {
        try await requestNoContent(
            "DELETE",
            path: "/tasks/\(id.uuidString)/complete",
            queryItems: [URLQueryItem(name: "date", value: APICoding.dateOnlyString(from: date))],
            body: nil, retrying: true
        )
    }

    func getDailyCheckins(from: Date, to: Date) async throws -> [DailyCheckin] {
        try await request(
            "GET", path: "/daily-checkins",
            queryItems: [
                URLQueryItem(name: "from", value: APICoding.dateOnlyString(from: from)),
                URLQueryItem(name: "to", value: APICoding.dateOnlyString(from: to)),
            ]
        )
    }

    func upsertDailyCheckin(_ body: UpsertDailyCheckinRequest) async throws -> DailyCheckin {
        let encoded = try APICoding.encoder.encode(body)
        return try await requestDecoded("POST", path: "/daily-checkins", body: encoded, retrying: true)
    }

    func closeDay(date: Date) async throws -> DailyCheckin {
        try await requestDecoded(
            "POST", path: "/daily-checkins/\(APICoding.dateOnlyString(from: date))/close", body: nil, retrying: true
        )
    }

    func reopenDay(date: Date) async throws -> DailyCheckin {
        try await requestDecoded(
            "DELETE", path: "/daily-checkins/\(APICoding.dateOnlyString(from: date))/close", body: nil, retrying: true
        )
    }

    /// Builds `from`/`to` query items for endpoints whose field is a full
    /// `DateTime<Utc>` (food/sleep/workouts) — `nil` in, `nil` out, so a
    /// call site that doesn't pass a range gets exactly the same request
    /// (and the server's own default range) as before this param existed.
    private static func rangeQueryItems(from: Date?, to: Date?) -> [URLQueryItem] {
        var items: [URLQueryItem] = []
        if let from { items.append(URLQueryItem(name: "from", value: APICoding.iso8601String(from: from))) }
        if let to { items.append(URLQueryItem(name: "to", value: APICoding.iso8601String(from: to))) }
        return items
    }

    // MARK: - Core request handling

    private func request<T: Decodable>(_ method: String, path: String, queryItems: [URLQueryItem] = []) async throws -> T {
        try await requestDecoded(method, path: path, queryItems: queryItems, body: nil, retrying: true)
    }

    /// Every retry re-runs from here with the same encoded body, so a 401 on a
    /// POST/PATCH doesn't silently retry as a bodyless request.
    private func requestDecoded<T: Decodable>(
        _ method: String, path: String, queryItems: [URLQueryItem] = [], body: Data?, retrying: Bool
    ) async throws -> T {
        let (data, response) = try await perform(method: method, path: path, queryItems: queryItems, body: body)

        if response.statusCode == 401, retrying {
            _ = try await auth.refreshAccessToken()
            return try await requestDecoded(method, path: path, queryItems: queryItems, body: body, retrying: false)
        }

        if response.statusCode == 403 {
            auth.markNeedsEmailVerification()
        }
        guard (200...299).contains(response.statusCode) else {
            throw try serverError(from: data, status: response.statusCode)
        }

        do {
            return try APICoding.decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    private func requestNoContent(
        _ method: String, path: String, queryItems: [URLQueryItem] = [], body: Data?, retrying: Bool
    ) async throws {
        let (data, response) = try await perform(method: method, path: path, queryItems: queryItems, body: body)

        if response.statusCode == 401, retrying {
            _ = try await auth.refreshAccessToken()
            return try await requestNoContent(method, path: path, queryItems: queryItems, body: body, retrying: false)
        }

        guard (200...299).contains(response.statusCode) else {
            throw try serverError(from: data, status: response.statusCode)
        }
    }

    private func perform(
        method: String, path: String, queryItems: [URLQueryItem] = [], body: Data?
    ) async throws -> (Data, HTTPURLResponse) {
        guard let accessToken = KeychainService.get(.accessToken) else {
            throw APIError.unauthorized
        }

        var url = baseURL.appendingPathComponent(path)
        // appendingPathComponent doesn't handle query strings — build them
        // separately via URLComponents so "?"/"&"/"=" get properly encoded
        // rather than mangled as literal path characters.
        if !queryItems.isEmpty,
           var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            components.queryItems = queryItems
            url = components.url ?? url
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            return (data, http)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.network(error)
        }
    }

    private func serverError(from data: Data, status: Int) throws -> APIError {
        if let decoded = try? APICoding.decoder.decode(ErrorResponse.self, from: data) {
            return .server(code: decoded.error.code, message: decoded.error.message, status: status)
        }
        return .invalidResponse
    }
}
