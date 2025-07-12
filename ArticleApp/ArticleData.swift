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
    
    func loadDraftsFromServer() {
        DraftsAPI.shared.fetchDrafts { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let draftsDTO):
                    print("Загружено черновиков с сервера: \(draftsDTO.count)")
                    self.drafts = draftsDTO.prefix(10).compactMap { dto in
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
                case .failure(let error):
                    print("Ошибка загрузки черновиков: \(error)")
                }
            }
        }
    }
} 
