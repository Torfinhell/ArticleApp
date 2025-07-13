import Foundation

struct Response: Decodable {
    let items: [DataTransfer]
    let total: Int
}

struct DataTransfer: Decodable, Identifiable {
    let id: String
    let title: String
    let content: String
    let status: String
    let tags: [String]
    let created_at: String
    let updated_at: String
    let published_at: String?
}

class API {
    static let shared = API()
    let baseURL = "http://89.169.180.108:8080/api/v1"
    
    func fetch(query: String, completion: @escaping (Result<[DataTransfer], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)\(query)") else {
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
                let response = try JSONDecoder().decode(Response.self, from: data)
                completion(.success(response.items))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func fetchSingle(query: String, completion: @escaping (Result<DataTransfer, Error>) -> Void) {
        request(method: "GET", path: query, completion: completion)
    }
    
    func request(method: String, path: String, body: Encodable? = nil, completion: @escaping (Result<DataTransfer, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            completion(.failure(NSError(domain: "URL error", code: 0)))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        
        if let body = body {
            do {
                urlRequest.httpBody = try JSONEncoder().encode(body)
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                urlRequest.setValue("application/json", forHTTPHeaderField: "accept")
            } catch {
                completion(.failure(error))
                return
            }
        }
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(DataTransfer.self, from: data)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func post(request: String, body: Encodable, completion: @escaping (Result<DataTransfer, Error>) -> Void) {
        self.request(method: "POST", path: request, body: body, completion: completion)
    }

    func patch(request: String, body: Encodable, completion: @escaping (Result<DataTransfer, Error>) -> Void) {
        self.request(method: "PATCH", path: request, body: body, completion: completion)
    }
}

class DraftsAPI {
    static let shared = DraftsAPI()
    let api = API.shared
    
    func fetchDrafts(completion: @escaping (Result<[DataTransfer], Error>) -> Void) {
        api.fetch(query: "/drafts", completion: completion)
    }
    
    func deleteDraft(draftId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        api.request(method: "DELETE", path: "/drafts/\(draftId)", completion: { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }
    
    func fetchDraft(draftId: String, completion: @escaping (Result<DataTransfer, Error>) -> Void) {
        api.fetchSingle(query: "/drafts/\(draftId)", completion: completion)
    }

    func transformDraft(draftId: String, title: String, content: String, tags: [String], completion: @escaping (Result<DataTransfer, Error>) -> Void) {
        guard let url = URL(string: "\(api.baseURL)/drafts/\(draftId)") else {
            completion(.failure(NSError(domain: "URL error", code: 0)))
            return
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PATCH"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "accept")

        let draftData = DataTransfer(
            id: draftId,
            title: title,
            content: content,
            status: "draft", // Assuming status is "draft" for updates
            tags: tags,
            created_at: "", // Not provided in the new_data, so keep empty
            updated_at: "", // Not provided in the new_data, so keep empty
            published_at: nil // Not provided in the new_data, so keep nil
        )

        do {
            let jsonData = try JSONEncoder().encode(draftData)
            urlRequest.httpBody = jsonData
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }

            do {
                let response = try JSONDecoder().decode(DataTransfer.self, from: data)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func publishDraft(draftId: String, completion: @escaping (Result<DataTransfer, Error>) -> Void) {
        guard let url = URL(string: "\(api.baseURL)/drafts/\(draftId)/publish") else {
            completion(.failure(NSError(domain: "URL error", code: 0)))
            return
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "accept")

        let emptyRequest = EmptyRequest()
        do {
            let jsonData = try JSONEncoder().encode(emptyRequest)
            urlRequest.httpBody = jsonData
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }

            do {
                let response = try JSONDecoder().decode(DataTransfer.self, from: data)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

struct EmptyRequest: Encodable {
    // Empty struct for requests that don't need a body
} 