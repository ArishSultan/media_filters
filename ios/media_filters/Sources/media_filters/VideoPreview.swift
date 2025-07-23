import UIKit
import SwiftCube
import AVFoundation

public typealias VideoPreviewStateCallback = @convention(c) (Int, Int) -> Void
public typealias VideoPreviewProgressCallback = @convention(c) (Int, Double) -> Void
public typealias VideoPreviewDurationCallback = @convention(c) (Int, Double) -> Void

public enum VideoPreviewState: Int {
    case stopped = 0
    case playing = 1
    case paused = 2
    case ended = 3
    case error = 4
}

public class VideoPreview: NSObject {
    public let id: Int
    
    // Core components - SINGLE rendering pipeline
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var playerLayer: AVPlayerLayer?
    private var timeObserver: Any?
    
    // Filter support - Hybrid approach using AVVideoComposition
    private var videoComposition: AVVideoComposition?
    private var currentFilter: CIFilter?
    
    // Callbacks
    private var stateCallback: VideoPreviewStateCallback?
    private var progressCallback: VideoPreviewProgressCallback?
    private var durationCallback: VideoPreviewDurationCallback?
    
    // State
    private var duration: CMTime = CMTime.zero
    private var currentTime: CMTime = CMTime.zero
    private var currentState: VideoPreviewState = .stopped
    private weak var containerView: UIView?
    
    public init(id: Int) {
        self.id = id
        super.init()
    }
    
    // MARK: - Callbacks
    public func setStateCallbacks(
        stateCallback: VideoPreviewStateCallback?,
        progressCallback: VideoPreviewProgressCallback?,
        durationCallback: VideoPreviewDurationCallback?,
    ) {
        self.stateCallback = stateCallback
        self.progressCallback = progressCallback
        self.durationCallback = durationCallback
        
        notifyStateChange()
    }
    
    // MARK: - View Attachment (Single approach)
    public func attachToView(_ view: UIView) {
        print("🎬 Attaching video preview \(id) to view")
        containerView = view
        
        // Remove existing layer
        playerLayer?.removeFromSuperlayer()

        // Create single player layer that handles both filtered and normal video
        playerLayer = AVPlayerLayer()
        playerLayer?.frame = view.bounds
        playerLayer?.videoGravity = .resizeAspectFill
        
        // Add to view
        view.layer.addSublayer(playerLayer!)
        
        // Connect player if it exists
        if let player = player {
            playerLayer?.player = player
            print("✅ Player connected to layer")
        } else {
            print("ℹ️ No player available yet")
        }
    }
    
    @MainActor public func loadVideoFile(path: String) -> Int {
        guard FileManager.default.fileExists(atPath: path) else {
            return FFIErrorCodes.FileNotFound
        }
        
        cleanup()
        
        let asset = AVAsset(url: URL(fileURLWithPath: path))
        playerItem = AVPlayerItem(asset: asset)
        guard let playerItem = playerItem else {
            updateState(.error)
            return FFIErrorCodes.AVPlayerItemCreationFailed
        }
        
        // Create player
        player = AVPlayer(playerItem: playerItem)
        guard let player = player else {
            updateState(.error)
            return FFIErrorCodes.AVPlayerCreationFailed
        }
        
        // Connect to layer
        playerLayer?.player = player
        
        // Apply current filter if exists
        if currentFilter != nil {
            applyCurrentFilterToPlayerItem()
        }
        
        // Setup observers
        setupObservers()
        setupTimeObserver()
        
        // Load duration
        loadDuration(from: asset)
        
        updateState(.stopped)
        progressCallback?(id, 0.0)

        return 0
    }
    
    @MainActor public func loadFilterFromFile(path: String) -> Int {
        guard FileManager.default.fileExists(atPath: path) else {
            return FFIErrorCodes.FileNotFound
        }
        
        guard let sc3dFilter = try? SC3DLut(contentsOf: URL(fileURLWithPath: path)) else {
            return FFIErrorCodes.SC3DFilterCreationFailed
        }
        
        guard let ciFilter = try? sc3dFilter.ciFilter() else {
            return FFIErrorCodes.SC3DToCiFilterFailed
        }
        
        // Apply the filter dynamically
        applyFilter(ciFilter)
        
        return 0
    }
    
    // MARK: - Hybrid Filter Management using AVVideoComposition
    @MainActor public func applyFilter(_ filter: CIFilter) {
        currentFilter = filter
        print("✅ Filter applied using AVVideoComposition")
        
        // Apply to current player item if exists
        if playerItem != nil {
            applyCurrentFilterToPlayerItem()
        }
    }
    
    @MainActor public func removeFilter() {
        currentFilter = nil
        print("🧹 Filter removed")
        
        // Remove video composition to return to normal playback
        if let playerItem = playerItem {
            playerItem.videoComposition = nil
        }
    }
    
    @MainActor public func setFilter(_ filter: CIFilter?) {
        if let filter = filter {
            applyFilter(filter)
        } else {
            removeFilter()
        }
    }
    
    private func applyCurrentFilterToPlayerItem() {
        guard let playerItem = playerItem,
              let currentFilter = currentFilter else { return }
        
        // Get video track
        guard let videoTrack = playerItem.asset.tracks(withMediaType: .video).first else {
            print("❌ No video track found")
            return
        }
        
        // Create video composition with Core Image filter
        let videoComposition = AVVideoComposition(asset: playerItem.asset) { request in
            // Get the source image
            let sourceImage = request.sourceImage.clampedToExtent()
            
            // Apply the filter
            currentFilter.setValue(sourceImage, forKey: kCIInputImageKey)
            
            // Provide the filtered image
            if let filteredImage = currentFilter.outputImage {
                request.finish(with: filteredImage, context: nil)
            } else {
                request.finish(with: sourceImage, context: nil)
            }
        }
        
        // Apply the composition to the player item
        playerItem.videoComposition = videoComposition
        self.videoComposition = videoComposition
        
        print("✅ AVVideoComposition applied with filter")
    }
    
    // MARK: - Duration Loading
    private func loadDuration(from asset: AVAsset) {
        if #available(iOS 15.0, *) {
            Task {
                do {
                    let duration = try await asset.load(.duration)
                    await MainActor.run {
                        self.duration = duration
                        print("✅ Duration loaded: \(self.duration)s")
                        self.notifyStateChange()
                    }
                } catch {
                    print("❌ Failed to load duration: \(error)")
                    await MainActor.run {
                        self.updateState(.error)
                    }
                }
            }
        } else {
            // Legacy iOS support
            asset.loadValuesAsynchronously(forKeys: ["duration"]) {
                DispatchQueue.main.async {
                    var error: NSError?
                    let status = asset.statusOfValue(forKey: "duration", error: &error)
                    
                    if status == .loaded {
                        self.duration = asset.duration
                        print("✅ Duration loaded: \(self.duration)s")
                        self.notifyStateChange()
                    } else {
                        print("❌ Failed to load duration: \(String(describing: error))")
                        self.updateState(.error)
                    }
                }
            }
        }
    }
    
    // MARK: - Playback Controls
    @MainActor
    public func play() {
        guard let player = player else {
            print("❌ Cannot play: no player")
            return
        }
        
        print("▶️ Playing video")
        player.play()
        updateState(.playing)
    }
    
    @MainActor
    public func pause() {
        guard let player = player else {
            print("❌ Cannot pause: no player")
            return
        }
        
        print("⏸️ Pausing video")
        player.pause()
        updateState(.paused)
    }
    
    public func seek(to time: Int64) {
        guard let player = player else {
            print("❌ Cannot seek: no player")
            return
        }
        
        let cmTime = CMTime(value: time, timescale: 1_000_000)
        player.seek(to: cmTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero) { [weak self] completed in
            if completed {
                self?.currentTime = cmTime
                self?.notifyStateChange()
                print("✅ Seek completed")
            }
        }
    }
    
    public func setVolume(_ volume: Float) {
        let clampedVolume = max(0.0, min(1.0, volume))
        player?.volume = clampedVolume
        print("🔊 Volume set to: \(clampedVolume)")
    }
    
    // MARK: - Frame Updates
    public func updateViewFrame(_ frame: CGRect) {
        playerLayer?.frame = frame
        print("📐 Frame updated: \(frame)")
    }
    
    // MARK: - Observers
    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidReachEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerFailedToPlay),
            name: .AVPlayerItemFailedToPlayToEndTime,
            object: playerItem
        )
        
        // Observe player item status
        playerItem?.addObserver(self, forKeyPath: "status", options: [.new], context: nil)
    }
    
    private func setupTimeObserver() {
        guard let player = player else { return }
        
        // Remove existing observer
        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        
        // Add new observer - updates every 0.1 seconds
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time
            
            // Call progress callback
            if let self = self {
                self.progressCallback?(self.id, min(self.currentTime.seconds, self.duration.seconds))
            }
        }
    }
    
    // MARK: - Observer Callbacks
    @objc private func playerDidReachEnd() {
        print("🏁 Video ended")
        updateState(.ended)
    }
    
    @objc private func playerFailedToPlay() {
        print("❌ Video failed to play")
        updateState(.error)
    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            if let playerItem = object as? AVPlayerItem {
                switch playerItem.status {
                case .readyToPlay:
                    print("✅ Player item ready to play")
                case .failed:
                    print("❌ Player item failed: \(String(describing: playerItem.error))")
                    updateState(.error)
                case .unknown:
                    print("🤔 Player item status unknown")
                @unknown default:
                    print("🤷‍♂️ Unknown player item status")
                }
            }
        }
    }
    
    // MARK: - State Management
    private func updateState(_ newState: VideoPreviewState) {
        currentState = newState
        notifyStateChange()
    }
    
    private func notifyStateChange() {
        stateCallback?(id, currentState.rawValue)
        durationCallback?(id, duration.seconds)
    }
    
    // MARK: - Filter Management
    public func clearFilter() {
        DispatchQueue.main.async { [weak self] in
            self?.removeFilter()
        }
    }
    
    public func hasFilter() -> Bool {
        return currentFilter != nil
    }
    
    public func getCurrentFilter() -> CIFilter? {
        return currentFilter
    }
    
    public func isFilterActive() -> Bool {
        return currentFilter != nil && videoComposition != nil
    }
    
    // MARK: - Debug
    public func debugState() {
        print("""
        
        === 🎬 Video Preview Debug ===
        ID: \(id)
        State: \(currentState)
        Duration: \(duration)s
        Current Time: \(currentTime)s
        Player: \(player != nil ? "✅" : "❌")
        Player Item: \(playerItem != nil ? "✅" : "❌")
        Player Layer: \(playerLayer != nil ? "✅" : "❌")
        Container View: \(containerView != nil ? "✅" : "❌")
        Filter Active: \(currentFilter != nil ? "✅" : "❌")
        Video Composition: \(videoComposition != nil ? "✅" : "❌")
        
        """)
        
        if let player = player {
            print("Player Rate: \(player.rate)")
            print("Player Status: \(player.status.rawValue)")
            print("Player Time Control: \(player.timeControlStatus.rawValue)")
        }
        
        if let playerItem = playerItem {
            print("Player Item Status: \(playerItem.status.rawValue)")
            if let error = playerItem.error {
                print("Player Item Error: \(error)")
            }
        }
        
        if let playerLayer = playerLayer {
            print("Player Layer Frame: \(playerLayer.frame)")
            print("Player Layer Hidden: \(playerLayer.isHidden)")
        }
        
        if let currentFilter = currentFilter {
            print("Current Filter: \(currentFilter.name)")
        }
        
        print("==============================\n")
    }
    
    // MARK: - Cleanup
    public func cleanup() {
        // Remove observers
        if let timeObserver = timeObserver, let player = player {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        
        playerItem?.removeObserver(self, forKeyPath: "status")
        NotificationCenter.default.removeObserver(self)
        
        // Clean up player
        player?.pause()
        player = nil
        playerItem = nil
        
        // Clean up filter
        currentFilter = nil
        videoComposition = nil
    }
    
    @MainActor public func destroy() {
        print("🗑️ Destroying video preview \(id)")
        cleanup()
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        containerView = nil
    }
    
    deinit {
        print("♻️ VideoPreview \(id) deinitialized")
        cleanup()
    }
}
