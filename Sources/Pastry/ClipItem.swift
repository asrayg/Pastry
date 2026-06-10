import Foundation

enum ClipContent: Codable, Equatable {
    case text(String)
    case image(Data) // PNG bytes
}

struct ClipItem: Identifiable, Codable, Equatable {
    let id: UUID
    var content: ClipContent
    var pinned: Bool
    var copiedAt: Date

    init(content: ClipContent) {
        self.id = UUID()
        self.content = content
        self.pinned = false
        self.copiedAt = Date()
    }
}
