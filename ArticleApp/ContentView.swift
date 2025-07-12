import SwiftUI

struct TagsView: View {
    @EnvironmentObject var tagsStore: TagsStore
    
    let tags = ["IT", "Biology", "Science", "AI", "Plants", "School", "University"]
    
    var body: some View {
        VStack {
            Text("Tags")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)

            Spacer().frame(height: 40)

            // Tags grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                ForEach(tags, id: \.self) { tag in
                    TagView(title: tag, isSelected: tagsStore.selectedTags.contains(tag))
                        .onTapGesture {
                            if tagsStore.selectedTags.contains(tag) {
                                tagsStore.selectedTags.remove(tag)
                            } else {
                                tagsStore.selectedTags.insert(tag)
                            }
                        }
                }
            }
            .padding(.horizontal)

            Spacer()
        }
    }
}

struct TagView: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(isSelected ? .white : .black)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(isSelected ? Color.black : Color(UIColor.systemGray6))
            .cornerRadius(20)
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            TagsView()
                .tabItem {
                    Image("check")
                    
                }
            
            ArticlesView()
                .tabItem {
                    Image("articles")
                    
                }
            
            ProfileView()
                .tabItem {
                    Image("person")
    
                }
        }
    }
}

struct TagsView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
