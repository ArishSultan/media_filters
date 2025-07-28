package dev.arish.media_filters

import androidx.annotation.Keep
import androidx.media3.common.util.UnstableApi

fun interface ByteArrayCallback {
  fun invoke(viewId: Int, data: ByteArray)
}

@Keep
object ApiImageEditor {
  @JvmStatic
  @UnstableApi
  fun create(imageId: Int) {
    ImageEditorsManager.create(imageId)
  }

  @JvmStatic
  @UnstableApi
  fun loadImageFile(imageId: Int, path: String) {
    ImageEditorsManager.get(imageId)?.loadImageFile(path)
  }

  @JvmStatic
  @UnstableApi
  fun setImageCallback(imageId: Int, callback: ByteArrayCallback?) {
    ImageEditorsManager.get(imageId)?.processCompleteCb = callback
  }

  @JvmStatic
  @UnstableApi
  fun removeImageCallback(imageId: Int) {
    ImageEditorsManager.get(imageId)?.processCompleteCb = null
  }

  @JvmStatic
  @UnstableApi
  fun loadFilterFile(imageId: Int, path: String) {
    ImageEditorsManager.get(imageId)?.loadFilterFile(path)
  }

  @JvmStatic
  @UnstableApi
  fun removeLutFilter(imageId: Int) {
    ImageEditorsManager.get(imageId)?.removeLutFilter()
  }

  @JvmStatic
  @UnstableApi
  fun setExposure(imageId: Int, exposure: Float) {
    ImageEditorsManager.get(imageId)?.setExposure(exposure)
  }

  @JvmStatic
  @UnstableApi
  fun setContrast(imageId: Int, contrast: Float) {
    ImageEditorsManager.get(imageId)?.setContrast(contrast)
  }

  @JvmStatic
  @UnstableApi
  fun setSaturation(imageId: Int, saturation: Float) {
    ImageEditorsManager.get(imageId)?.setSaturation(saturation)
  }

  @JvmStatic
  @UnstableApi
  fun setTemperature(imageId: Int, temperature: Float) {
    ImageEditorsManager.get(imageId)?.setTemperature(temperature)
  }

  @JvmStatic
  @UnstableApi
  fun setTint(imageId: Int, tint: Float) {
    ImageEditorsManager.get(imageId)?.setTint(tint)
  }

  @JvmStatic
  @UnstableApi
  fun destroy(imageId: Int) {
    ImageEditorsManager.destroy(imageId)
  }
}

