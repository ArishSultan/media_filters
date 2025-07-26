package dev.arish.media_filters

import android.view.View
import android.content.Context

import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformViewFactory


class VideoPlayerViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
  override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
    return VideoPlayerPlatformView(viewId = viewId, context = context)
  }
}

class VideoPlayerPlatformView(private val viewId: Int, context: Context) : PlatformView {
  private val player = VideoPlayersManager.createPlayer(viewId, context)

  override fun getView(): View = player.view

  override fun dispose() {
    VideoPlayersManager.destroyPlayer(viewId)
  }
}
