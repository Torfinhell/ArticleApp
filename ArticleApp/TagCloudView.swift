import SwiftUI

struct TagCircle: Identifiable {
    let id = UUID()
    let label: String
    let size: CGFloat
    var x: CGFloat
    var y: CGFloat
}

func generateNonOverlappingCircles(
    labels: [String],
    sizes: [CGFloat],
    areaWidth: CGFloat,
    areaHeight: CGFloat,
    maxTries: Int = 1000
) -> [TagCircle] {
    var circles: [TagCircle] = []
    let count = min(labels.count, sizes.count)
    let padding: CGFloat = 8

    for i in 0..<count {
        let size = sizes[i]
        var tries = 0
        var position: CGPoint
        var overlaps: Bool

        repeat {
            let x = CGFloat.random(in: 0...(areaWidth - size))
            let y = CGFloat.random(in: 0...(areaHeight - size))
            position = CGPoint(x: x, y: y)
            overlaps = false

            for circle in circles {
                let dx = (circle.x + circle.size/2) - (x + size/2)
                let dy = (circle.y + circle.size/2) - (y + size/2)
                let distance = sqrt(dx*dx + dy*dy)
                if distance < (circle.size + size)/2 + padding {
                    overlaps = true
                    break
                }
            }
            tries += 1
        } while overlaps && tries < maxTries

        if !overlaps {
            circles.append(TagCircle(label: labels[i], size: size, x: position.x, y: position.y))
        }
    }
    return circles
}

struct TagsTabView: View {
    @EnvironmentObject var tagsStore: TagsStore

    let areaWidth: CGFloat = 600
    let areaHeight: CGFloat = 350
    let sizes: [CGFloat] = [130, 120, 110, 100, 90, 90, 90, 80, 80, 70, 70, 70, 60, 60, 60]

    @State private var tagCircles: [TagCircle] = []
    @State private var lastTagLabels: [String] = []

    var body: some View {
        VStack(spacing: 0) {
            Text("Tags")
                .font(.largeTitle)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 10)
                .padding(.bottom, 24)

            ScrollView(.horizontal, showsIndicators: false) {
                ZStack {
                    ForEach(tagCircles) { tag in
                        let isSelected = tagsStore.selectedTags.contains(tag.label)
                        Text(tag.label)
                            .font(.system(size: tag.size / 6, weight: .bold))
                            .foregroundColor(isSelected ? .white : .red)
                            .frame(width: tag.size, height: tag.size, alignment: .center)
                            .background(isSelected ? Color.red : Color.white)
                            .overlay(
                                Circle()
                                    .stroke(Color.red, lineWidth: isSelected ? 0 : 3)
                            )
                            .clipShape(Circle())
                            .multilineTextAlignment(.center)
                            .contentShape(Circle())
                            .onTapGesture {
                                tagsStore.toggleTag(tag.label)
                            }
                            .position(x: tag.x + tag.size / 2, y: tag.y + tag.size / 2)
                    }
                }
                .frame(width: areaWidth, height: areaHeight)
                .padding()
            }
            Spacer()
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .onAppear {
            let labels = Array(tagsStore.serverTags.prefix(sizes.count))
            tagCircles = generateNonOverlappingCircles(
                labels: labels,
                sizes: sizes,
                areaWidth: areaWidth,
                areaHeight: areaHeight
            )
            lastTagLabels = labels
            tagsStore.loadTagsFromServer()
        }
        .onChange(of: tagsStore.serverTags) { newTags in
            let labels = Array(newTags.prefix(sizes.count))
            if labels != lastTagLabels {
                tagCircles = generateNonOverlappingCircles(
                    labels: labels,
                    sizes: sizes,
                    areaWidth: areaWidth,
                    areaHeight: areaHeight
                )
                lastTagLabels = labels
            }
        }
    }
} 
