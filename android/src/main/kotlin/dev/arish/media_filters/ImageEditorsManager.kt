package dev.arish.media_filters

import androidx.media3.common.util.UnstableApi
import java.util.concurrent.ConcurrentHashMap

object ImageEditorsManager {
  private val editors = ConcurrentHashMap<Int, ImageEditor>()

  val count: Int
    get() = editors.size

  @UnstableApi
  fun create(imageId: Int): ImageEditor {
    return editors.getOrPut(imageId) {
      ImageEditor(imageId, MediaFiltersPlugin.context!!)
    }
  }

  @UnstableApi
  fun get(imageId: Int): ImageEditor? {
    return editors[imageId]
  }

  @UnstableApi
  fun destroy(imageId: Int) {
    editors.remove(imageId)?.dispose()
  }

  @UnstableApi
  fun destroyAll() {
    editors.values.forEach { it.dispose() }
    editors.clear()
  }
}