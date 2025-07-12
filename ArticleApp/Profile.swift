import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var store: ArticleStore
    @State private var selectedTab: Int = 1
    @State private var showCreateArticle = false
    @State private var editingDraft: Article? = nil
    
    // Теги, которые есть во вкладке Tags (можно вынести в отдельное хранилище при необходимости)
    let allTags = ["IT", "Biology", "Science", "AI", "Plants", "School", "University"]
    let tabTitles = ["Information", "Drafts"]
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                // Заголовок
                Text("Profile")
                    .font(.system(size: 40, weight: .bold))
                    .padding(.top, 16)
                    .padding(.horizontal)
                    .padding(.bottom, 15)
                
                // Табы
                HStack(spacing: 0) {
                    ForEach(0..<tabTitles.count, id: \.self) { idx in
                        Button(action: {
                            selectedTab = idx
                        }) {
                            VStack(spacing: 4) {
                                Text(tabTitles[idx])
                                    .font(.system(size: 18, weight: .medium))
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
                
                if selectedTab == 0 {
                    // Информация о пользователе (заглушка)
                    Spacer()
                    HStack {
                        Spacer()
                        Text("User information here")
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    Spacer()
                } else {
                    // Черновики
                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(store.drafts) { draft in
                                DraftCard(article: draft, store: store, onEdit: {
                                    editingDraft = draft
                                    showCreateArticle = true
                                }, onPublish: {
                                    store.addArticle(Article(id: draft.id, image: draft.image, imageName: draft.imageName, title: draft.title, description: draft.description, tags: draft.tags, isDraft: false))
                                    store.removeDraft(draft)
                                })
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 80)
                    }
                }
            }
            // Кнопка Add Draft
            Button(action: { showCreateArticle = true }) {
                Text("Add Draft")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.black)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(Color(.systemGray6))
                    .cornerRadius(24)
                    .shadow(color: Color(.black).opacity(0.04), radius: 2, x: 0, y: 1)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
            .sheet(isPresented: $showCreateArticle, onDismiss: { editingDraft = nil }) {
                ArticleCreateView(store: store, allTags: allTags, draftToEdit: editingDraft)
            }
        }
        .onAppear {
            store.loadDraftsFromServer()
        }
    }
}

struct DraftCard: View {
    let article: Article
    @ObservedObject var store: ArticleStore
    var onEdit: (() -> Void)? = nil
    var onPublish: (() -> Void)? = nil
    
    var body: some View {
        HStack {
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
                
                HStack(spacing: 12) {
                    Button(action: {
                        onPublish?()
                    }) {
                        Text("Publish")
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    Button(action: {
                        store.removeDraft(article)
                    }) {
                        Text("Delete")
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    Button(action: {
                        onEdit?()
                    }) {
                        Text("Edit")
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color(.black).opacity(0.04), radius: 4, x: 0, y: 2)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView().environmentObject(ArticleStore())
    }
} 
