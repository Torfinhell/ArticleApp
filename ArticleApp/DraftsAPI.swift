import Foundation

struct DraftsResponse: Decodable {
    let items: [DraftDTO]
    let total: Int
}

struct DraftDTO: Decodable, Identifiable {
    let id: String
    let title: String
    let content: String
    let status: String
    let tags: [String]
    let created_at: String
    let updated_at: String
    let published_at: String?
}

class DraftsAPI {
    static let shared = DraftsAPI()
    let baseURL = "http://89.169.180.108:8080/api/v1"
    
    func fetchDrafts(completion: @escaping (Result<[DraftDTO], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/drafts") else {
            completion(.failure(NSError(domain: "URL error", code: 0)))
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }
            do {
                let response = try JSONDecoder().decode(DraftsResponse.self, from: data)
                completion(.success(response.items))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
} 