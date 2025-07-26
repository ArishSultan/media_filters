import Flutter
import UIKit

class VideoPreviewViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return VideoPlayerView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger,
        )
    }

    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

class VideoPlayerView: NSObject, FlutterPlatformView {
    private var _view: UIView
    private var _viewId: Int = -1

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        _view = VideoPlayerUIView()
        _viewId = Int(viewId)
        super.init()

        createNativeView(view: _view)
    }

    func view() -> UIView {
        return _view
    }

    func createNativeView(view: UIView) {
        VideoPlayersManager.create(_viewId).attachToView(view)
    }
    
    deinit {
        if (_viewId > -1) {
            VideoPlayersManager.remove(_viewId)
        }
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
