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

struct DraftRequest: Encodable {
    let title: String
    let content: String
    let tags: [String]
}

struct EmptyRequest: Encodable {
    // Empty struct for requests that don't need a body
}

class API{
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
    
    // Generic request method for POST, PATCH, PUT operations
    func request(method: String, path: String, body: Encodable? = nil, completion: @escaping (Result<DataTransfer, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            completion(.failure(NSError(domain: "URL error", code: 0)))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "accept")
        
        if let body = body {
            do {
                let jsonData = try JSONEncoder().encode(body)
                urlRequest.httpBody = jsonData
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
    
    func fetchSingle(query: String, completion: @escaping (Result<DataTransfer, Error>) -> Void) {
        request(method: "GET", path: query, completion: completion)
    }
    
    func post(request: String, body: Encodable, completion: @escaping (Result<DataTransfer, Error>) -> Void) {
        self.request(method: "POST", path: request, body: body, completion: completion)
    }
    
    func patch(request: String, body: Encodable, completion: @escaping (Result<DataTransfer, Error>) -> Void) {
        self.request(method: "PATCH", path: request, body: body, completion: completion)
    }
    
    func request(request: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)\(request)") else {
            completion(.failure(NSError(domain: "URL error", code: 0)))
            return
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(()))
        }.resume()
    }
}
class DraftsAPI {
    static let shared = DraftsAPI()
    let api = API.shared
    
    func fetchDrafts(completion: @escaping (Result<[DataTransfer], Error>) -> Void) {
        api.fetch(query: "/drafts", completion: completion)
    }
    
    func deleteDraft(draftId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        api.request(request: "/drafts/\(draftId)", completion: completion)
    }
    
    func fetchDraft(draftId: String, completion: @escaping (Result<DataTransfer, Error>) -> Void) {
        api.fetchSingle(query: "/drafts/\(draftId)", completion: completion)
    }
    
    func addDraft(title: String, content: String, tags: [String], completion: @escaping (Result<DataTransfer, Error>) -> Void) {
        let draftRequest = DraftRequest(title: title, content: content, tags: tags)
        api.post(request: "/drafts", body: draftRequest, completion: completion)
    }
    func editDraft(draftId: String, title: String, content: String, tags: [String], completion: @escaping (Result<DataTransfer, Error>) -> Void) {
        let draftRequest = DraftRequest(title: title, content: content, tags: tags)
        api.patch(request: "/drafts/\(draftId)", body: draftRequest, completion: completion)
    }
    
    func publishDraft(draftId: String, completion: @escaping (Result<DataTransfer, Error>) -> Void) {
        api.post(request: "/drafts/\(draftId)/publish", body: EmptyRequest(), completion: completion)
    }
}

class PostsAPI {
    static let shared = PostsAPI()
    let api = API.shared
    
    func fetchPosts(query: String = "", tags: [String] = [], size: Int = 20, page: Int = 0, completion: @escaping (Result<[DataTransfer], Error>) -> Void) {
        var queryItems: [URLQueryItem] = []
        
        if !query.isEmpty {
            queryItems.append(URLQueryItem(name: "query", value: query))
        }
        
        if !tags.isEmpty {
            let tagsString = tags.joined(separator: " ")
            queryItems.append(URLQueryItem(name: "tag", value: tagsString))
        }
        
        queryItems.append(URLQueryItem(name: "size", value: String(size)))
        queryItems.append(URLQueryItem(name: "page", value: String(page)))
        
        var urlComponents = URLComponents(string: "\(api.baseURL)/posts")
        urlComponents?.queryItems = queryItems
        
        guard let url = urlComponents?.url else {
            completion(.failure(NSError(domain: "URL error", code: 0)))
            return
        }
        
        print("DEBUG: Fetching posts from URL: \(url)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("DEBUG: Network error: \(error)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                print("DEBUG: No data received")
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(Response.self, from: data)
                print("DEBUG: Successfully decoded \(response.items.count) posts")
                completion(.success(response.items))
            } catch {
                print("DEBUG: Decoding error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    func UnpublishPost(postId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        api.request(request: "/posts/\(postId)/unpublish", completion: completion)
    }
    
    func fetchPost(postId: String, completion: @escaping (Result<DataTransfer, Error>) -> Void) {
        api.fetchSingle(query: "/posts/\(postId)", completion: completion)
    }
}

struct TagResponse: Decodable {
    let items: [String]
}

class TagAPI {
    static let shared = TagAPI()
    let api = API.shared
    
    func fetchTags(completion: @escaping (Result<[String], Error>) -> Void) {
        guard let url = URL(string: "\(api.baseURL)/tags") else {
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
                let response = try JSONDecoder().decode(TagResponse.self, from: data)
                completion(.success(response.items))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
