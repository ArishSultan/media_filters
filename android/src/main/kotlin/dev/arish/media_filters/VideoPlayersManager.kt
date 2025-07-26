package dev.arish.media_filters

import android.content.Context
import java.util.concurrent.ConcurrentHashMap

object VideoPlayersManager {
  private val previews = ConcurrentHashMap<Int, VideoPlayer>()

  val count: Int
    get() = previews.size

  fun createPlayer(viewId: Int, context: Context): VideoPlayer {
    return previews.getOrPut(viewId) {
      VideoPlayer(viewId, context)
    }
  }

  fun getPlayer(viewId: Int): VideoPlayer? {
    return previews[viewId]
  }

  fun destroyPlayer(viewId: Int) {
    previews.remove(viewId)?.cleanup()
  }

  fun destroyAllPlayers() {
    previews.values.forEach { it.cleanup() }
    previews.clear()
  }
}