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
        return FLNativeView(
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

class FLNativeView: NSObject, FlutterPlatformView {
    private var _view: UIView
    private var _viewId: Int = -1

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        _view = VidePreviewUIView()
        _viewId = Int(viewId)
        super.init()

        createNativeView(view: _view, viewId: Int(viewId))
    }

    func view() -> UIView {
        return _view
    }

    func createNativeView(view: UIView, viewId: Int) {
        let preview = VideoPreviewManager.instance.createPreview(viewId: viewId)
        preview.attachToView(view)
    }
    
    deinit {
        if (_viewId > -1) {
            VideoPreviewManager.instance.destroyPreview(viewId: _viewId)
        }
    }
}

class VidePreviewUIView: UIView {
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
