import SwiftUI

struct Article: Identifiable, Equatable {
    let id: UUID
    var title: String
    var description: String
    var tags: [String]
    var isDraft: Bool
    
    init(id: UUID = UUID(), title: String, description: String, tags: [String], isDraft: Bool) {
        self.id = id
        self.title = title
        self.description = description
        self.tags = tags
        self.isDraft = isDraft
    }
}

class ArticleStore: ObservableObject {
    @Published var articles: [Article] = []
    @Published var drafts: [Article] = []
    
    init() {
        // No cache loading - data will be fetched from server
    }
    
    func addArticle(_ article: Article) {
        articles.insert(article, at: 0)
    }
    
    func addDraft(_ article: Article) {
        drafts.insert(article, at: 0)
    }
    
    func removeDraft(_ article: Article) {
        drafts.removeAll { $0.id == article.id }
    }
    
    func loadDraftsFromServer() {
        DraftsAPI.shared.fetchDrafts { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let draftsDTO):
                    print("Загружено черновиков с сервера: \(draftsDTO.count)")
                    self.drafts = draftsDTO.compactMap { dto in
                        print("Draft: \(dto.title), id: \(dto.id)")
                        guard let uuid = UUID(uuidString: dto.id) else { return nil }
                        return Article(
                            id: uuid,
                            title: dto.title,
                            description: dto.content,
                            tags: dto.tags,
                            isDraft: true
                        )
                    }
                case .failure(let error):
                    print("Ошибка загрузки черновиков: \(error)")
                }
            }
        }
    }
    
    func loadPostsFromServer(query: String = "", tags: [String] = []) {
        print("DEBUG: ArticleStore.loadPostsFromServer called with query: '\(query)', tags: \(tags)")
        PostsAPI.shared.fetchPosts(query: query, tags: tags) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let postsDTO):
                    print("DEBUG: ArticleStore received \(postsDTO.count) posts from server")
                    self.articles = postsDTO.compactMap { dto in
                        print("DEBUG: Processing post: \(dto.title), id: \(dto.id)")
                        guard let uuid = UUID(uuidString: dto.id) else { 
                            print("DEBUG: Failed to create UUID from string: \(dto.id)")
                            return nil 
                        }
                        let article = Article(
                            id: uuid,
                            title: dto.title,
                            description: dto.content,
                            tags: dto.tags,
                            isDraft: false
                        )
                        print("DEBUG: Created article: \(article.title)")
                        return article
                    }
                    print("DEBUG: ArticleStore now has \(self.articles.count) articles")
                    
                    // Test: Print all articles to see if they're loaded
                    for (index, article) in self.articles.enumerated() {
                        print("DEBUG: Article \(index): \(article.title) - Tags: \(article.tags)")
                    }
                case .failure(let error):
                    print("DEBUG: ArticleStore error loading posts: \(error)")
                }
            }
        }
    }
    
    // Test function to load all posts without filtering
    func loadAllPosts() {
        print("DEBUG: Testing loadAllPosts")
        PostsAPI.shared.fetchPosts(query: "", tags: []) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let postsDTO):
                    print("DEBUG: Test - Received \(postsDTO.count) posts")
                    self.articles = postsDTO.compactMap { dto in
                        guard let uuid = UUID(uuidString: dto.id) else { return nil }
                        return Article(
                            id: uuid,
                            title: dto.title,
                            description: dto.content,
                            tags: dto.tags,
                            isDraft: false
                        )
                    }
                    print("DEBUG: Test - Now have \(self.articles.count) articles")
                case .failure(let error):
                    print("DEBUG: Test - Error: \(error)")
                }
            }
        }
    }
    
    func unpublishPost(postId: String, completion: @escaping (Bool) -> Void) {
        print("DEBUG: ArticleStore.unpublishPost called with postId: \(postId)")
        PostsAPI.shared.UnpublishPost(postId: postId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let unpublishedPost):
                    print("DEBUG: Post successfully unpublished on server: \(unpublishedPost.title)")
                    // The post is now a draft, so we should move it to drafts
                    if let uuid = UUID(uuidString: unpublishedPost.id) {
                        let draftArticle = Article(
                            id: uuid,
                            title: unpublishedPost.title,
                            description: unpublishedPost.content,
                            tags: unpublishedPost.tags,
                            isDraft: true
                        )
                        // Remove from articles and add to drafts
                        self.articles.removeAll { $0.id == uuid }
                        self.addDraft(draftArticle)
                        print("DEBUG: Moved unpublished post to drafts: \(draftArticle.title)")
                    }
                    completion(true)
                case .failure(let error):
                    print("DEBUG: Error unpublishing post: \(error)")
                    completion(false)
                }
            }
        }
    }
} 
