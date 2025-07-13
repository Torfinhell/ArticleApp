import SwiftUI

struct ArticleCreateView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var store: ArticleStore
    let allTags: [String]
    var draftToEdit: Article? = nil
    
    @State private var image: UIImage? = nil
    @State private var showImagePicker = false
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var selectedTags: Set<String> = []
    @State private var didSetup: Bool = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Картинка
                    Button(action: { showImagePicker = true }) {
                        if let image = image {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 160)
                                .clipped()
                                .cornerRadius(14)
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(.systemGray6))
                                    .frame(height: 160)
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("Add Image")
                                    .foregroundColor(.gray)
                                    .offset(y: 40)
                            }
                        }
                    }
                    .sheet(isPresented: $showImagePicker) {
                        ImagePicker(image: $image)
                    }
                    
                    // Название
                    TextField("Title", text: $title)
                        .font(.system(size: 20, weight: .semibold))
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    // Описание
                    TextField("Description", text: $description, axis: .vertical)
                        .font(.system(size: 16))
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    // Теги
                    Text("Tags:")
                        .font(.system(size: 16, weight: .medium))
                    TextField("Enter tags separated by commas", text: Binding(
                        get: { selectedTags.joined(separator: ", ") },
                        set: { newValue in
                            let tags = newValue.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                            selectedTags = Set(tags)
                        }
                    ))
                    .font(.system(size: 15))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                }
                .padding()
            }
            .navigationBarTitle("Create Article", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
            }
            // Кнопки внизу
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 16) {
                    Button(action: {
                        if let draft = draftToEdit {
                            // Update existing draft
                            DraftsAPI.shared.editDraft(draftId: draft.id.uuidString, title: title, content: description, tags: Array(selectedTags)) { result in
                                DispatchQueue.main.async {
                                    switch result {
                                    case .success(let updatedDraft):
                                        let updatedArticle = Article(
                                            id: UUID(uuidString: updatedDraft.id) ?? draft.id,
                                            image: image,
                                            imageName: nil,
                                            title: updatedDraft.title,
                                            description: updatedDraft.content,
                                            tags: updatedDraft.tags,
                                            isDraft: true
                                        )
                                        store.removeDraft(draft)
                                        store.addDraft(updatedArticle)
                                        presentationMode.wrappedValue.dismiss()
                                    case .failure(let error):
                                        print("Error updating draft: \(error)")
                                    }
                                }
                            }
                        } else {
                            // Create new draft
                            DraftsAPI.shared.addDraft(title: title, content: description, tags: Array(selectedTags)) { result in
                                DispatchQueue.main.async {
                                    switch result {
                                    case .success(let newDraft):
                                        let article = Article(
                                            id: UUID(uuidString: newDraft.id) ?? UUID(),
                                            image: image,
                                            imageName: nil,
                                            title: newDraft.title,
                                            description: newDraft.content,
                                            tags: newDraft.tags,
                                            isDraft: true
                                        )
                                        store.addDraft(article)
                                        presentationMode.wrappedValue.dismiss()
                                    case .failure(let error):
                                        print("Error creating draft: \(error)")
                                    }
                                }
                            }
                        }
                    }) {
                        Text("Save Draft")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.black)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                    }
                    Button(action: {
                        if let draft = draftToEdit {
                            // Update and publish existing draft
                            DraftsAPI.shared.editDraft(draftId: draft.id.uuidString, title: title, content: description, tags: Array(selectedTags)) { result in
                                DispatchQueue.main.async {
                                    switch result {
                                    case .success(let updatedDraft):
                                        // Publish the updated draft
                                        DraftsAPI.shared.publishDraft(draftId: updatedDraft.id) { publishResult in
                                            DispatchQueue.main.async {
                                                switch publishResult {
                                                case .success(let publishedPost):
                                                    let publishedArticle = Article(
                                                        id: UUID(uuidString: publishedPost.id) ?? draft.id,
                                                        image: image,
                                                        imageName: nil,
                                                        title: publishedPost.title,
                                                        description: publishedPost.content,
                                                        tags: publishedPost.tags,
                                                        isDraft: false
                                                    )
                                                    store.removeDraft(draft)
                                                    store.addArticle(publishedArticle)
                                                    presentationMode.wrappedValue.dismiss()
                                                case .failure(let error):
                                                    print("Error publishing draft: \(error)")
                                                }
                                            }
                                        }
                                    case .failure(let error):
                                        print("Error updating draft: \(error)")
                                    }
                                }
                            }
                        } else {
                            // Create new draft and publish it
                            DraftsAPI.shared.addDraft(title: title, content: description, tags: Array(selectedTags)) { result in
                                DispatchQueue.main.async {
                                    switch result {
                                    case .success(let newDraft):
                                        // Publish the new draft
                                        DraftsAPI.shared.publishDraft(draftId: newDraft.id) { publishResult in
                                            DispatchQueue.main.async {
                                                switch publishResult {
                                                case .success(let publishedPost):
                                                    let publishedArticle = Article(
                                                        id: UUID(uuidString: publishedPost.id) ?? UUID(),
                                                        image: image,
                                                        imageName: nil,
                                                        title: publishedPost.title,
                                                        description: publishedPost.content,
                                                        tags: publishedPost.tags,
                                                        isDraft: false
                                                    )
                                                    store.addArticle(publishedArticle)
                                                    presentationMode.wrappedValue.dismiss()
                                                case .failure(let error):
                                                    print("Error publishing draft: \(error)")
                                                }
                                            }
                                        }
                                    case .failure(let error):
                                        print("Error creating draft: \(error)")
                                    }
                                }
                            }
                        }
                    }) {
                        Text("Publish")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.black)
                            .cornerRadius(16)
                    }
                }
                .padding(.vertical, 10)
            }
            .onAppear {
                if !didSetup, let draft = draftToEdit {
                    self.title = draft.title
                    self.description = draft.description
                    self.selectedTags = Set(draft.tags)
                    self.image = draft.image
                    self.didSetup = true
                }
            }
        }
    }
} 