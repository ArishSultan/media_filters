import Foundation
import SwiftCube

// MARK: - Callbacks
public typealias VoidCallback = @convention(c) (Int) -> Void
public typealias IntValueCallback = @convention(c) (Int, Int) -> Void
public typealias LongValueCallback = @convention(c) (Int, Int64) -> Void
public typealias FloatValueCallback = @convention(c) (Int, Float) -> Void
public typealias DoubleValueCallback = @convention(c) (Int, Double) -> Void

// MARK: - Video Player API

///
@_cdecl("vpCreate")
func vpCreate(
  playerId: Int,
  stateListener: IntValueCallback,
  durationListener: LongValueCallback,
  progressListener: LongValueCallback,
  aspectRatioListener: DoubleValueCallback,
) {
  VideoPlayer.create(
    playerId: playerId,
    stateListener: stateListener,
    durationListener: durationListener,
    progressListener: progressListener,
    aspectRatioListener: aspectRatioListener,
  );
}

///
@_cdecl("vpRemove")
func vpRemove(playerId: Int) {
  VideoPlayer.remove(playerId)
}

///
@_cdecl("vpLoad")
public func vpLoad(playerId: Int, resourceType: Int, resource: UnsafePointer<CChar>) {
  guard let player = VideoPlayer.get(playerId) else { return }

  return player.load(
    locator: String(cString: resource),
    resourceType: VideoResourceType(rawValue: resourceType)
  )
}

///
@_cdecl("vpSeek")
public func vpSeek(playerId: Int, position: Int64) {
  VideoPlayer.get(playerId)?.seek(to: position)
}

///
@_cdecl("vpPlay")
public func vpPlay(playerId: Int) {
  VideoPlayer.get(playerId)?.play()
}

///
@_cdecl("vpPause")
public func vpPause(playerId: Int) {
  VideoPlayer.get(playerId)?.pause()
}

@_cdecl("vpLoadLutFilter")
public func vpLoadLutFilter(playerId: Int, resource: UnsafePointer<CChar>) {
  guard let player = VideoPlayer.get(playerId) else {
    return
  }
  
  let url = URL(fileURLWithPath: String(cString: resource))
  
  guard let sc3dFilter = try? SC3DLut(contentsOf: url),
        let ciFilter = try? sc3dFilter.ciFilter() else {
    player.mediaFilters.lutFilter = nil
    return
  }
  
  player.mediaFilters.lutFilter = ciFilter
}

@_cdecl("vpRemoveLutFilter")
public func vpRemoveLutFilter(playerId: Int) {
  VideoPlayer.get(playerId)?.mediaFilters.lutFilter = nil
}

@_cdecl("vpSetExposure")
public func vpSetExposure(playerId: Int, value: Float) {
  VideoPlayer.get(playerId)?.mediaFilters.exposure = value
}

@_cdecl("vpSetContrast")
public func vpSetContrast(playerId: Int, value: Float) {
  VideoPlayer.get(playerId)?.mediaFilters.contrast = value
}

@_cdecl("vpSetSaturation")
public func vpSetSaturation(playerId: Int, value: Float) {
  VideoPlayer.get(playerId)?.mediaFilters.saturation = value
}

@_cdecl("vpSetTemperature")
public func vpSetTemperature(playerId: Int, value: Float) {
  VideoPlayer.get(playerId)?.mediaFilters.temperature = value
}

@_cdecl("vpSetTint")
public func vpSetTint(playerId: Int, value: Float) {
  VideoPlayer.get(playerId)?.mediaFilters.tint = value
}

@_cdecl("exportVideo")
func exportVideoWithFilters(
  id: Int,
  input: UnsafePointer<CChar>,
  output: UnsafePointer<CChar>,
  filter: UnsafePointer<CChar>?,
  contrast: Float,
  saturation: Float,
  exposure: Float,
  temperature: Float,
  tint: Float,
  onProgress: FloatValueCallback,
  onCompletion: VoidCallback,
) {
  let filters = MediaFilters()
  
  if filter != nil {
    let lutUrl = URL(fileURLWithPath: String(cString: filter!))
    
    guard let sc3dFilter = try? SC3DLut(contentsOf: lutUrl),
          let ciFilter = try? sc3dFilter.ciFilter() else {
      filters.lutFilter = nil
      return
    }
    
    filters.lutFilter = ciFilter
  }
  
  filters.contrast = contrast
  filters.saturation = saturation
  filters.exposure = exposure
  filters.temperature = temperature
  filters.tint = tint
  
  let exporter = VideoExporter(
    inputURL: URL(fileURLWithPath: String(cString: input)),
    outputURL: URL(fileURLWithPath: String(cString: output)),
    mediaFilters: filters
  )
  
  // 3. Set progress and completion handlers
  exporter.progressHandler = { progress in
    onProgress(id, progress)
  }
  
  exporter.completionHandler = { result in
    switch result {
      case .success:
        onCompletion(id)
        print("Export completed successfully! Video saved to: \(output)")
      case .failure(let error):
        print("Export failed: \(error.localizedDescription)")
    }
  }
  
  exporter.export()
}
