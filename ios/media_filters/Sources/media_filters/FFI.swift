import Foundation
import UIKit

// MARK: - VideoResourceType

/// Defines the source type of the video resource to be loaded.
public enum VideoResourceType: Int {
  /// Video is located in the app's asset catalog.
  case asset = 1
  /// Video is a local file on the device.
  case file = 2
  /// Video is hosted on a network server.
  case network = 3
}

// MARK: - VideoPlayerFFI

/// Loads a video for a specific player from a given resource.
/// - Parameters:
///   - playerId: The ID of the player that will load the video.
///   - resource: A C-string representing the path, URL, or asset name.
///   - resourceType: The type of the resource, defined by `VideoResourceType`.
@_cdecl("vpLoadVideo")
public func vpLoadVideo(playerId: Int, resource: UnsafePointer<CChar>, resourceType: Int) {
  guard let player = VideoPlayersManager.get(playerId) else { return }
  
  let resourceStr = String(cString: resource)
  let type = VideoResourceType(rawValue: resourceType) ?? .file
  var videoURL: URL?

  switch type {
    case .file:
      videoURL = URL(fileURLWithPath: resourceStr)
    case .network:
      videoURL = URL(string: resourceStr)
    case .asset:
      // Assumes the asset is in the main bundle. Adjust if your assets are located elsewhere.
      if let path = Bundle.main.path(forResource: resourceStr, ofType: nil) {
        videoURL = URL(fileURLWithPath: path)
      }
  }
  
  guard let url = videoURL else {
    print("VideoPlayerFFI Error: Could not construct URL for resource '\(resourceStr)'")
    return
  }
  
  player.loadVideo(from: url)
}

/// Starts or resumes playback for the specified player.
/// - Parameter playerId: The ID of the player to play.
@_cdecl("vpPlay")
public func vpPlay(playerId: Int) {
  VideoPlayersManager.get(playerId)?.play()
}

/// Pauses playback for the specified player.
/// - Parameter playerId: The ID of the player to pause.
@_cdecl("vpPause")
public func vpPause(playerId: Int) {
  VideoPlayersManager.get(playerId)?.pause()
}

/// Seeks to a specific time in the video for the specified player.
/// - Parameters:
///   - playerId: The ID of the player to seek.
///   - time: The time to seek to, in seconds.
@_cdecl("vpSeek")
public func vpSeek(playerId: Int, time: Int64) {
  VideoPlayersManager.get(playerId)?.seek(to: time)
}

/// Sets the state, duration, and progress callbacks for a specific player.
/// - Parameters:
///   - playerId: The ID of the player.
///   - stateCallback: The C-function to call on state changes.
///   - durationCallback: The C-function to call when duration is available.
///   - progressCallback: The C-function to call for progress updates.
@_cdecl("vpSetCallbacks")
public func vpSetCallbacks(
  playerId: Int,
  stateCallback: @escaping IntegerValueCallback,
  durationCallback: @escaping LongValueCallback,
  progressCallback: @escaping LongValueCallback,
) {
  guard let player = VideoPlayersManager.get(playerId) else { return }
  
  player.setCallbacks(
    stateCallback: stateCallback,
    durationCallback: durationCallback,
    progressCallback: progressCallback
  )
}

@_cdecl("vpRemoveCallbacks")
public func vpRemoveCallbacks(playerId: Int) {
  guard let player = VideoPlayersManager.get(playerId) else { return }
  
  player.setCallbacks(
    stateCallback: nil,
    durationCallback: nil,
    progressCallback: nil,
  )
}


// MARK: - Filters

@_cdecl("vpLoadLutFilter")
public func vpLoadLutFilter(playerId: Int, resource: UnsafePointer<CChar>) {
  VideoPlayersManager.get(playerId)?.loadLutFilter(String(cString: resource))
}

@_cdecl("vpRemoveLutFilter")
public func vpRemoveLutFilter(playerId: Int) {
  VideoPlayersManager.get(playerId)?.removeLutFilter()
}

@_cdecl("vpSetExposure")
public func vpSetExposure(playerId: Int, value: Float) {
  VideoPlayersManager.get(playerId)?.setExposure(value)
}

@_cdecl("vpSetContrast")
public func vpSetContrast(playerId: Int, value: Float) {
  VideoPlayersManager.get(playerId)?.setContrast(value)
}

@_cdecl("vpSetSaturation")
public func vpSetSaturation(playerId: Int, value: Float) {
  VideoPlayersManager.get(playerId)?.setSaturation(value)
}

@_cdecl("vpSetTemperature")
public func vpSetTemperature(playerId: Int, value: Float) {
  VideoPlayersManager.get(playerId)?.setTemperature(value)
}

@_cdecl("vpSetTint")
public func vpSetTint(playerId: Int, value: Float) {
  VideoPlayersManager.get(playerId)?.setTint(value)
}
