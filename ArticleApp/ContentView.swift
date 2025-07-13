import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TagsTabView()
                .tabItem {
                    Image(systemName: "tag")
                    Text("Tags")
                }
            ArticlesView()
                .tabItem {
                    Image(systemName: "doc.text")
                    Text("Articles")
                }
            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
        }
    }
}
