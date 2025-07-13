import Foundation
import SwiftUI

class UserTagsStore: ObservableObject {
    @Published var userTags: [String] = []
    
    private let userDefaults = UserDefaults.standard
    private let userTagsKey = "userTags"
    
    init() {
        loadUserTags()
    }
    
    private func loadUserTags() {
        // Load user's own tags from UserDefaults
        if let data = userDefaults.data(forKey: userTagsKey),
           let tags = try? JSONDecoder().decode([String].self, from: data) {
            userTags = tags
        }
    }
    
    private func saveUserTags() {
        // Save user's own tags to UserDefaults
        if let data = try? JSONEncoder().encode(userTags) {
            userDefaults.set(data, forKey: userTagsKey)
        }
    }
    
    func addUserTag(_ tag: String) {
        if !userTags.contains(tag) {
            userTags.append(tag)
            saveUserTags()
        }
    }
    
    func removeUserTag(_ tag: String) {
        userTags.removeAll { $0 == tag }
        saveUserTags()
    }
    
    func getUserTags() -> [String] {
        return userTags
    }
} 