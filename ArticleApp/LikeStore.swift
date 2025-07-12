import Foundation

class LikeStore: ObservableObject {
    @Published var likedArticleIDs: Set<UUID> = []
} 