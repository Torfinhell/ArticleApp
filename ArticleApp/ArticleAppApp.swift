//
//  ArticleAppApp.swift
//  ArticleApp
//
//  Created by Mac on 12.07.2025.
//

import SwiftUI

@main
struct ArticleAppApp: App {
    @StateObject var store = ArticleStore() // создаём один экземпляр
    @StateObject var tagsStore = TagsStore() // создаём один экземпляр для тегов
    @StateObject var likeStore = LikeStore() // создаём один экземпляр для лайков
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(tagsStore)
                .environmentObject(likeStore)
        }
    }
}
