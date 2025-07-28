package dev.arish.media_filters

import android.R.attr.duration
import java.io.File

import android.net.Uri
import android.util.Log
import android.view.ViewGroup
import android.content.Context
import android.graphics.BitmapFactory

import androidx.media3.ui.PlayerView
import androidx.media3.common.Player
import androidx.media3.common.MediaItem
import androidx.media3.common.util.UnstableApi
import androidx.media3.effect.ColorLut
import androidx.media3.effect.SingleColorLut
import androidx.media3.exoplayer.ExoPlayer

import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.DelicateCoroutinesApi
import kotlin.math.min
import kotlin.reflect.typeOf

enum class VideoPlayerState(val value: Int) {
  STOPPED(0),
  PLAYING(1),
  PAUSED(2),
  ENDED(3),
  ERROR(4)
}

/**
 *
 */
class VideoPlayer(private val id: Int, context: Context) {
  /**
   *
   */
  private val player = ExoPlayer.Builder(context).build().apply {
    addListener(object : Player.Listener {
      override fun onPlaybackStateChanged(playbackState: Int) {
        notifyPlaybackStateChanged(
          when (playbackState) {
            Player.STATE_ENDED -> {
              progressCb?.invoke(id, duration)

              VideoPlayerState.ENDED
            }
            Player.STATE_IDLE -> VideoPlayerState.STOPPED
            Player.STATE_READY -> {
              durationCb?.invoke(id, duration)

              VideoPlayerState.STOPPED
            }

            Player.STATE_BUFFERING -> VideoPlayerState.STOPPED
            else -> VideoPlayerState.ERROR
          }
        )
      }

      override fun onIsPlayingChanged(isPlaying: Boolean) {
        if (isPlaying) {
          notifyPlaybackStateChanged(VideoPlayerState.PLAYING)
          startProgressTracking()
        } else {
          notifyPlaybackStateChanged(
            if (playbackState == Player.STATE_READY)
              VideoPlayerState.PAUSED
            else
              VideoPlayerState.ENDED
          )

          stopProgressTracking()
        }
      }

      override fun onPlayerError(error: androidx.media3.common.PlaybackException) {
        Log.e(TAG, "Player error: ${error.message}", error)
        notifyPlaybackStateChanged(VideoPlayerState.ERROR)
      }

      // Handle duration changes properly
      override fun onTimelineChanged(timeline: androidx.media3.common.Timeline, reason: Int) {
        durationCb?.invoke(id, duration)
      }
    })
  }

  /**
   *
   */
  val view = PlayerView(context).also {
    it.player = player
    it.useController = false
    it.layoutParams = ViewGroup.LayoutParams(
      ViewGroup.LayoutParams.MATCH_PARENT,
      ViewGroup.LayoutParams.MATCH_PARENT
    )
  }

  /**
   *
   */
  var stateCb: IntegerValueCallback? = null

  /**
   *
   */
  var progressCb: LongValueCallback? = null

  /**
   *
   */
  var durationCb: LongValueCallback? = null

  /**
   *
   */
  private var currentPlaybackState: VideoPlayerState? = null

  /**
   *
   */
  private var playerProgressListenerJob: Job? = null

  /**
   *
   */
  @UnstableApi
  val filters = EnhancedFilters()


  /**
   *
   */
  fun play() {
    player.play()
  }

  /**
   *
   */
  fun pause() {
    player.pause()
  }

  /**
   *
   */
  fun seekTo(timeMs: Long) {
    val time = min(timeMs, player.duration)

    player.seekTo(time)
    progressCb?.invoke(id, time)
  }

  /**
   *
   */
  @UnstableApi
  fun loadVideoFile(filePath: String): Int {
    val file = File(filePath)
    if (!(file.exists() && file.isFile)) {
      return ERROR_FILE_NOT_FOUND
    }

    // Stop the player before changing the video
    player.stop()

    try {
      val mediaItem = MediaItem.fromUri(Uri.fromFile(file))

      view.player = player
      player.setMediaItem(mediaItem)
      player.setVideoEffects(listOf())
      player.prepare()
    } catch (e: Exception) {
      Log.e(TAG, e.toString(), e)
      notifyPlaybackStateChanged(VideoPlayerState.ERROR)
      return ERROR_PLAYER_CREATION_FAILED
    }

    return SUCCESS
  }

  /**
   *
   */
  @UnstableApi
  fun loadFilterFile(filePath: String): Int {
    val file = File(filePath)
    if (!(file.exists() && file.isFile)) {
      return ERROR_FILE_NOT_FOUND
    }

    filters.loadLutFilter(filePath)
    applyFilters()

    return 0
  }

  @UnstableApi
  fun removeLutFilter() {
    filters.removeLutFilter()
  }

  /**
   * Set exposure value and apply
   */
  @UnstableApi
  fun setExposure(value: Float) {
    filters.exposure.value = value
    applyFilters()
  }

  /**
   * Set contrast value and apply
   */
  @UnstableApi
  fun setContrast(value: Float) {
    filters.contrast.value = value
    applyFilters()
  }

  /**
   * Set saturation value and apply
   */
  @UnstableApi
  fun setSaturation(value: Float) {
    filters.saturation.value = value
    applyFilters()
  }

  /**
   * Set temperature value and apply
   */
  @UnstableApi
  fun setTemperature(value: Float) {
    filters.temperature.value = value
    applyFilters()
  }

  /**
   * Set tint value and apply
   */
  @UnstableApi
  fun setTint(value: Float) {
    filters.tint.value = value
    applyFilters()
  }

  @UnstableApi
  fun applyFilters() {
    player.setVideoEffects(filters.createEffects())
    player.prepare()
  }

  /**
   *
   */
  private fun notifyPlaybackStateChanged(state: VideoPlayerState) {
    if (state != currentPlaybackState) {
      currentPlaybackState = state

      stateCb?.invoke(id, state.value)
    }
  }

  /**
   *
   */
  @OptIn(DelicateCoroutinesApi::class)
  private fun startProgressTracking() {
    playerProgressListenerJob = GlobalScope.launch {
      flow {
        while (true) {
          emit(player.currentPosition)
          delay(100)
        }
      }.flowOn(Dispatchers.Main).collect {
        progressCb?.invoke(id, it)
      }
    }
  }

  private fun stopProgressTracking() {
    playerProgressListenerJob?.cancel()
    playerProgressListenerJob = null
  }

  fun cleanup() {
    stopProgressTracking()

    player.release()
    view.player = null
  }

  companion object {
    private const val TAG = "VideoPlayer"

    const val SUCCESS = 0
    const val ERROR_FILE_NOT_FOUND = -1
    const val ERROR_PLAYER_CREATION_FAILED = -2
    const val ERROR_FILTER_CREATION_FAILED = -3
  }
}
