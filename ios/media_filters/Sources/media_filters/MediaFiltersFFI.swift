import Darwin.C
import Foundation

// MARK: - Callbacks
public typealias VoidCallback = @convention(c) (Int) -> Void
public typealias IntValueCallback = @convention(c) (Int, Int) -> Void
public typealias LongValueCallback = @convention(c) (Int, Int64) -> Void
public typealias FloatValueCallback = @convention(c) (Int, Float) -> Void
public typealias DoubleValueCallback = @convention(c) (Int, Double) -> Void
public typealias StringValueCallback = @convention(c) (Int, UnsafePointer<CChar>) -> Void


struct CSize {
  let width: Double
  let height: Double
}

// MARK: - Video Player API

///
@_cdecl("vpPrepare")
func vpCreate(
  playerId: Int,
  stateListener: IntValueCallback,
  progressListener: LongValueCallback,
) {
  VideoPlayer.prepare(
    playerId: playerId,
    stateListener: stateListener,
    progressListener: progressListener,
  );
}

///
@_cdecl("vpRelease")
func vpRelease(playerId: Int) {
  VideoPlayer.release(playerId)
}

///
@_cdecl("vpState")
func vpState(playerId: Int) -> Int {
  VideoPlayer.get(playerId)?.getState().rawValue ?? 0
}

///
@_cdecl("vpApplyFilter")
func vpApplyFilter(playerId: Int) {
  VideoPlayer.get(playerId)?.applyFilter()
}

///
@_cdecl("vpSize")
func vpSize(playerId: Int) -> UnsafeMutableRawPointer {
  let sizePtr = UnsafeMutablePointer<CSize>.allocate(capacity: 1)
  if let resolution = VideoPlayer.get(playerId)?.getVideoResolution() {
    print("i am here, \(resolution)")
    sizePtr.pointee = CSize(width: resolution.width, height: resolution.height)
  }
  
  return UnsafeMutableRawPointer(sizePtr)
}

///
@_cdecl("vpDuration")
func vpDuration(playerId: Int) -> Int64 {
  VideoPlayer.get(playerId)?.getDuration() ?? -1
}

///
@_cdecl("vpProgress")
func vpProgress(playerId: Int) -> Int64 {
  VideoPlayer.get(playerId)?.getCurrentTime() ?? -1
}

///
@_cdecl("vpLoad")
public func vpLoad(
  playerId: Int,
  resourceType: Int,
  resource: UnsafePointer<CChar>,
  onLoad: VoidCallback,
  onLoadError: StringValueCallback,
) {
  guard let player = VideoPlayer.get(playerId) else { return }
  
  return player.load(
    locator: String(cString: resource),
    resourceType: VideoResourceType(rawValue: resourceType),
    onLoad: onLoad,
    onLoadError: onLoadError,
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

@_cdecl("vpSetLutFilter")
public func vpLoadLutFilter(playerId: Int, resource: UnsafePointer<CChar>) {
  guard let player = VideoPlayer.get(playerId) else {
    return
  }
  
  let lutUrl = URL(fileURLWithPath: String(cString: resource))
  player.mediaFilters.loadLutFilter(lutUrl: lutUrl)
}

@_cdecl("vpRemoveLutFilter")
public func vpRemoveLutFilter(playerId: Int) {
  VideoPlayer.get(playerId)?.mediaFilters.unloadLutFilter()
}

@_cdecl("vpSetExposureFilter")
public func vpSetExposure(playerId: Int, value: Float) {
  VideoPlayer.get(playerId)?.mediaFilters.exposure = value
}

@_cdecl("vpSetContrastFilter")
public func vpSetContrast(playerId: Int, value: Float) {
  VideoPlayer.get(playerId)?.mediaFilters.contrast = value
}

@_cdecl("vpSetSaturationFilter")
public func vpSetSaturation(playerId: Int, value: Float) {
  VideoPlayer.get(playerId)?.mediaFilters.saturation = value
}

@_cdecl("vpSetTemperatureFilter")
public func vpSetTemperature(playerId: Int, value: Float) {
  VideoPlayer.get(playerId)?.mediaFilters.temperature = value
}

@_cdecl("vpSetTintFilter")
public func vpSetTint(playerId: Int, value: Float) {
  VideoPlayer.get(playerId)?.mediaFilters.tint = value
}

@_cdecl("transformVideo")
func transformVideo(
  id: Int,
  
  //
  width: Float,
  height: Float,
  preserveAspectRatio: Bool,
  
  //
  tint: Float,
  contrast: Float,
  exposure: Float,
  saturation: Float,
  temperature: Float,
  
  //
  lutFile: UnsafePointer<CChar>?,
  srcFile: UnsafePointer<CChar>,
  dstFile: UnsafePointer<CChar>,
  
  //
  onProgress: FloatValueCallback,
  onCompletion: VoidCallback,
  onError: StringValueCallback,
) {
  let filters = MediaFilters()
  
  if lutFile != nil {
    let lutUrl = URL(fileURLWithPath: String(cString: lutFile!))
    filters.loadLutFilter(lutUrl: lutUrl)
  }
  
  filters.contrast = contrast
  filters.saturation = saturation
  filters.exposure = exposure
  filters.temperature = temperature
  filters.tint = tint
  
  VideoTransformer.transform(
    id: id,
    
    width: width,
    height: height,
    preserveAspectRatio: preserveAspectRatio,
    
    srcUrl: URL(fileURLWithPath: String(cString: srcFile)),
    dstUrl: URL(fileURLWithPath: String(cString: dstFile)),
    filters: filters,
    
    onProgress: onProgress,
    onCompletion: onCompletion,
    onError: onError,
  )
}
