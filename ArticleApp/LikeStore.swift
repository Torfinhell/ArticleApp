import Foundation

class LikeStore: ObservableObject {
    @Published var likedArticleIDs: Set<UUID> = []
    
    private let userDefaults = UserDefaults.standard
    private let likedIDsKey = "likedArticleIDs"
    
    init() {
        loadLikedIDs()
    }
    
    private func loadLikedIDs() {
        if let data = userDefaults.data(forKey: likedIDsKey),
           let ids = try? JSONDecoder().decode([String].self, from: data) {
            likedArticleIDs = Set(ids.compactMap { UUID(uuidString: $0) })
        }
    }
    
    private func saveLikedIDs() {
        let ids = likedArticleIDs.map { $0.uuidString }
        if let data = try? JSONEncoder().encode(ids) {
            userDefaults.set(data, forKey: likedIDsKey)
        }
    }
    
    func toggleLike(for articleID: UUID) {
        if likedArticleIDs.contains(articleID) {
            likedArticleIDs.remove(articleID)
        } else {
            likedArticleIDs.insert(articleID)
        }
        saveLikedIDs()
    }
} 