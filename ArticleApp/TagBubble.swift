import SwiftUI

struct TagBubble: View {
    let tag: Tag

    var body: some View {
        Text(tag.label)
            .font(.system(size: tag.size / 6, weight: .bold))
            .foregroundColor(.white)
            .frame(width: tag.size, height: tag.size)
            .background(Color.red)
            .clipShape(Circle())
    }
} 