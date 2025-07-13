import SwiftUI

struct Tag: Identifiable {
    let id = UUID()
    let label: String
    let size: CGFloat
    let x: CGFloat
    let y: CGFloat
} 