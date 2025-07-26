import UIKit
import AVFoundation
import CoreImage
import SwiftCube

// MARK: - Type Aliases for Callbacks

/// A C-compatible callback that receives the player's ID and a corresponding integer value.
public typealias IntegerValueCallback = @convention(c) (Int, Int) -> Void

/// A C-compatible callback that receives the player's ID and a corresponding 64-bit integer value, typically for time in milliseconds.
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

/// A robust and efficient class for managing video playback with a chain of Core Image filters.
public final class VideoPlayer: NSObject {
  
  // MARK: - Public Properties
  
  public let id: Int
  
  // MARK: - Private Player Properties
  
  private let playerLayer = AVPlayerLayer()
  private var player: AVPlayer?
  private var playerItem: AVPlayerItem?
  private var videoDuration: CMTime?
  private var timeObserverToken: Any?
  
  /// The final, combined CIFilter that will be applied to the video.
  private var filters: Filters = Filters()
  
  // MARK: - Callbacks
  
  private var stateCallback: IntegerValueCallback?
  private var durationCallback: LongValueCallback?
  private var progressCallback: LongValueCallback?
  
  // MARK: - Initialization & Deinitialization
  
  public init(id: Int) {
    self.id = id
    super.init()
    playerLayer.videoGravity = .resizeAspectFill
    resetFilterDefaults()
  }
  
  deinit {
    cleanup()
  }
  
  // MARK: - Public API
  
  public func attachToView(_ view: UIView) {
    DispatchQueue.main.async {
      if self.playerLayer.superlayer == view.layer { return }
      view.layer.addSublayer(self.playerLayer)
    }
  }
  
  public func setCallbacks(
    stateCallback: IntegerValueCallback?,
    durationCallback: LongValueCallback?,
    progressCallback: LongValueCallback?
  ) {
    self.stateCallback = stateCallback
    self.durationCallback = durationCallback
    self.progressCallback = progressCallback
  }
  
  public func loadVideo(from url: URL) {
    cleanup()
    
    let asset = AVAsset(url: url)
    playerItem = AVPlayerItem(asset: asset)
    
    guard let playerItem = self.playerItem else {
      notifyState(.error)
      return
    }
    
    player = AVPlayer(playerItem: playerItem)
    playerLayer.player = player
    
    loadDuration(from: asset)
    setupObservers(for: playerItem)
    setupTimeObserver()
    
    // Apply any existing filters to the new video item.
    updateAndApplyCompositeFilter()
    
    notifyState(.stopped)
    notifyProgress(CMTime.zero)
  }
  
  public func play() {
    guard let player = player, player.timeControlStatus != .playing else { return }
    player.play()
    notifyState(.playing)
  }
  
  public func pause() {
    guard let player = player, player.timeControlStatus != .paused else { return }
    player.pause()
    notifyState(.paused)
  }
  
  public func seek(to time: Int64) {
    guard let player = player else { return }
    let seekTime = CMTime(value: time, timescale: 1000)
    player.seek(to: seekTime, toleranceBefore: .zero, toleranceAfter: .zero)
  }
  
  public func updateFrame(_ frame: CGRect) {
    DispatchQueue.main.async {
      self.playerLayer.frame = frame
    }
  }
  
  public func destroy() {
    cleanup()
    DispatchQueue.main.async {
      self.playerLayer.removeFromSuperlayer()
    }
  }
  
  // MARK: - Filter Control API
  
  /// Loads a LUT (Look-Up Table) filter from a file path.
  public func loadLutFilter(_ path: String) {
    let url = URL(fileURLWithPath: path)
    
    // For simplicity, this example assumes SC3DLut is available.
    // Replace with your actual LUT loading mechanism if it's different.
    guard let sc3dFilter = try? SC3DLut(contentsOf: url),
          let ciFilter = try? sc3dFilter.ciFilter() else {
      print("❌ Failed to load LUT filter from path: \(path)")
      self.filters.lutFilter = nil
      updateAndApplyCompositeFilter()
      return
    }
    
    self.filters.lutFilter = ciFilter
    updateAndApplyCompositeFilter()
  }
  
  /// Removes the currently applied LUT filter.
  public func removeLutFilter() {
    if self.filters.lutFilter != nil {
      self.filters.lutFilter = nil
      updateAndApplyCompositeFilter()
    }
  }
  
  /// Sets the exposure level.
  /// - Parameter value: A float value. Typical range is -10.0 to 10.0. Default is 0.0.
  public func setExposure(_ value: Float) {
    filters.exposure.value = value
    updateAndApplyCompositeFilter()
  }
  
  /// Sets the contrast level.
  /// - Parameter value: A float value. Typical range is 0.0 to 4.0. Default is 1.0.
  public func setContrast(_ value: Float) {
    filters.contrast.value = value
    updateAndApplyCompositeFilter()
  }
  
  /// Sets the saturation level.
  /// - Parameter value: A float value. Typical range is 0.0 to 2.0. Default is 1.0.
  public func setSaturation(_ value: Float) {
    filters.saturation.value = value
    updateAndApplyCompositeFilter()
  }
  
  /// Sets the color temperature.
  /// - Parameter value: A float value. Typical range is 2000 to 10000. Default is 6500.
  public func setTemperature(_ value: Float) {
    filters.temperature.value = value
    updateAndApplyCompositeFilter()
  }
  
  /// Sets the color tint.
  /// - Parameter value: A float value. Typical range is -200 to 200. Default is 0.
  public func setTint(_ value: Float) {
    filters.tint.value = value
    updateAndApplyCompositeFilter()
  }
  
  // MARK: - Private Filter Management
  
  /// Resets all filter parameters to their neutral default values.
  private func resetFilterDefaults() {
    self.filters.exposure.value = 0.0
    self.filters.contrast.value = 1.0
    self.filters.saturation.value = 1.0
    self.filters.temperature.value = 6500
    self.filters.tint.value = 0.0
    self.filters.lutFilter = nil
  }
  
  /// Chains all active filters together and applies the result to the video item.
  private func updateAndApplyCompositeFilter() {
    applyCompositeFilterToPlayerItem()
  }
  
  /// Applies the final composite filter to the current AVPlayerItem's videoComposition.
  private func applyCompositeFilterToPlayerItem() {
    guard let playerItem = self.playerItem else {
      // If there's no player item or no filters, ensure the composition is nil.
      self.playerItem?.videoComposition = nil
      return
    }
    
    let ciFilter = filters.createCompositeFilter()
    playerItem.videoComposition = AVVideoComposition(asset: playerItem.asset) { [weak self] request in
      guard let self = self else {
        request.finish(with: request.sourceImage, context: nil)
        return
      }
      
      ciFilter?.setValue(request.sourceImage, forKey: kCIInputImageKey)

      if let filteredImage = ciFilter?.outputImage {
        request.finish(with: filteredImage, context: nil)
      } else {
        request.finish(with: request.sourceImage, context: nil)
      }
    }
  }
  
  // MARK: - Private Helper Methods
  
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
      asset.loadValuesAsynchronously(forKeys: ["duration"]) {
        DispatchQueue.main.async {
          var error: NSError?
          if asset.statusOfValue(forKey: "duration", error: &error) == .loaded {
            self.videoDuration = asset.duration
            self.notifyDuration(asset.duration)
          } else {
            self.notifyState(.error)
          }
        }
      }
    }
  }
  
  private func setupObservers(for item: AVPlayerItem) {
    item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: .new, context: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(playerDidReachEnd), name: .AVPlayerItemDidPlayToEndTime, object: item)
  }
  
  private func setupTimeObserver() {
    guard let player = self.player else { return }
    let interval = CMTime(value: 100, timescale: 1000)
    timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
      self?.notifyProgress(time)
    }
  }
  
  public func cleanup() {
    if let token = timeObserverToken, let player = self.player {
      player.removeTimeObserver(token)
      timeObserverToken = nil
    }
    
    if let item = self.playerItem {
      item.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
      NotificationCenter.default.removeObserver(self)
    }
    
    player?.pause()
    player = nil
    playerItem = nil
    playerLayer.player = nil
    videoDuration = nil
    self.filters.lutFilter = nil
  }
  
  // MARK: - KVO & Notification Handlers
  
  @objc private func playerDidReachEnd() {
    notifyState(.ended)
    player?.seek(to: .zero)
  }
  
  public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    guard keyPath == #keyPath(AVPlayerItem.status), let item = object as? AVPlayerItem else {
      super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
      return
    }
    if item.status == .failed {
      notifyState(.error)
    }
  }
  
  // MARK: - Callback Notifiers
  
  private func notifyState(_ state: VideoPlayerState) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.stateCallback?(self.id, state.rawValue)
    }
  }
  
  private func notifyDuration(_ duration: CMTime) {
    guard !duration.seconds.isNaN else { return }
    let durationMs = Int64(duration.seconds * 1000)
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.durationCallback?(self.id, durationMs)
    }
  }
  
  private func notifyProgress(_ progress: CMTime) {
    guard let duration = videoDuration, !progress.seconds.isNaN else { return }
    let progressMs = Int64(progress.seconds * 1000)
    let durationMs = Int64(duration.seconds * 1000)
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.progressCallback?(self.id, min(progressMs, durationMs))
    }
  }
}
