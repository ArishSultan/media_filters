import Foundation

public class VideoPreviewManager {
    nonisolated(unsafe) public static let instance = VideoPreviewManager()

    private let lock = NSLock()
    private var previews: [Int: VideoPreview] = [:]
    private var nextPreviewId: Int = 1

    private init() {}
    
    func getCount() -> Int {
        return previews.count;
    }

    func createPreview() -> Int {
        lock.lock()
        defer { lock.unlock() }

        let previewId = nextPreviewId
        nextPreviewId += 1

        let preview = VideoPreview(id: previewId)
        previews[previewId] = preview

        return previewId
    }

    func getPreview(id: Int) -> VideoPreview? {
        lock.lock()
        defer { lock.unlock() }
        return previews[id]
    }

    @MainActor func destroyPreview(id: Int) {
        lock.lock()
        defer { lock.unlock() }

        if let preview = previews[id] {
//            preview.cleanup()
            previews.removeValue(forKey: id)
        }
    }

    @MainActor func destroyAllPreviews() {
        lock.lock()
        defer { lock.unlock() }

        for preview in previews.values {
//            preview.cleanup()
        }
        previews.removeAll()
    }
}
