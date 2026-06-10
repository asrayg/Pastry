import Foundation
import Combine

final class HistoryStore: ObservableObject {
    // Windows clipboard history keeps 25 items; pinned items don't count against it.
    static let maxUnpinned = 25
    static let maxItemBytes = 4 * 1024 * 1024

    @Published private(set) var items: [ClipItem] = []

    private let saveURL: URL

    init() {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Pastry", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        saveURL = dir.appendingPathComponent("history.json")

        // Migrate history from the pre-rename app.
        let legacy = base.appendingPathComponent("CopyPaste/history.json")
        if !fm.fileExists(atPath: saveURL.path), fm.fileExists(atPath: legacy.path) {
            try? fm.copyItem(at: legacy, to: saveURL)
        }
        load()
    }

    func add(_ content: ClipContent) {
        if let idx = items.firstIndex(where: { $0.content == content }) {
            var existing = items.remove(at: idx)
            existing.copiedAt = Date()
            items.insert(existing, at: 0)
        } else {
            items.insert(ClipItem(content: content), at: 0)
        }
        trim()
        save()
    }

    func togglePin(_ id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].pinned.toggle()
        trim()
        save()
    }

    func delete(_ id: UUID) {
        items.removeAll { $0.id == id }
        save()
    }

    /// Like Windows "Clear all": removes everything except pinned items.
    func clearAll() {
        items.removeAll { !$0.pinned }
        save()
    }

    private func trim() {
        var unpinned = 0
        items = items.filter { item in
            if item.pinned { return true }
            unpinned += 1
            return unpinned <= Self.maxUnpinned
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let decoded = try? JSONDecoder().decode([ClipItem].self, from: data) else { return }
        items = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: saveURL, options: .atomic)
    }
}
