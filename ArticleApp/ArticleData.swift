import SwiftUI

struct Article: Identifiable, Equatable {
    let id: UUID
    var image: UIImage?
    var imageName: String? // для ассетов
    var title: String
    var description: String
    var tags: [String]
    var isDraft: Bool
    
    init(id: UUID = UUID(), image: UIImage? = nil, imageName: String? = nil, title: String, description: String, tags: [String], isDraft: Bool) {
        self.id = id
        self.image = image
        self.imageName = imageName
        self.title = title
        self.description = description
        self.tags = tags
        self.isDraft = isDraft
    }
}

// Codable struct for caching
struct CachedArticle: Codable {
    let id: String
    let title: String
    let description: String
    let tags: [String]
    let isDraft: Bool
    let timestamp: Date
    
    init(from article: Article) {
        self.id = article.id.uuidString
        self.title = article.title
        self.description = article.description
        self.tags = article.tags
        self.isDraft = article.isDraft
        self.timestamp = Date()
    }
    
    func toArticle() -> Article? {
        guard let uuid = UUID(uuidString: id) else { return nil }
        return Article(
            id: uuid,
            image: nil,
            imageName: nil,
            title: title,
            description: description,
            tags: tags,
            isDraft: isDraft
        )
    }
}

class ArticleStore: ObservableObject {
    @Published var articles: [Article] = []
    @Published var drafts: [Article] = []
    
    private let userDefaults = UserDefaults.standard
    private let cachedPostsKey = "cachedPosts"
    private let cachedDraftsKey = "cachedDrafts"
    private let maxCachedItems = 10
    
    init() {
        loadCachedData()
    }
    
    private func loadCachedData() {
        // Load cached posts
        if let data = userDefaults.data(forKey: cachedPostsKey),
           let cachedPosts = try? JSONDecoder().decode([CachedArticle].self, from: data) {
            articles = cachedPosts.compactMap { $0.toArticle() }
        }
        
        // Load cached drafts
        if let data = userDefaults.data(forKey: cachedDraftsKey),
           let cachedDrafts = try? JSONDecoder().decode([CachedArticle].self, from: data) {
            drafts = cachedDrafts.compactMap { $0.toArticle() }
        }
    }
    
    private func saveCachedData() {
        // Save posts (keep only last 10)
        let cachedPosts = articles.prefix(maxCachedItems).map { CachedArticle(from: $0) }
        if let data = try? JSONEncoder().encode(cachedPosts) {
            userDefaults.set(data, forKey: cachedPostsKey)
        }
        
        // Save drafts (keep only last 10)
        let cachedDrafts = drafts.prefix(maxCachedItems).map { CachedArticle(from: $0) }
        if let data = try? JSONEncoder().encode(cachedDrafts) {
            userDefaults.set(data, forKey: cachedDraftsKey)
        }
    }
    
    func addArticle(_ article: Article) {
        articles.insert(article, at: 0)
        saveCachedData()
    }
    
    func addDraft(_ article: Article) {
        drafts.insert(article, at: 0)
        saveCachedData()
    }
    
    func removeDraft(_ article: Article) {
        drafts.removeAll { $0.id == article.id }
        saveCachedData()
    }
    
    func loadDraftsFromServer() {
        DraftsAPI.shared.fetchDrafts { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let draftsDTO):
                    print("Загружено черновиков с сервера: \(draftsDTO.count)")
                    self.drafts = draftsDTO.prefix(self.maxCachedItems).compactMap { dto in
                        print("Draft: \(dto.title), id: \(dto.id)")
                        guard let uuid = UUID(uuidString: dto.id) else { return nil }
                        return Article(
                            id: uuid,
                            image: nil,
                            imageName: nil,
                            title: dto.title,
                            description: dto.content,
                            tags: dto.tags,
                            isDraft: true
                        )
                    }
                    self.saveCachedData()
                case .failure(let error):
                    print("Ошибка загрузки черновиков: \(error)")
                }
            }
        }
    }
    
    func loadPostsFromServer(query: String = "", tags: [String] = []) {
        PostsAPI.shared.fetchPosts(query: query, tags: tags) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let postsDTO):
                    print("Загружено постов с сервера: \(postsDTO.count)")
                    self.articles = postsDTO.prefix(self.maxCachedItems).compactMap { dto in
                        print("Post: \(dto.title), id: \(dto.id)")
                        guard let uuid = UUID(uuidString: dto.id) else { return nil }
                        return Article(
                            id: uuid,
                            image: nil,
                            imageName: nil,
                            title: dto.title,
                            description: dto.content,
                            tags: dto.tags,
                            isDraft: false
                        )
                    }
                    self.saveCachedData()
                case .failure(let error):
                    print("Ошибка загрузки постов: \(error)")
                }
            }
        }
    }
    
    func unpublishPost(postId: String, completion: @escaping (Bool) -> Void) {
        PostsAPI.shared.UnpublishPost(postId: postId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("Пост успешно снят с публикации")
                    completion(true)
                case .failure(let error):
                    print("Ошибка снятия поста с публикации: \(error)")
                    completion(false)
                }
            }
        }
    }
} 
