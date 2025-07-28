package dev.arish.media_filters

import androidx.annotation.Keep
import androidx.media3.common.util.UnstableApi

fun interface IntegerValueCallback {
  fun invoke(viewId: Int, state: Int)
}

fun interface LongValueCallback {
  fun invoke(viewId: Int, state: Long)
}


@Keep
object ApiVideoPlayer {
  @JvmStatic
  fun create(viewId: Int) {
    VideoPlayersManager.createPlayer(viewId, MediaFiltersPlugin.context!!)
  }

  @JvmStatic
  fun destroy(imageId: Int) {
    VideoPlayersManager.destroyPlayer(imageId)
  }

  @JvmStatic
  @UnstableApi
  fun loadVideoFile(viewId: Int, path: String) {
    val preview = VideoPlayersManager.getPlayer(viewId)?.loadVideoFile(path)
  }

  @JvmStatic
  fun play(viewId: Int) {
    VideoPlayersManager.getPlayer(viewId)?.play()
  }

  @JvmStatic
  fun pause(viewId: Int) {
    VideoPlayersManager.getPlayer(viewId)?.pause()
  }

  @JvmStatic
  fun seekTo(viewId: Int, progress: Long) {
    VideoPlayersManager.getPlayer(viewId)?.seekTo(progress)
  }

  @JvmStatic
  fun setStateCallbacks(
    viewId: Int,
    stateCallback: IntegerValueCallback?,
    durationCallback: LongValueCallback?,
    progressCallback: LongValueCallback?,
  ) {
    val player = VideoPlayersManager.getPlayer(viewId)

    player?.stateCb = stateCallback
    player?.progressCb = progressCallback
    player?.durationCb = durationCallback
  }

  @JvmStatic
  fun removeStateCallbacks(viewId: Int) {
    val player = VideoPlayersManager.getPlayer(viewId)

    player?.stateCb = null
    player?.progressCb = null
    player?.durationCb = null
  }

  @JvmStatic
  @UnstableApi
  fun loadFilterFile(viewId: Int, path: String) {
    VideoPlayersManager.getPlayer(viewId)?.loadFilterFile(path)
  }

  @JvmStatic
  fun removeLutFilter(viewId: Int) {
    VideoPlayersManager.getPlayer(viewId)?.removeLutFilter()
  }

  @JvmStatic
  @UnstableApi
  fun setExposure(viewId: Int, exposure: Float) {
    VideoPlayersManager.getPlayer(viewId)?.setExposure(exposure)
  }

  @JvmStatic
  @UnstableApi
  fun setContrast(viewId: Int, contrast: Float) {
    VideoPlayersManager.getPlayer(viewId)?.setContrast(contrast)
  }

  @JvmStatic
  @UnstableApi
  fun setSaturation(viewId: Int, saturation: Float) {
    VideoPlayersManager.getPlayer(viewId)?.setSaturation(saturation)
  }

  @JvmStatic
  @UnstableApi
  fun setTemperature(viewId: Int, temperature: Float) {
    VideoPlayersManager.getPlayer(viewId)?.setTemperature(temperature)
  }

  @JvmStatic
  @UnstableApi
  fun setTint(viewId: Int, tint: Float) {
    VideoPlayersManager.getPlayer(viewId)?.setTint(tint)
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
//    callback: StringValueCallback
  ) {
    val preview = VideoPlayersManager.getPlayer(viewId)
    if (preview != null) {
//      preview.exportVideo(
//        videoPath,
//        filterPath,
//        outputPath,
//        outputWidth,
//        outputHeight,
//        maintainAspectRatio,
//        exportId,
//        callback
//      )
    } else {
//      callback.invoke(exportId, null)
    }
  }
}
