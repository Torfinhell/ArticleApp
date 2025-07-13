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
    @StateObject var userInfoStore = UserInfoStore() // создаём один экземпляр для информации о пользователе
    @StateObject var userTagsStore = UserTagsStore() // создаём один экземпляр для пользовательских тегов
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(tagsStore)
                .environmentObject(likeStore)
                .environmentObject(userInfoStore)
                .environmentObject(userTagsStore)
        }
    }
}
