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
                    let columns = [GridItem(.adaptive(minimum: 80), spacing: 8)]
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(allTags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 15))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(selectedTags.contains(tag) ? Color.black : Color(.systemGray6))
                                .foregroundColor(selectedTags.contains(tag) ? .white : .black)
                                .cornerRadius(16)
                                .onTapGesture {
                                    if selectedTags.contains(tag) {
                                        selectedTags.remove(tag)
                                    } else {
                                        selectedTags.insert(tag)
                                    }
                                }
                        }
                    }
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
                            store.removeDraft(draft)
                        }
                        let article = Article(image: image, title: title, description: description, tags: Array(selectedTags), isDraft: true)
                        store.addDraft(article)
                        presentationMode.wrappedValue.dismiss()
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
                            store.removeDraft(draft)
                        }
                        let article = Article(image: image, title: title, description: description, tags: Array(selectedTags), isDraft: false)
                        store.addArticle(article)
                        presentationMode.wrappedValue.dismiss()
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