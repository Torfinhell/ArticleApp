import SwiftUI

//struct Article: Identifiable {
//    let id = UUID()
//    let imageName: String
//    let title: String
//    let description: String
//    let tags: [String]
//}

struct ArticlesView: View {
    @EnvironmentObject var store: ArticleStore
    @EnvironmentObject var tagsStore: TagsStore
    @EnvironmentObject var likeStore: LikeStore
    @State private var selectedTab: Int = 1
    @State private var searchText: String = ""
    
    let tabTitles = ["Following", "For you", "Favorites"]
    
    var filteredArticles: [Article] {
        store.articles.filter { article in
            let matchesTags = tagsStore.selectedTags.isEmpty || !tagsStore.selectedTags.isDisjoint(with: Set(article.tags))
            let matchesSearch = searchText.isEmpty ? true : article.title.localizedCaseInsensitiveContains(searchText)
            let isFavorite = selectedTab != 2 || likeStore.likedArticleIDs.contains(article.id)
            return matchesTags && matchesSearch && isFavorite
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Заголовок
            Text("Articles")
                .font(.system(size: 40, weight: .bold))
                .padding(.top, 16)
                .padding(.horizontal)
                .padding(.bottom, 15)
            
            // Табы
            HStack(spacing: 10) {
                ForEach(0..<tabTitles.count, id: \.self) { idx in
                    Button(action: {
                        selectedTab = idx
                    }) {
                        VStack(spacing: 4) {
                            Text(tabTitles[idx])
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(selectedTab == idx ? .black : .gray)
                            Rectangle()
                                .frame(height: 2)
                                .foregroundColor(selectedTab == idx ? .black : .clear)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // Поиск
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search", text: $searchText)
                    .disableAutocorrection(true)
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // Список статей
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(filteredArticles) { article in
                        ArticleCard(article: article)
                            .environmentObject(likeStore)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
        }
    }
}

struct ArticleCard: View {
    let article: Article
    @EnvironmentObject var likeStore: LikeStore
    @State private var isLiked: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let image = article.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(2, contentMode: .fill)
                    .frame(height: 120)
                    .clipped()
                    .cornerRadius(12)
            } else if let imageName = article.imageName {
                Image(imageName)
                    .resizable()
                    .aspectRatio(2, contentMode: .fill)
                    .frame(height: 120)
                    .clipped()
                    .cornerRadius(12)
            }
            
            Text("Article: \(article.title)")
                .font(.system(size: 17, weight: .semibold))
            Text("Description: \(article.description)")
                .font(.system(size: 15))
                .foregroundColor(.gray)
            Text("Tags: \(article.tags.joined(separator: ", "))")
                .font(.system(size: 15, weight: .medium))
            
            HStack {
                Button(action: {}) {
                    Text("Subscribe")
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                Spacer()
                Button(action: {
                    if likeStore.likedArticleIDs.contains(article.id) {
                        likeStore.likedArticleIDs.remove(article.id)
                    } else {
                        likeStore.likedArticleIDs.insert(article.id)
                    }
                }) {
                    Image(systemName: likeStore.likedArticleIDs.contains(article.id) ? "heart.fill" : "heart")
                        .font(.system(size: 22))
                        .foregroundColor(likeStore.likedArticleIDs.contains(article.id) ? .red : .black)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color(.black).opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

struct ArticlesView_Previews: PreviewProvider {
    static var previews: some View {
        ArticlesView()
    }
} 
