import Foundation
import SwiftUI

class TagsStore: ObservableObject {
    @Published var selectedTags: Set<String> = ["Plants", "University"]
} 