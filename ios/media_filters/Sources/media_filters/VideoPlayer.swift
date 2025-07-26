import UIKit
import AVFoundation

// MARK: - Type Aliases for Callbacks

public typealias IntegerValueCallback = @convention(c) (Int, Int) -> Void

public typealias LongValueCallback = @convention(c) (Int, Int64) -> Void


// MARK: - VideoPlayerState

/// Represents the various states of the video player.
public enum VideoPlayerState: Int {
  /// Player is stopped or has not started. Initial state.
  case stopped = 0
  /// Player is actively playing.
  case playing = 1
  /// Player is paused.
  case paused = 2
  /// Player has reached the end of the media.
  case ended = 3
  /// An error occurred during loading or playback.
  case error = 4
}

// MARK: - VideoPlayer

/// A robust and efficient class for managing video playback within a `UIView`.
///
/// `VideoPlayer` encapsulates the complexity of `AVFoundation`, providing a simple interface
/// for loading, controlling, and observing video playback. It uses callbacks to communicate
/// its state, duration, and progress, making it easy to integrate into various application
/// architectures.
public final class VideoPlayer: NSObject {
  
  // MARK: - Public Properties
  
  /// The unique identifier for this video player instance.
  public let id: Int
  
  // MARK: - Private Properties
  
  /// The core `AVFoundation` layer that renders the video content.
  private let playerLayer = AVPlayerLayer()
  
  /// The underlying player responsible for managing playback.
  private var player: AVPlayer?
  
  /// The current media item being played.
  private var playerItem: AVPlayerItem?
  
  /// The total duration of the current video. Stored to avoid repeated access.
  private var videoDuration: CMTime?
  
  /// An observer token for tracking playback progress. Must be retained and released.
  private var timeObserverToken: Any?
  
  // MARK: - Callbacks
  
  /// A closure that is called whenever the player's state changes.
  private var stateCallback: IntegerValueCallback?
  
  /// A closure that is called once the video's duration is loaded.
  private var durationCallback: LongValueCallback?
  
  /// A closure that is called periodically during playback to report progress.
  private var progressCallback: LongValueCallback?
  
  // MARK: - Initialization & Deinitialization
  
  /// Initializes a new `VideoPlayer` with a unique identifier.
  /// - Parameter id: An integer to uniquely identify this player instance.
  public init(id: Int) {
    self.id = id
    super.init()
    // Ensure the video is scaled to fill the layer's bounds while maintaining aspect ratio.
    playerLayer.videoGravity = .resizeAspectFill
  }
  
  deinit {
    // Ensure all resources are released when the object is deallocated.
    cleanup()
  }
  
  // MARK: - Public API
  
  /// Attaches the video player's output to a specified `UIView`.
  ///
  /// This method adds the player's `AVPlayerLayer` as a sublayer to the provided view,
  /// allowing the video to be rendered. The layer's frame will need to be managed
  /// separately to match the view's bounds.
  /// - Parameter view: The `UIView` where the video will be displayed.
  public func attachToView(_ view: UIView) {
    // Ensure we are on the main thread for UI operations.
    DispatchQueue.main.async {
      // Avoid re-adding the layer if it's already attached to the same view.
      if self.playerLayer.superlayer == view.layer {
        return
      }
      // Add the player layer to the view's layer hierarchy.
      view.layer.addSublayer(self.playerLayer)
    }
  }
  
  /// Sets the callbacks for player state, duration, and progress updates.
  /// - Parameters:
  ///   - stateCallback: The closure to call when the player's state changes.
  ///   - durationCallback: The closure to call when the video duration is available.
  ///   - progressCallback: The closure to call for playback progress updates.
  public func setCallbacks(
    stateCallback: IntegerValueCallback?,
    durationCallback: LongValueCallback?,
    progressCallback: LongValueCallback?
  ) {
    self.stateCallback = stateCallback
    self.durationCallback = durationCallback
    self.progressCallback = progressCallback
  }
  
  /// Loads a video from a given URL and prepares it for playback.
  ///
  /// This method performs a full cleanup of any existing media before loading the new one.
  /// It sets up the necessary player items, observers, and loads the video's duration.
  /// - Parameter url: The `URL` of the video file to load.
  public func loadVideo(from url: URL) {
    cleanup() // Clean up previous player state before loading new media.
    
    let asset = AVAsset(url: url)
    playerItem = AVPlayerItem(asset: asset)
    
    guard let playerItem = self.playerItem else {
      notifyState(.error)
      return
    }
    
    player = AVPlayer(playerItem: playerItem)
    playerLayer.player = player
    
    // Load duration asynchronously.
    loadDuration(from: asset)
    
    // Set up observers for playback events.
    setupObservers(for: playerItem)
    setupTimeObserver()
    
    notifyState(.stopped)
    notifyProgress(CMTime.zero)
  }
  
  /// Starts or resumes video playback.
  public func play() {
    guard let player = player, player.timeControlStatus != .playing else { return }
    player.play()
    notifyState(.playing)
  }
  
  /// Pauses video playback.
  public func pause() {
    guard let player = player, player.timeControlStatus != .paused else { return }
    player.pause()
    notifyState(.paused)
  }
  
  /// Seeks to a specific time in the video.
  /// - Parameter time: The time to seek to, in seconds.
  public func seek(to time: Int64) {
    guard let player = player else { return }
    let seekTime = CMTime(value: time, timescale: 1000)
    player.seek(to: seekTime, toleranceBefore: .zero, toleranceAfter: .zero)
  }
  
  /// Updates the frame of the player layer. Call this when the container view's layout changes.
  /// - Parameter frame: The new frame for the video layer.
  public func updateFrame(_ frame: CGRect) {
    DispatchQueue.main.async {
      self.playerLayer.frame = frame
    }
  }
  
  /// Tears down the player and removes its layer from its superlayer.
  /// This should be called when the player is no longer needed to ensure proper cleanup.
  public func destroy() {
    cleanup()
    DispatchQueue.main.async {
      self.playerLayer.removeFromSuperlayer()
    }
  }
  
  // MARK: - Private Helper Methods
  
  /// Loads the duration of an asset asynchronously and notifies the duration callback.
  /// Uses modern `async/await` on iOS 15+ and falls back to a completion handler for older versions.
  private func loadDuration(from asset: AVAsset) {
    if #available(iOS 15.0, *) {
      Task {
        do {
          let duration = try await asset.load(.duration)
          await MainActor.run {
            self.videoDuration = duration
            self.notifyDuration(duration)
          }
        } catch {
          await MainActor.run { self.notifyState(.error) }
        }
      }
    } else {
      // Fallback for older iOS versions
      asset.loadValuesAsynchronously(forKeys: ["duration"]) {
        DispatchQueue.main.async {
          var error: NSError?
          let status = asset.statusOfValue(forKey: "duration", error: &error)
          if status == .loaded {
            self.videoDuration = asset.duration
            self.notifyDuration(asset.duration)
          } else {
            self.notifyState(.error)
          }
        }
      }
    }
  }
  
  /// Sets up KVO for player item status and a notification for when the item plays to its end.
  private func setupObservers(for item: AVPlayerItem) {
    // Observe the item's status to know when it's ready to play or if it failed.
    item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: .new, context: nil)
    
    // Observe when the player item reaches its end time.
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(playerDidReachEnd),
      name: .AVPlayerItemDidPlayToEndTime,
      object: item
    )
  }
  
  /// Sets up a periodic time observer to notify the progress callback.
  private func setupTimeObserver() {
    guard let player = self.player else { return }
    // Notify every 100ms.
    let interval = CMTime(value: 100, timescale: 1000)
    
    timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
      guard let self = self else { return }
      self.notifyProgress(time)
    }
  }
  
  /// Releases all observers and player resources to prevent memory leaks.
  public func cleanup() {
    // Remove the time observer if it exists.
    if let token = timeObserverToken, let player = self.player {
      player.removeTimeObserver(token)
      self.timeObserverToken = nil
    }
    
    // Remove KVO and NotificationCenter observers from the current player item.
    if let item = self.playerItem {
      item.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
      NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: item)
    }
    
    // Pause the player and release its resources.
    player?.pause()
    player = nil
    playerItem = nil
    playerLayer.player = nil
    videoDuration = nil
  }
  
  // MARK: - KVO & Notification Handlers
  
  /// Called when the player item finishes playing.
  @objc private func playerDidReachEnd() {
    notifyState(.ended)
  }
  
  /// Handles changes to the observed `playerItem.status` key path.
  public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    guard keyPath == #keyPath(AVPlayerItem.status),
          let item = object as? AVPlayerItem else {
      super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
      return
    }
    
    switch item.status {
      case .readyToPlay:
        // Player is ready, but we don't change the state until `play()` is called.
        break
      case .failed:
        // An error occurred.
        notifyState(.error)
      case .unknown:
        // Status is not yet known.
        break
      @unknown default:
        break
    }
  }
  
  // MARK: - Callback Notifiers
  
  /// Invokes the state callback with the new state.
  private func notifyState(_ state: VideoPlayerState) {
    stateCallback?(id, state.rawValue)
  }
  
  /// Invokes the duration callback with the loaded duration.
  private func notifyDuration(_ duration: CMTime) {
    if duration.isPositiveInfinity || duration.isNegativeInfinity || duration.isIndefinite {
      return
    }
    
    durationCallback?(id, duration.convertScale(1000, method: .quickTime).value)
  }
  
  /// Invokes the progress callback with the current playback time.
  private func notifyProgress(_ progress: CMTime) {
    guard let duration = videoDuration?.convertScale(1000, method: .quickTime).value else {
      return
    }

    if progress.isPositiveInfinity || progress.isNegativeInfinity || progress.isIndefinite {
      return
    }
    
    // Clamp progress to the duration to avoid reporting times beyond the end.
    progressCallback?(id, min(progress.convertScale(1000, method: .quickTime).value, duration))
  }
}
