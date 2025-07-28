package dev.arish.media_filters

import android.annotation.SuppressLint
import android.content.Context
import androidx.media3.common.util.UnstableApi
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding

class MediaFiltersPlugin : FlutterPlugin {
  companion object {
    @SuppressLint("StaticFieldLeak")
    public var context: Context? = null
  }

  override fun onAttachedToEngine(binding: FlutterPluginBinding) {
    context = binding.applicationContext

    binding
      .platformViewRegistry
      .registerViewFactory("media_filters.preview", VideoPlayerViewFactory())
  }

  @UnstableApi
  override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
    context = null
    VideoPlayersManager.destroyAllPlayers()
    ImageEditorsManager.destroyAll()
  }
}
