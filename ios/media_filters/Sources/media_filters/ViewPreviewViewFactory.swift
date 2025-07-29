import Flutter
import UIKit

class VideoPreviewViewFactory: NSObject, FlutterPlatformViewFactory {
  init(messenger: FlutterBinaryMessenger) {
    super.init()
  }
  
  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    return VideoPlayerView(playerId: (args as? Int)!)
  }
  
  public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }
}

class VideoPlayerView: NSObject, FlutterPlatformView {
  private var _view: UIView
  
  init(playerId: Int) {
    _view = VideoPlayerUIView()
    
    super.init()
    
    // Attach to view by fetching the Video Player
    VideoPlayer.get(playerId)?.attachView(_view)
  }
  
  func view() -> UIView {
    return _view
  }
}

class VideoPlayerUIView: UIView {
  override func layoutSubviews() {
    super.layoutSubviews() // It's good practice to call super
    
    // Determine the correct frame to use
    let newFrame: CGRect
    if bounds.width.isInfinite || bounds.height.isInfinite {
      // If the view's bounds are infinite, use a zero-sized frame
      newFrame = .zero
    } else {
      // Otherwise, use the view's actual bounds
      newFrame = bounds
    }
    
    // Safely iterate through sublayers and assign the new frame
    // Using `?? []` is safer than force-unwrapping with `!`
    for sublayer in self.layer.sublayers ?? [] {
      sublayer.frame = newFrame
    }
  }
}
