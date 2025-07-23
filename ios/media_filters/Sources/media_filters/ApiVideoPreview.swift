import SwiftCube
import Foundation

///
@_cdecl("vpLoadVideoFile")
@MainActor public func vpLoadVideoFile(viewId: Int, path: UnsafePointer<CChar>) -> Int {
    guard let preview = VideoPreviewManager.instance.getPreview(viewId) else {
        return FFIErrorCodes.VideoPreviewNotFound
    }
    
    return preview.loadVideoFile(path: String(cString: path))
}

///
@_cdecl("vpLoadFilterFile")
@MainActor public func vpLoadFilterFile(viewId: Int, path: UnsafePointer<CChar>) -> Int {
    guard let preview = VideoPreviewManager.instance.getPreview(viewId) else {
        return FFIErrorCodes.VideoPreviewNotFound
    }
    
    return preview.loadFilterFromFile(path: String(cString: path))
}

///
@_cdecl("vpClearFilter")
@MainActor public func vpClearFilter(viewId: Int) -> Int {
    guard let preview = VideoPreviewManager.instance.getPreview(viewId) else {
        return FFIErrorCodes.VideoPreviewNotFound
    }

    preview.removeFilter()
    return 0
}

///
@_cdecl("vpPlay")
public func vpPlay(viewId: Int) -> Int {
    guard let preview = VideoPreviewManager.instance.getPreview(viewId) else {
        return FFIErrorCodes.VideoPreviewNotFound
    }

    Task { @MainActor in
        preview.play()
    }

    return 0
}

///
@_cdecl("vpPause")
public func vpPause(viewId: Int) -> Int {
    guard let preview = VideoPreviewManager.instance.getPreview(viewId) else {
        return FFIErrorCodes.VideoPreviewNotFound
    }

    Task { @MainActor in
        preview.pause()
    }

    return 0
}

///
@_cdecl("vpSeek")
public func vpSeek(viewId: Int, time: Int64) -> Int {
    guard let preview = VideoPreviewManager.instance.getPreview(viewId) else {
        return FFIErrorCodes.VideoPreviewNotFound
    }

    Task { @MainActor in
        preview.seek(to: time)
    }

    return 0
}

///
@_cdecl("vpSetStateCallback")
public func vpSetStateCallback(
    viewId: Int,
    stateCallback: @escaping VideoPreviewStateCallback,
    progressCallback: @escaping VideoPreviewProgressCallback,
    durationCallback: @escaping VideoPreviewDurationCallback
) -> Int {
    guard let preview = VideoPreviewManager.instance.getPreview(viewId) else {
        return FFIErrorCodes.VideoPreviewNotFound
    }

    preview.setStateCallbacks(
        stateCallback: stateCallback,
        progressCallback: progressCallback,
        durationCallback: durationCallback,
    )

    return 0
}

///
@_cdecl("vpRemoveStateCallback")
public func vpRemoveStateCallback(viewId: Int) -> Int {
    guard let preview = VideoPreviewManager.instance.getPreview(viewId) else {
        return FFIErrorCodes.VideoPreviewNotFound
    }

    preview.setStateCallbacks(stateCallback: nil, progressCallback: nil, durationCallback: nil)

    return 0
}
