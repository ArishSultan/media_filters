package dev.arish.media_filters

import androidx.annotation.Keep
import androidx.media3.common.util.UnstableApi

fun interface IntegerValueCallback {
  fun invoke(viewId: Int, state: Long)
}

fun interface StringValueCallback {
  fun invoke(viewId: Int, result: String?)
}

@Keep
object ApiVideoPreview {
  @JvmStatic
  @UnstableApi
  fun loadVideoFile(viewId: Int, path: String) {
    val preview = VideoPreviewManager.getInstance().getPreview(viewId)?.loadVideoFile(path)
  }

  @JvmStatic
  fun play(viewId: Int) {
    VideoPreviewManager.getInstance().getPreview(viewId)?.play()
  }

  @JvmStatic
  fun pause(viewId: Int) {
    VideoPreviewManager.getInstance().getPreview(viewId)?.pause()
  }

  @JvmStatic
  fun seekTo(viewId: Int, progress: Long) {
    VideoPreviewManager.getInstance().getPreview(viewId)?.seekTo(progress)
  }

  @JvmStatic
  fun setStateCallbacks(
    viewId: Int,
    stateCallback: IntegerValueCallback?,
    durationCallback: IntegerValueCallback?,
    progressCallback: IntegerValueCallback?,
  ) {
    VideoPreviewManager.getInstance().getPreview(viewId)?.setStateCallbacks(
      stateCallback,
      durationCallback,
      progressCallback,
    )
  }

  @JvmStatic
  fun removeStateCallbacks(viewId: Int) {
    VideoPreviewManager.getInstance().getPreview(viewId)?.removeStateCallbacks()
  }

  @JvmStatic
  @UnstableApi
  fun loadFilterFile(viewId: Int, path: String) {
    VideoPreviewManager.getInstance().getPreview(viewId)?.loadFilterFile(path)
  }

  @JvmStatic
  fun exportVideo(
    viewId: Int,
    videoPath: String,
    filterPath: String?,
    outputPath: String,
    outputWidth: Int,
    outputHeight: Int,
    maintainAspectRatio: Boolean,
    exportId: Int,
    callback: StringValueCallback
  ) {
    val preview = VideoPreviewManager.getInstance().getPreview(viewId)
    if (preview != null) {
      preview.exportVideo(
        videoPath,
        filterPath,
        outputPath,
        outputWidth,
        outputHeight,
        maintainAspectRatio,
        exportId,
        callback
      )
    } else {
      callback.invoke(exportId, null)
    }
  }
}

/**
 * @_cdecl("vpLoadFilterFile")
 * @MainActor public func vpLoadFilterFile(viewId: Int, path: UnsafePointer<CChar>) -> Int {
 *     guard let preview = VideoPreviewManager.instance.getPreview(viewId) else {
 *         return FFIErrorCodes.VideoPreviewNotFound
 *     }
 *
 *     return preview.loadFilterFromFile(path: String(cString: path))
 * }
 *
 * @_cdecl("vpClearFilter")
 * @MainActor public func vpClearFilter(viewId: Int) -> Int {
 *     guard let preview = VideoPreviewManager.instance.getPreview(viewId) else {
 *         return FFIErrorCodes.VideoPreviewNotFound
 *     }
 *
 *     preview.removeFilter()
 *     return 0
 * }
 */