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
            binaryMessenger: messenger)
    }

    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
          return FlutterStandardMessageCodec.sharedInstance()
    }
}

class FLNativeView: NSObject, FlutterPlatformView {
    private var _view: UIView

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        print("I am here at frame \(frame)")
        _view = CustomUIView()
        super.init()
        createNativeView(view: _view, frame: frame, viewId: (args as? Int)!)
    }

    func view() -> UIView {
        return _view
    }

    func createNativeView(view: UIView, frame: CGRect, viewId: Int) {
        view.frame = frame
        view.backgroundColor = UIColor.black
        
        print("🎬 Creating native view for ID: \(viewId)")
        
        guard let preview = VideoPreviewManager.instance.getPreview(id: viewId) else {
            print("❌ Failed to get preview for viewId: \(viewId)")
            // Show error state
            let errorLabel = UILabel()
            errorLabel.text = "Video Preview Error"
            errorLabel.textColor = .white
            errorLabel.textAlignment = .center
            errorLabel.frame = view.bounds
            view.addSubview(errorLabel)
            return
        }

        // Attach the preview to this view
        preview.attachToView(view)
        
        print("✅ Video preview attached to view")
        
        // Debug after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            preview.debugState()
        }
    }
}

class CustomUIView: UIView {
    override func layoutSubviews() {
        for sublayer in self.layer.sublayers! {
            sublayer.frame = bounds
        }
    }
}
