import Foundation
import SwiftUI

class TagsStore: ObservableObject {
    @Published var selectedTags: Set<String> = []
    @Published var serverTags: [String] = []
    
    private let userDefaults = UserDefaults.standard
    private let selectedTagsKey = "selectedTags"
    
    init() {
        loadSelectedTags()
    }
    
    private func loadSelectedTags() {
        // Load selected tags from UserDefaults
        if let data = userDefaults.data(forKey: selectedTagsKey),
           let tags = try? JSONDecoder().decode([String].self, from: data) {
            selectedTags = Set(tags)
        }
    }
    
    private func saveSelectedTags() {
        // Save selected tags to UserDefaults
        let selectedTagsArray = Array(selectedTags)
        if let data = try? JSONEncoder().encode(selectedTagsArray) {
            userDefaults.set(data, forKey: selectedTagsKey)
        }
    }
    
    func clearSelectedTags() {
        selectedTags.removeAll()
        saveSelectedTags()
        print("DEBUG: Cleared all selected tags")
    }
    
    func debugSelectedTags() {
        print("DEBUG: Current selected tags in memory: \(selectedTags)")
        if let data = userDefaults.data(forKey: selectedTagsKey),
           let tags = try? JSONDecoder().decode([String].self, from: data) {
            print("DEBUG: Selected tags in UserDefaults: \(tags)")
        } else {
            print("DEBUG: No selected tags found in UserDefaults")
        }
    }
    
    func loadTagsFromServer() {
        TagAPI.shared.fetchTags { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let tags):
                    print("Загружено тегов с сервера: \(tags.count)")
                    self.serverTags = tags
                case .failure(let error):
                    print("Ошибка загрузки тегов: \(error)")
                    // Keep empty array if server fails
                    self.serverTags = []
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
        saveSelectedTags() // Save selected tags to persist them
    }
} 