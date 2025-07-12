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

class ArticleStore: ObservableObject {
    @Published var articles: [Article] = [
        Article(imageName: "plants", title: "Name of Article", description: "Some description....", tags: ["Plants", "IT"], isDraft: false)
    ]
    @Published var drafts: [Article] = [
        Article(imageName: "plants", title: "Name of Article", description: "Some description....", tags: ["Plants", "IT"], isDraft: true)
    ]
    
    func addArticle(_ article: Article) {
        articles.insert(article, at: 0)
    }
    
    func addDraft(_ article: Article) {
        drafts.insert(article, at: 0)
    }
    
    func removeDraft(_ article: Article) {
        drafts.removeAll { $0.id == article.id }
    }
} 