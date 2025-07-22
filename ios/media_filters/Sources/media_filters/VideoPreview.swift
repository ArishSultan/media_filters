import UIKit
import AVFoundation

public typealias VideoPreviewProgressCallback = @convention(c) (Int, Double) -> Void
public typealias VideoPreviewStateCallback = @convention(c) (Int, Int, Double, Double) -> Void

public enum VideoPreviewState: Int {
    case stopped = 0
    case playing = 1
    case paused = 2
    case ended = 3
    case error = 4
}

public class VideoPreview: NSObject {
    public let id: Int
    
    // Core components
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var playerLayer: AVPlayerLayer?
    private var timeObserver: Any?
    
    // Callbacks
    private var stateCallback: VideoPreviewStateCallback?
    private var progressCallback: VideoPreviewProgressCallback?
    
    // State
    private var duration: Double = 0.0
    private var currentTime: Double = 0.0
    private var currentState: VideoPreviewState = .stopped
    private weak var containerView: UIView?
    
    public init(id: Int) {
        self.id = id
        super.init()
    }
    
    // MARK: - Callbacks
    public func setStateCallback(_ callback: VideoPreviewStateCallback?) {
        stateCallback = callback
    }
    
    public func setProgressCallback(_ callback: VideoPreviewProgressCallback?) {
        progressCallback = callback
    }
    
    // MARK: - View Attachment
    public func attachToView(_ view: UIView) {
        print("🎬 Attaching video preview \(id) to view")
        containerView = view
        
        // Remove existing layer
        playerLayer?.removeFromSuperlayer()

        // Create player layer
        playerLayer = AVPlayerLayer()
        playerLayer?.frame = view.bounds
        playerLayer?.videoGravity = .resizeAspectFill
//        playerLayer?.backgroundColor = UIColor.black.cgColor
        
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
    
    // MARK: - Video Loading
    @MainActor
    public func loadVideo(path: String) -> Bool {
        print("🎬 Loading video: \(path)")
        
        // Check file exists
        guard FileManager.default.fileExists(atPath: path) else {
            print("❌ Video file not found: \(path)")
            updateState(.error)
            return false
        }
        
        // Clean up existing player
        cleanup()
        
        // Create URL and asset
        let url = URL(fileURLWithPath: path)
        let asset = AVAsset(url: url)
        
        // Create player item
        playerItem = AVPlayerItem(asset: asset)
        guard let playerItem = playerItem else {
            print("❌ Failed to create player item")
            updateState(.error)
            return false
        }
        
        // Create player
        player = AVPlayer(playerItem: playerItem)
        guard let player = player else {
            print("❌ Failed to create player")
            updateState(.error)
            return false
        }
        
        // Connect to layer if attached
        playerLayer?.player = player
        
        // Setup observers
        setupObservers()
        setupTimeObserver()
        
        // Load duration
        loadDuration(from: asset)
        
        print("✅ Video loaded successfully")
        updateState(.stopped)
        return true
    }
    
    // MARK: - Duration Loading
    private func loadDuration(from asset: AVAsset) {
        if #available(iOS 15.0, *) {
            Task {
                do {
                    let duration = try await asset.load(.duration)
                    await MainActor.run {
                        self.duration = duration.seconds
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
                        self.duration = asset.duration.seconds
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
    
    public func seek(to time: Double) {
        guard let player = player else {
            print("❌ Cannot seek: no player")
            return
        }
        
        print("⏭️ Seeking to: \(time)s")
        let cmTime = CMTime(seconds: time, preferredTimescale: 1000)
        player.seek(to: cmTime) { [weak self] completed in
            if completed {
                self?.currentTime = time
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
            self?.currentTime = time.seconds
            
            // Call progress callback
            if let self = self, self.duration > 0 {
                let progress = self.currentTime / self.duration
                self.progressCallback?(self.id, progress)
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
        stateCallback?(id, currentState.rawValue, currentTime, duration)
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
        
        print("==============================\n")
    }
    
    // MARK: - Cleanup
    private func cleanup() {
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
