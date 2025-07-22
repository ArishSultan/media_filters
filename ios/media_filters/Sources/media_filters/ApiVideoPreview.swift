import Foundation
import SwiftCube

@_cdecl("vp_create")
public func vp_create() -> Int {
    return VideoPreviewManager.instance.createPreview()
}

@MainActor @_cdecl("vp_load_video")
public func vp_load(id: Int, path: UnsafePointer<CChar>) -> Bool {
    let pathString = String(cString: path)
    
    guard let preview = VideoPreviewManager.instance.getPreview(id: id) else {
        return false
    }
    
    return preview.loadVideo(path: pathString)
}

@_cdecl("vp_load_lut_path")
public func vp_set_filter(id: Int, filterPath: UnsafePointer<CChar>) -> Bool {
//    let filterUrl = URL(fileURLWithPath: String(cString: filterPath))
//    
//    if let sc3dFilter = try? SC3DLut(contentsOf: filterUrl) {
//        if let ciFilter = try? sc3dFilter.ciFilter() {
//            guard let preview = VideoPreviewManager.instance.getPreview(id: id) else {
//                return false
//            }
//        
//            return preview.setFilter(filter: ciFilter)
//        } else {
//            print("unable to conver to CIFilter")
//            return false
//        }
//    } else {
//        print("Unable to parse the SwiftCube Filter")
//        return false
//    }
    return false
}

@_cdecl("vp_clear_filter")
public func vp_clear_filter(id: Int) -> Int {
    guard let preview = VideoPreviewManager.instance.getPreview(id: id) else {
        return 0
    }
    
//    preview.clearFilter()
    return 1
}

@_cdecl("vp_play")
public func play_video(id: Int) -> Int {
    guard let preview = VideoPreviewManager.instance.getPreview(id: id) else {
        return 0
    }
    
    Task { @MainActor in
        preview.play()
    }
    return 1
}

@_cdecl("vp_pause")
public func pause_video(id: Int) -> Int {
    guard let preview = VideoPreviewManager.instance.getPreview(id: id) else {
        return 0
    }
    
    Task { @MainActor in
        preview.pause()
    }
    return 1
}

//@_cdecl("seek_video")
//public func seek_video(id: Int, time: Double) -> Int {
//    guard let preview = VideoPreviewManager.shared.getPreview(id: id) else {
//        return 0
//    }
//    
//    preview.seek(to: time)
//    return 1
//}
//
//@_cdecl("set_video_volume")
//public func set_video_volume(id: Int, volume: Float) -> Int {
//    guard let preview = VideoPreviewManager.shared.getPreview(id: id) else {
//        return 0
//    }
//    
//    preview.setVolume(volume)
//    return 1
//}
//
//@_cdecl("set_state_callback")
//public func set_state_callback(id: Int, callback: @escaping VideoPreviewStateCallback) -> Int {
//    guard let preview = VideoPreviewManager.shared.getPreview(id: id) else {
//        return 0
//    }
//    
//    preview.setStateCallback(callback)
//    return 1
//}
//
//@_cdecl("set_progress_callback")
//public func set_progress_callback(id: Int, callback: @escaping VideoPreviewProgressCallback) -> Int {
//    guard let preview = VideoPreviewManager.shared.getPreview(id: id) else {
//        return 0
//    }
//    
//    preview.setProgressCallback(callback)
//    return 1
//}
//
//@_cdecl("set_frame_callback")
//public func set_frame_callback(id: Int, callback: @escaping VideoPreviewFrameCallback) -> Int {
//    guard let preview = VideoPreviewManager.shared.getPreview(id: id) else {
//        return 0
//    }
//    
//    preview.setFrameCallback(callback)
//    return 1
//}

@MainActor @_cdecl("vp_destroy")
public func vp_destroy(id: Int) -> Int {
    VideoPreviewManager.instance.destroyPreview(id: id)
    return 1
}
