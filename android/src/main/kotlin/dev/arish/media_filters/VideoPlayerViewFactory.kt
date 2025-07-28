package dev.arish.media_filters

import android.view.View
import android.content.Context

import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformViewFactory


class VideoPlayerViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
  override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
    val creationParams = args as Map<String, Any>;
    return VideoPlayerPlatformView(
      viewId = creationParams["viewId"] as Int,
      type = creationParams["type"] as Int,
      context = context
    )
  }
}

class VideoPlayerPlatformView(private val viewId: Int, private val type: Int, context: Context) : PlatformView {
  override fun getView(): View {
    if (type == 0) {
      return VideoPlayersManager.getPlayer(viewId)!!.view
    } else {
      return ImageEditorsManager.get(viewId)!!.view
    }
  }

  override fun dispose() {
  }
}
