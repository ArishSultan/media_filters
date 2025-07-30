import UIKit
import Flutter

public class MediaFiltersPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    registrar.register(
      VideoPreviewViewFactory(messenger: registrar.messenger()),
      withId: "media_filters.preview"
    )
  }
}
