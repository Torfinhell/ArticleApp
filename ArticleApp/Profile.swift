import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var store: ArticleStore
    @EnvironmentObject var userInfoStore: UserInfoStore
    @State private var selectedTab: Int = 0
    @State private var showCreateArticle = false
    @State private var editingDraft: Article? = nil
    @State private var userName: String = ""
    
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
                    // Информация о пользователе
                    VStack(spacing: 20) {
                        Spacer()
                        
                        VStack(spacing: 16) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.gray)
                            
                            VStack(spacing: 8) {
                                Text("User Name")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                TextField("Enter your name", text: $userName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(maxWidth: 200)
                                    .multilineTextAlignment(.center)
                                    .onAppear {
                                        userName = userInfoStore.userName
                                    }
                                    .onChange(of: userName) { newValue in
                                        userInfoStore.updateUserName(newValue)
                                    }
                            }
                            
                            VStack(spacing: 8) {
                                Text("Posted Articles")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                Text("\(userInfoStore.postedArticlesCount)")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.black)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color(.black).opacity(0.04), radius: 4, x: 0, y: 2)
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .offset(y: -100) // Lift up the view
                } else {
                    // Черновики
                    ZStack(alignment: .bottomTrailing) {
                        ScrollView {
                            LazyVStack(spacing: 20) {
                                ForEach(store.drafts) { draft in
                                    DraftCard(article: draft, store: store, onEditWithDraft: { article in
                                        editingDraft = article
                                        showCreateArticle = true
                                    }, onPublish: {
                                        // Use the API to publish the draft
                                        DraftsAPI.shared.publishDraft(draftId: draft.id.uuidString) { result in
                                            DispatchQueue.main.async {
                                                switch result {
                                                case .success(let publishedPost):
                                                    print("Draft published successfully: \(publishedPost.title)")
                                                    // Remove from drafts and add to articles
                                                    store.removeDraft(draft)
                                                    let publishedArticle = Article(
                                                        id: UUID(uuidString: publishedPost.id) ?? draft.id,
                                                        title: publishedPost.title,
                                                        description: publishedPost.content,
                                                        tags: publishedPost.tags,
                                                        isDraft: false
                                                    )
                                                    store.addArticle(publishedArticle)
                                                    // Increment posted articles count
                                                    userInfoStore.incrementPostedArticlesCount()
                                                case .failure(let error):
                                                    print("Error publishing draft: \(error)")
                                                }
                                            }
                                        }
                                    })
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                            .padding(.bottom, 80)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        // Кнопка Add Draft - только в Drafts tab
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
                    }
                }
            }
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
    var onEditWithDraft: ((Article) -> Void)? = nil
    var onPublish: (() -> Void)? = nil
    @State private var showFullDescription: Bool = false
    @State private var isDeleting: Bool = false
    @State private var isLoadingEdit: Bool = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Article: \(article.title)")
                    .font(.system(size: 17, weight: .semibold))
                if showFullDescription || article.description.count <= 100 {
                    Text("Description: \(article.description)")
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                    if article.description.count > 100 {
                        Button(action: { showFullDescription = false }) {
                            Text("Show less")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.blue)
                        }
                    }
                } else {
                    Text("Description: \(article.description.prefix(100))...")
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                    Button(action: { showFullDescription = true }) {
                        Text("Show more")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                    }
                }
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
                        isDeleting = true
                        DraftsAPI.shared.deleteDraft(draftId: article.id.uuidString) { result in
                            DispatchQueue.main.async {
                                isDeleting = false
                                switch result {
                                case .success:
                                    store.removeDraft(article)
                                case .failure(let error):
                                    print("Error deleting draft: \(error)")
                                }
                            }
                        }
                    }) {
                        if isDeleting {
                            ProgressView()
                                .frame(width: 24, height: 24)
                        } else {
                            Text("Delete")
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                    Button(action: {
                        isLoadingEdit = true
                        DraftsAPI.shared.editDraft(draftId: article.id.uuidString, title: article.title, content: article.description, tags: article.tags) { result in
                            DispatchQueue.main.async {
                                isLoadingEdit = false
                                switch result {
                                case .success(let updatedDraft):
                                    let editedDraft = Article(
                                        id: UUID(uuidString: updatedDraft.id) ?? article.id,
                                        title: updatedDraft.title,
                                        description: updatedDraft.content,
                                        tags: updatedDraft.tags,
                                        isDraft: true
                                    )
                                    onEditWithDraft?(editedDraft)
                                case .failure(let error):
                                    print("Error editing draft: \(error)")
                                }
                            }
                        }
                    }) {
                        if isLoadingEdit {
                            ProgressView()
                                .frame(width: 24, height: 24)
                        } else {
                            Text("Edit")
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
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
