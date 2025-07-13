import SwiftUI

struct ArticlesView: View {
    @EnvironmentObject var store: ArticleStore
    @EnvironmentObject var tagsStore: TagsStore
    @EnvironmentObject var likeStore: LikeStore
    @EnvironmentObject var userInfoStore: UserInfoStore
    @EnvironmentObject var userTagsStore: UserTagsStore
    @State private var selectedTab: Int = 0
    @State private var searchText: String = ""
    
    let tabTitles = ["For you", "Favorites"]
    
    var filteredArticles: [Article] {
        let filtered = store.articles.filter { article in
            let matchesTags = tagsStore.selectedTags.isEmpty || !tagsStore.selectedTags.isDisjoint(with: Set(article.tags))
            let matchesSearch = searchText.isEmpty ? true : article.title.localizedCaseInsensitiveContains(searchText)
            
            // For favorites tab, only show liked articles
            if selectedTab == 1 {
                return matchesTags && matchesSearch && likeStore.likedArticleIDs.contains(article.id)
            }
            
            return matchesTags && matchesSearch
        }
        return filtered
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
                    .onSubmit {
                        performSearch()
                    }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // Список статей - Fixed scrolling
            ScrollView {
                LazyVStack(spacing: 20) {
                    if filteredArticles.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: selectedTab == 1 ? "heart" : "doc.text")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text(selectedTab == 1 ? "No favorite articles yet" : "No articles found")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.gray)
                            Text(selectedTab == 1 ? "Like some articles to see them here" : "Try adjusting your search or tags")
                                .font(.system(size: 14))
                                .foregroundColor(.gray.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 50)
                        .frame(maxWidth: .infinity)
                    } else {
                        ForEach(filteredArticles) { article in
                            ArticleCard(article: article)
                                .environmentObject(likeStore)
                                .environmentObject(store)
                                .environmentObject(userInfoStore)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            performSearch()
        }
        .onChange(of: tagsStore.selectedTags) { _ in
            performSearch()
        }
    }
    
    private func performSearch() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let selectedTags = Array(tagsStore.selectedTags)
        print("DEBUG: ArticlesView.performSearch called with query: '\(query)', selectedTags: \(selectedTags)")
        store.loadPostsFromServer(query: query, tags: selectedTags)
    }
}

struct ArticleCard: View {
    let article: Article
    @EnvironmentObject var likeStore: LikeStore
    @EnvironmentObject var store: ArticleStore
    @EnvironmentObject var userInfoStore: UserInfoStore
    @State private var isLiked: Bool = false
    @State private var showingUnpublishAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Article: \(article.title)")
                .font(.system(size: 17, weight: .semibold))
            Text("Description: \(article.description)")
                .font(.system(size: 15))
                .foregroundColor(.gray)
            Text("Tags: \(article.tags.joined(separator: ", "))")
                .font(.system(size: 15, weight: .medium))
            
            HStack {
                Spacer()
                
                // Unpublish button for published posts
                if !article.isDraft {
                    Button(action: {
                        showingUnpublishAlert = true
                    }) {
                        Text("Unpublish")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                Button(action: {
                    likeStore.toggleLike(for: article.id)
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
        .alert("Unpublish Article", isPresented: $showingUnpublishAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Unpublish", role: .destructive) {
                print("DEBUG: Unpublish button pressed for article: \(article.title) with id: \(article.id)")
                store.unpublishPost(postId: article.id.uuidString) { success in
                    if success {
                        print("DEBUG: Article successfully unpublished and moved to drafts: \(article.title)")
                        // The article is now moved to drafts by the ArticleStore
                        // Decrement posted articles count
                        userInfoStore.decrementPostedArticlesCount()
                    } else {
                        print("DEBUG: Unpublish failed, keeping article in list: \(article.title)")
                    }
                }
            }
        } message: {
            Text("Are you sure you want to unpublish this article?")
        }
    }
}

struct ArticlesView_Previews: PreviewProvider {
    static var previews: some View {
        ArticlesView()
    }
} 
