import Foundation
import SwiftUI

class UserInfoStore: ObservableObject {
    @Published var userName: String = ""
    @Published var postedArticlesCount: Int = 0
    
    private let userDefaults = UserDefaults.standard
    private let userNameKey = "userName"
    private let postedArticlesCountKey = "postedArticlesCount"
    
    init() {
        loadUserInfo()
    }
    
    private func loadUserInfo() {
        // Load user name
        if let name = userDefaults.string(forKey: userNameKey) {
            userName = name
        }
        
        // Load posted articles count
        postedArticlesCount = userDefaults.integer(forKey: postedArticlesCountKey)
    }
    
    private func saveUserInfo() {
        userDefaults.set(userName, forKey: userNameKey)
        userDefaults.set(postedArticlesCount, forKey: postedArticlesCountKey)
    }
    
    func updateUserName(_ name: String) {
        userName = name
        saveUserInfo()
    }
    
    func incrementPostedArticlesCount() {
        postedArticlesCount += 1
        saveUserInfo()
    }
    
    func decrementPostedArticlesCount() {
        postedArticlesCount = max(0, postedArticlesCount - 1)
        saveUserInfo()
    }
} 