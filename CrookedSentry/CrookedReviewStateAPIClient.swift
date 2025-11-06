import Foundation

struct CrookedReviewState: Codable, Identifiable {
    var id: String { eventId }
    let eventId: String
    let reviewedBy: String?
    let reviewed: Bool
}

class CrookedReviewStateAPIClient {
    let baseURL: String
    private let session: URLSession
    
    init(baseURL: String) {
        self.baseURL = baseURL
        self.session = URLSession.shared
    }
    
    func fetchReviewStates() async throws -> [CrookedReviewState] {
        guard let url = URL(string: "\(baseURL)/api/crooked-review-state") else {
            throw URLError(.badURL)
        }
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode([CrookedReviewState].self, from: data)
    }
    
    func fetchReviewState(eventId: String) async throws -> CrookedReviewState? {
        guard let url = URL(string: "\(baseURL)/api/crooked-review-state/\(eventId)") else {
            throw URLError(.badURL)
        }
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try? JSONDecoder().decode(CrookedReviewState.self, from: data)
    }
    
    func markEventAsReviewed(eventId: String, reviewedBy: String? = nil) async throws {
        guard let url = URL(string: "\(baseURL)/api/crooked-review-state") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["eventId": eventId, "reviewed": true]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }
    
    func batchMarkEventsAsReviewed(eventIds: [String], reviewedBy: String? = nil) async throws {
        guard let url = URL(string: "\(baseURL)/api/crooked-review-state/batch") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = eventIds.map { ["eventId": $0, "reviewed": true] }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }
}
