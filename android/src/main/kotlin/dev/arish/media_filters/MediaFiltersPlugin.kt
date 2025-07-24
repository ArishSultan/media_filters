package dev.arish.media_filters

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding

class MediaFiltersPlugin : FlutterPlugin {
  override fun onAttachedToEngine(binding: FlutterPluginBinding) {
    binding
      .platformViewRegistry
      .registerViewFactory("media_filters.preview", VideoPreviewViewFactory())
  }

  override fun onDetachedFromEngine(binding: FlutterPluginBinding) {}
}
