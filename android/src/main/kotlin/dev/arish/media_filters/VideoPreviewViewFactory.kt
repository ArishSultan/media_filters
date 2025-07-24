package dev.arish.media_filters

import android.view.View
import android.content.Context

import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformViewFactory


class VideoPreviewViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
  override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
    return VideoPreviewPlatformView(viewId = viewId, context = context)
  }
}

class VideoPreviewPlatformView(private val viewId: Int, private val context: Context) : PlatformView {
  private val view: View

  init {
    val manager = VideoPreviewManager.getInstance()
    val videoPreview = manager.createPreview(viewId, context)
    view = videoPreview.createView()
  }

  override fun getView(): View = view

  override fun dispose() {
    VideoPreviewManager.getInstance().destroyPreview(viewId)
  }
}
