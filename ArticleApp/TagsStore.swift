import Foundation
import SwiftUI

class TagsStore: ObservableObject {
    @Published var selectedTags: Set<String> = []
    @Published var serverTags: [String] = []
    
    private let userDefaults = UserDefaults.standard
    private let cachedTagsKey = "cachedTags"
    private let selectedTagsKey = "selectedTags"
    
    init() {
        loadCachedData()
    }
    
    private func loadCachedData() {
        // Load cached tags
        if let data = userDefaults.data(forKey: cachedTagsKey),
           let tags = try? JSONDecoder().decode([String].self, from: data) {
            serverTags = tags
        }
        
        // Load selected tags
        if let data = userDefaults.data(forKey: selectedTagsKey),
           let tags = try? JSONDecoder().decode([String].self, from: data) {
            selectedTags = Set(tags)
        }
    }
    
    private func saveCachedData() {
        // Save server tags
        if let data = try? JSONEncoder().encode(serverTags) {
            userDefaults.set(data, forKey: cachedTagsKey)
        }
        
        // Save selected tags
        let selectedTagsArray = Array(selectedTags)
        if let data = try? JSONEncoder().encode(selectedTagsArray) {
            userDefaults.set(data, forKey: selectedTagsKey)
        }
    }
    
    func loadTagsFromServer() {
        TagAPI.shared.fetchTags { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let tags):
                    print("Загружено тегов с сервера: \(tags.count)")
                    self.serverTags = tags
                    self.saveCachedData()
                case .failure(let error):
                    print("Ошибка загрузки тегов: \(error)")
                    // Keep empty array if server fails
                    self.serverTags = []
                    self.saveCachedData()
                }
            }
        }
    }
    
    func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
        saveCachedData()
    }
} 
} 