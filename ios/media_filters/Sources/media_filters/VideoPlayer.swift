import Darwin.C
import UIKit
import CoreImage
import Foundation
import AVFoundation

// MARK: - Enums

/// Defines the type of video resource and its location
public enum VideoResourceType: Int {
  /// Video is located in the app's asset catalog
  case asset = 1
  /// Video is a local file on the device
  case file = 2
  /// Video is hosted on a network server
  case network = 3
}

/// Represents the various states of the video player
public enum VideoPlayerState: Int {
  /// Initial state when player is created
  case idle = 0
  /// Video is currently loading
  case loading = 1
  /// Video is ready to play
  case ready = 2
  /// Video is currently playing
  case playing = 3
  /// Video playback is paused
  case paused = 4
  /// Video playback has stopped
  case stopped = 5
  /// Video has finished playing
  case completed = 6
  /// An error occurred
  case error = 7
}

// MARK: - VideoPlayer

/// A comprehensive video player implementation for iOS applications.
///
/// This class provides a complete video playback solution with the following features:
/// - Support for multiple video sources (assets, files, network URLs)
/// - Real-time playback state monitoring
/// - Progress and duration tracking
/// - Memory-efficient player management
/// - Thread-safe operations
///
/// ## Usage Example:
/// ```swift
/// let player = VideoPlayer.create(
///     playerId: 1,
///     stateListener: { id, state in
///         print("Player \(id) state: \(state)")
///     },
///     durationListener: { id, duration in
///         print("Video duration: \(duration)ms")
///     },
///     progressListener: { id, progress in
///         print("Current progress: \(progress)ms")
///     }
/// )
///
/// player.attachView(videoContainerView)
/// player.load(locator: "sample_video.mp4", resourceType: .asset)
/// player.play()
/// ```
public final class VideoPlayer: NSObject {
  /// Unique identifier for this player instance
  private let id: Int
  
  /// Current AVPlayer instance
  private var player: AVPlayer?
  
  /// Current AVPlayerItem being played
  private var playerItem: AVPlayerItem?
  
  /// AVPlayerLayer responsible for video rendering
  private let playerLayer = AVPlayerLayer()
  
  public let mediaFilters = MediaFilters()
  
  /// Current player state
  private var state: VideoPlayerState = .idle {
    didSet { if oldValue != state { stateListener(id, state.rawValue) } }
  }
  
  /// Total video duration in milliseconds (-1 if unknown)
  private var duration: CMTime = CMTime.zero
  
  /// Current playback progress in milliseconds
  private var _progress: Int64 = 0 {
    didSet { if oldValue != _progress { progressListener(id, _progress) } }
  }
  private var progress: CMTime {
    get { return CMTime(value: _progress, timescale: 1000) }
    set {
      _progress = newValue.milliseconds
    }
  }
  
  /// Token for progress observer
  private var progressObserverToken: Any?
  
  /// Callback for state changes
  private let stateListener: IntValueCallback
  
  /// Callback for progress updates
  private let progressListener: LongValueCallback
  
  /// Initializes a new VideoPlayer instance
  /// - Parameters:
  ///   - id: Unique identifier for the player
  ///   - stateListener: Callback invoked when player state changes
  ///   - durationListener: Callback invoked when video duration is determined
  ///   - progressListener: Callback invoked periodically with playback progress
  init(
    id: Int,
    stateListener: @escaping IntValueCallback,
    progressListener: @escaping LongValueCallback,
  ) {
    self.id = id
    self.stateListener = stateListener
    self.progressListener = progressListener
    
    super.init()
  }
  
  // MARK: - Public Methods
  
  /// Attaches the video player to a UIView for rendering
  /// - Parameter view: The view to attach the player layer to
  public func attachView(_ view: UIView) {
    guard playerLayer.superlayer != view.layer else { return }
    
    playerLayer.removeFromSuperlayer()
    playerLayer.frame = view.bounds
    playerLayer.videoGravity = .resizeAspect
    view.layer.addSublayer(playerLayer)
  }
  
  /// Loads a video from the specified location
  /// - Parameters:
  ///   - locator: Path, filename, or URL of the video
  ///   - resourceType: Type of video resource (.asset, .file, or .network)
  public func load(
    locator: String,
    resourceType: VideoResourceType?,
    onLoad: VoidCallback,
    onLoadError: StringValueCallback,
  ) {
    guard let resourceType = resourceType else {
      onLoadError(id, strdup("Error: invalid resource type"))
      state = .error
      return
    }
    
    release()
    state = .loading
    
    guard let videoUrl = createURL(from: locator, type: resourceType) else {
      onLoadError(id, strdup("Error: invalid resource locator"))
      state = .error
      return
    }
    
    let asset = AVAsset(url: videoUrl)
    let playerItem = AVPlayerItem(asset: asset)
    let player = AVPlayer(playerItem: playerItem)
    
    self.playerItem = playerItem
    self.player = player
    self.playerLayer.player = player
    
    setupObservers(for: playerItem)
    setupProgressObserver()
    
    loadDurationAsync(asset, onLoad: onLoad, onLoadError: onLoadError)
  }
  
  /// Starts or resumes video playback
  public func play() {
    guard let player = player else { return }
    player.play()
    state = .playing
  }
  
  /// Pauses video playback
  public func pause() {
    guard let player = player else { return }
    player.pause()
    state = .paused
  }
  
  /// Stops video playback and resets to beginning
  public func stop() {
    guard let player = player else { return }
    player.pause()
    player.seek(to: CMTime.zero)
    state = .stopped
    progress = CMTime.zero
  }
  
  /// Seeks to a specific time in the video
  /// - Parameter timeInMilliseconds: Target time in milliseconds
  public func seek(to timeInMilliseconds: Int64) {
    guard let player = player else { return }
    let targetTime = CMTime(value: timeInMilliseconds, timescale: 1000)
    player.seek(to: targetTime)
  }
  
  public func getState() -> VideoPlayerState {
    return state
  }
  
  /// Gets the current playback time in milliseconds
  /// - Returns: Current time in milliseconds, or 0 if unavailable
  public func getCurrentTime() -> Int64 {
    guard let player = player else { return 0 }
    return player.currentTime().milliseconds
  }
  
  /// Gets the video duration in milliseconds
  /// - Returns: Duration in milliseconds, or -1 if unknown
  public func getDuration() -> Int64 {
    return duration.milliseconds
  }
  
  /// Sets the playback rate
  /// - Parameter rate: Playback rate (1.0 = normal speed)
  public func setPlaybackRate(_ rate: Float) {
    player?.rate = rate
  }
  
  /// Sets the video volume
  /// - Parameter volume: Volume level (0.0 to 1.0)
  public func setVolume(_ volume: Float) {
    player?.volume = max(0.0, min(1.0, volume))
  }
  
  // MARK: - Private Methods
  
  /// Creates a URL from the locator based on resource type
  private func createURL(from locator: String, type: VideoResourceType) -> URL? {
    switch type {
      case .file:
        return URL(fileURLWithPath: locator)
        
      case .network:
        return URL(string: locator)
        
      case .asset:
        guard let path = Bundle.main.path(forResource: locator, ofType: nil) else {
          return nil
        }
        return URL(fileURLWithPath: path)
    }
  }
  
  /// Sets up all necessary observers for the player item
  private func setupObservers(for item: AVPlayerItem) {
    // Observe player item status
    item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: .new, context: nil)
    
    // Observe playback completion
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(playerDidReachEnd),
      name: .AVPlayerItemDidPlayToEndTime,
      object: item
    )
    
    // Observe playback stalls
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(playerDidStall),
      name: .AVPlayerItemPlaybackStalled,
      object: item
    )
  }
  
  /// Sets up periodic time observer for progress updates
  private func setupProgressObserver() {
    guard let player = player else { return }
    
    let interval = CMTime(value: 100, timescale: 1000) // Update every 100ms
    progressObserverToken = player.addPeriodicTimeObserver(
      forInterval: interval,
      queue: .main
    ) { [weak self] time in
      self?.progress = time
    }
  }
  
  /// Loads video duration asynchronously
  private func loadDurationAsync(
    _ asset: AVAsset,
    onLoad: VoidCallback,
    onLoadError: StringValueCallback,
  ) {
    if #available(iOS 15.0, *) {
      Task {
        do {
          let duration = try await asset.load(.duration)
          await MainActor.run {
            self.duration = duration
            onLoad(self.id)
          }
        } catch {
          await MainActor.run {
            self.state = .error
            onLoadError(self.id, strdup("Error: loading duration failed"))
          }
        }
      }
    } else {
      asset.loadValuesAsynchronously(forKeys: ["duration"]) {
        DispatchQueue.main.async {
          var error: NSError?
          if asset.statusOfValue(forKey: "duration", error: &error) == .loaded {
            self.duration = asset.duration
            onLoad(self.id)
          } else {
            onLoadError(self.id, strdup("Error: loading duration failed"))
            self.state = .error
          }
        }
      }
    }
  }
  
  func getVideoResolution() -> CGSize? {
    guard let asset = playerItem?.asset,
          let track = asset.tracks(withMediaType: AVMediaType.video).first else {
      return nil
    }
    
    return track.naturalSize.applying(track.preferredTransform)
  }
  
  /// Releases all player resources
  private func release() {
    // Remove progress observer
    if let token = progressObserverToken, let player = player {
      player.removeTimeObserver(token)
      progressObserverToken = nil
    }
    
    // Remove KVO and notifications
    if let item = playerItem {
      item.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
      NotificationCenter.default.removeObserver(self)
    }
    
    // Clean up player
    player?.pause()
    player = nil
    playerItem = nil
    playerLayer.player = nil
    
    // Reset state
    duration = CMTime.zero
    _progress = 0
    state = .idle
  }
  
  // MARK: - Observer Methods
  
  /// Handles KVO notifications
  override public func observeValue(
    forKeyPath keyPath: String?,
    of object: Any?,
    change: [NSKeyValueChangeKey : Any]?,
    context: UnsafeMutableRawPointer?
  ) {
    if keyPath == #keyPath(AVPlayerItem.status) {
      guard let item = object as? AVPlayerItem else { return }
      
      switch item.status {
        case .readyToPlay:
          state = .ready
        case .failed:
          state = .error
        case .unknown:
          break
        @unknown default:
          break
      }
    }
  }
  
  /// Called when video playback reaches the end
  @objc private func playerDidReachEnd() {
    state = .completed
  }
  
  /// Called when video playback stalls
  @objc private func playerDidStall() {
    state = .loading
  }
  
  public func applyFilter() {
    guard let playerItem = self.playerItem else {
      return
    }
    
    let filter: CIFilter = mediaFilters.ciFilter
    
    playerItem.videoComposition = AVVideoComposition(asset: playerItem.asset) { [weak self] request in
      guard let self = self else {
        request.finish(with: request.sourceImage, context: nil)
        return
      }
      
      filter.setValue(request.sourceImage, forKey: kCIInputImageKey)
      
      if let filteredImage = filter.outputImage {
        request.finish(with: filteredImage, context: nil)
      } else {
        request.finish(with: request.sourceImage, context: nil)
      }
    }
  }
}


// MARK: - Static Player Management

extension VideoPlayer {
  /// Thread-safe lock for player management
  private static let lock = NSLock()
  
  /// Dictionary storing all active player instances
  private static var players: [Int: VideoPlayer] = [:]
  
  /// Returns the number of active player instances
  public static var count: Int {
    lock.lock()
    defer { lock.unlock() }
    return players.count
  }
  
  /// Creates or retrieves a VideoPlayer instance
  /// - Parameters:
  ///   - playerId: Unique identifier for the player
  ///   - progressListener: Callback for progress updates
  /// - Returns: VideoPlayer instance (existing or newly created)
  public static func create(
    playerId: Int,
    stateListener: @escaping IntValueCallback,
    progressListener: @escaping LongValueCallback,
  ) -> VideoPlayer {
    lock.lock()
    defer { lock.unlock() }
    
    if let existingPlayer = players[playerId] {
      return existingPlayer
    }
    
    let newPlayer = VideoPlayer(
      id: playerId,
      stateListener: stateListener,
      progressListener: progressListener,
    )
    
    players[playerId] = newPlayer
    return newPlayer
  }
  
  /// Retrieves an existing player instance
  /// - Parameter playerId: Unique identifier of the player
  /// - Returns: VideoPlayer instance if found, nil otherwise
  public static func get(_ playerId: Int) -> VideoPlayer? {
    lock.lock()
    defer { lock.unlock() }
    return players[playerId]
  }
  
  /// Removes a specific player instance and releases its resources
  /// - Parameter playerId: Unique identifier of the player to remove
  public static func remove(_ playerId: Int) {
    lock.lock()
    let playerToRemove = players.removeValue(forKey: playerId)
    lock.unlock()
    
    if let player = playerToRemove {
      DispatchQueue.main.async {
        player.release()
      }
    }
  }
  
  /// Removes all player instances and releases their resources
  public static func removeAll() {
    lock.lock()
    let allPlayers = Array(players.values)
    players.removeAll()
    lock.unlock()
    
    if !allPlayers.isEmpty {
      DispatchQueue.main.async {
        for player in allPlayers {
          player.release()
        }
      }
    }
  }
}

// MARK: - CMTime Extension

extension CMTime {
  /// Converts CMTime to milliseconds
  /// - Returns: Time value in milliseconds
  public var milliseconds: Int64 {
    return Int64(CMTimeGetSeconds(self) * 1000)
  }
}
