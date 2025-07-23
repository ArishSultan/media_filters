import Foundation

public class VideoPreviewManager {
    nonisolated(unsafe) public static let instance = VideoPreviewManager()

    private let lock = NSLock()
    private var previews: [Int: VideoPreview] = [:]

    private init() {}
    
    func getCount() -> Int {
        return previews.count;
    }

    func createPreview(viewId: Int) -> VideoPreview {
        lock.lock()
        defer { lock.unlock() }
        
        if let existingPreview = previews[viewId] {
            return existingPreview
        }

        let preview = VideoPreview(id: viewId)
        previews[viewId] = preview

        return preview
    }

    func getPreview(_ viewId: Int) -> VideoPreview? {
        lock.lock()
        defer { lock.unlock() }
        return previews[viewId]
    }

    func destroyPreview(viewId: Int) {
        lock.lock()
        defer { lock.unlock() }

        if let preview = previews[viewId] {
            previews.removeValue(forKey: viewId)
            
            Task { @MainActor in
                preview.cleanup()
            }
        }
    }

    @MainActor func destroyAllPreviews() {
        lock.lock()
        defer { lock.unlock() }

        for preview in previews.values {
            preview.cleanup()
        }
        previews.removeAll()
    }
}
