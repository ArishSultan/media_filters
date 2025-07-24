package dev.arish.media_filters

import java.io.File
import android.net.Uri
import android.util.Log
import android.os.Looper
import android.view.View
import android.os.Handler
import android.content.Context
import androidx.media3.common.Player
import androidx.media3.ui.PlayerView
import androidx.media3.common.MediaItem
import androidx.media3.common.VideoSize
import androidx.media3.exoplayer.ExoPlayer

enum class VideoPreviewState(val value: Int) {
  STOPPED(0),
  PLAYING(1),
  PAUSED(2),
  ENDED(3),
  ERROR(4)
}

class VideoPreview(
  private val id: Int,
  private val context: Context
) {
  private var exoPlayer: ExoPlayer? = null
  private var playerView: PlayerView? = null

  //    private var transformer: Transformer? = null
  private var currentState = VideoPreviewState.STOPPED
  private var currentLutPath: String? = null
  private var originalMediaItem: MediaItem? = null

  // Callbacks
  var stateCallback: IntegerValueCallback? = null
  var progressCallback: IntegerValueCallback? = null
  var durationCallback: IntegerValueCallback? = null

  // Progress tracking
  private val progressHandler = Handler(Looper.getMainLooper())
  private var progressRunnable: Runnable? = null
  private var isProgressTracking = false

  // Duration tracking to avoid repeated notifications
  private var lastNotifiedDuration: Long = -1

  private val playerListener = object : Player.Listener {
    override fun onPlaybackStateChanged(playbackState: Int) {
      when (playbackState) {
        Player.STATE_IDLE -> {
          updateState(VideoPreviewState.STOPPED)
          stopProgressTracking()
        }

        Player.STATE_BUFFERING -> {
          updateState(VideoPreviewState.STOPPED)
          stopProgressTracking()
        }

        Player.STATE_READY -> {
          // Don't change state here, let onIsPlayingChanged handle it
          notifyDuration()
          if (exoPlayer?.isPlaying == true) {
            startProgressTracking()
          }
        }

        Player.STATE_ENDED -> {
          updateState(VideoPreviewState.ENDED)
          stopProgressTracking()
        }
      }
    }

    override fun onIsPlayingChanged(isPlaying: Boolean) {
      if (isPlaying) {
        updateState(VideoPreviewState.PLAYING)
        startProgressTracking()
      } else {
        val playbackState = exoPlayer?.playbackState ?: Player.STATE_IDLE
        if (playbackState == Player.STATE_ENDED) {
          updateState(VideoPreviewState.ENDED)
        } else if (playbackState == Player.STATE_READY) {
          updateState(VideoPreviewState.PAUSED)
        }
        stopProgressTracking()
      }
    }

    override fun onPlayerError(error: androidx.media3.common.PlaybackException) {
      Log.e(TAG, "Player error: ${error.message}", error)
      updateState(VideoPreviewState.ERROR)
      stopProgressTracking()
    }

    override fun onVideoSizeChanged(videoSize: VideoSize) {
      Log.d(TAG, "Video size changed: ${videoSize.width}x${videoSize.height}")
    }

    // Handle duration changes properly
    override fun onTimelineChanged(timeline: androidx.media3.common.Timeline, reason: Int) {
      notifyDuration()
    }

    // Handle seek completion to update progress immediately
    override fun onSeekBackIncrementChanged(seekBackIncrementMs: Long) {
      notifyProgress()
    }
  }

  fun createView(): View {
    Log.d(TAG, "Creating video preview view for id: $id")

    // Initialize ExoPlayer
    exoPlayer = ExoPlayer.Builder(context).build().apply {
      addListener(playerListener)
    }

    // Create PlayerView
    playerView = PlayerView(context).apply {
      player = exoPlayer
      useController = false // We'll control playback through our API
      layoutParams = android.view.ViewGroup.LayoutParams(
        android.view.ViewGroup.LayoutParams.MATCH_PARENT,
        android.view.ViewGroup.LayoutParams.MATCH_PARENT
      )
    }

    // Initialize Transformer
//        transformer = Transformer.Builder(context)
//            .build()

    return playerView!!
  }

  private fun startProgressTracking() {
    if (isProgressTracking) return

    isProgressTracking = true
    progressRunnable = object : Runnable {
      override fun run() {
        if (isProgressTracking) {
          notifyProgress()
          progressHandler.postDelayed(this, 100) // Update every 100ms
        }
      }
    }
    progressHandler.post(progressRunnable!!)
    Log.d(TAG, "Started progress tracking for player $id")
  }

  private fun stopProgressTracking() {
    if (!isProgressTracking) return

    isProgressTracking = false
    progressRunnable?.let { runnable ->
      progressHandler.removeCallbacks(runnable)
    }
    progressRunnable = null
    Log.d(TAG, "Stopped progress tracking for player $id")
  }

  private fun notifyProgress() {
    exoPlayer?.let { player ->
      if (player.duration != androidx.media3.common.C.TIME_UNSET) {
        progressCallback?.invoke(id, player.currentPosition)
      }
    }
  }

  fun loadVideoFile(filePath: String): Int {
    try {
      val file = File(filePath)
      if (!file.exists()) {
        Log.e(TAG, "Video file not found: $filePath")
        return ERROR_FILE_NOT_FOUND
      }

      // Reset tracking variables
      lastNotifiedDuration = 0
      stopProgressTracking()

      val mediaItem = MediaItem.fromUri(Uri.fromFile(file))
      originalMediaItem = mediaItem

      // If we have a current filter, apply it during loading
      if (currentLutPath != null) {
        applyLutFilterToVideo(mediaItem, currentLutPath!!)
      } else {
        // Load video directly without filter
        exoPlayer?.setMediaItem(mediaItem)
        exoPlayer?.prepare()
      }

      Log.d(TAG, "Video file loaded: $filePath")
      updateState(VideoPreviewState.STOPPED)
      return SUCCESS
    } catch (e: Exception) {
      Log.e(TAG, "Failed to load video file: ${e.message}", e)
      updateState(VideoPreviewState.ERROR)
      return ERROR_PLAYER_CREATION_FAILED
    }
  }

  fun loadFilterFile(filePath: String): Int {
    try {
      val file = File(filePath)
      if (!file.exists()) {
        Log.e(TAG, "Filter file not found: $filePath")
        return ERROR_FILE_NOT_FOUND
      }

      currentLutPath = filePath

      // If we have a loaded video, apply the filter
      originalMediaItem?.let { mediaItem ->
        applyLutFilterToVideo(mediaItem, filePath)
      }

      Log.d(TAG, "Filter file loaded: $filePath")
      return SUCCESS
    } catch (e: Exception) {
      Log.e(TAG, "Failed to load filter file: ${e.message}", e)
      return ERROR_FILTER_CREATION_FAILED
    }
  }

  private fun applyLutFilterToVideo(mediaItem: MediaItem, lutPath: String) {
//        try {
//            // Create a temporary output file for the transformed video
//            val outputFile = File(context.cacheDir, "filtered_video_${id}_${System.currentTimeMillis()}.mp4")
//
//            // Create LUT effect
//            val lutEffect = createLutEffect(lutPath)
//            val effects = Effects(
//                /* audioEffects = */ emptyList(),
//                /* videoEffects = */ listOf(lutEffect)
//            )
//
//            // Create transformation request
//            val transformationRequest = TransformationRequest.Builder()
//                .setEffects(effects)
//                .build()
//
//            // Start transformation
//            transformer?.start(
//                mediaItem,
//                outputFile.absolutePath,
//                transformationRequest
//            )
//
//            // Set up transformation listener
//            transformer?.setListener(object : Transformer.Listener {
//                override fun onTransformationCompleted(mediaItem: MediaItem) {
//                    Log.d(TAG, "Transformation completed, loading filtered video")
//                    // Load the transformed video
//                    val filteredMediaItem = MediaItem.fromUri(Uri.fromFile(outputFile))
//                    exoPlayer?.setMediaItem(filteredMediaItem)
//                    exoPlayer?.prepare()
//                }
//
//                override fun onTransformationError(
//                    mediaItem: MediaItem,
//                    exception: androidx.media3.transformer.TransformationException
//                ) {
//                    Log.e(TAG, "Transformation error: ${exception.message}", exception)
//                    // Fall back to original video without filter
//                    exoPlayer?.setMediaItem(mediaItem)
//                    exoPlayer?.prepare()
//                }
//            })
//
//        } catch (e: Exception) {
//            Log.e(TAG, "Failed to apply LUT filter: ${e.message}", e)
//            // Fall back to original video without filter
//            exoPlayer?.setMediaItem(mediaItem)
//            exoPlayer?.prepare()
//        }
  }

//    private fun createLutEffect(lutPath: String): VideoProcessor.Factory {
//        // Use our custom LUT video processor factory
//        return LutVideoProcessorFactory(lutPath)
//    }

  fun removeFilter() {
    currentLutPath = null

    // Reload original video without filter
    originalMediaItem?.let { mediaItem ->
      exoPlayer?.setMediaItem(mediaItem)
      exoPlayer?.prepare()
    }

    Log.d(TAG, "Filter removed")
  }

  fun play() {
    exoPlayer?.let { player ->
      player.play()
      Log.d(TAG, "Playing video")
    } ?: Log.e(TAG, "Cannot play: no player")
  }

  fun pause() {
    exoPlayer?.let { player ->
      player.pause()
      Log.d(TAG, "Pausing video")
    } ?: Log.e(TAG, "Cannot pause: no player")
  }

  fun seekTo(timeMs: Long) {
    exoPlayer?.let { player ->
      player.seekTo(timeMs)

      progressHandler.postDelayed({ notifyProgress() }, 50) // Small delay to ensure seek is processed
    } ?: Log.e(TAG, "Cannot seek: no player")
  }

  fun setStateCallbacks(
    stateCallback: IntegerValueCallback?,
    durationCallback: IntegerValueCallback?,
    progressCallback: IntegerValueCallback?,
  ) {
    this.stateCallback = stateCallback
    this.durationCallback = durationCallback
    this.progressCallback = progressCallback

    // Notify current state and duration
    notifyStateChange()
    notifyDuration()

    // If player is currently playing, start progress tracking
    if (currentState == VideoPreviewState.PLAYING) {
      startProgressTracking()
    }
  }

  fun removeStateCallbacks() {
    this.stateCallback = null
    this.progressCallback = null
    this.durationCallback = null
    stopProgressTracking()
  }

  private fun updateState(newState: VideoPreviewState) {
    if (currentState != newState) {
      currentState = newState
      notifyStateChange()
      Log.d(TAG, "State changed to: $newState for player $id")
    }
  }

  private fun notifyStateChange() {
    stateCallback?.invoke(id, currentState.value.toLong())
  }

  private fun notifyDuration() {
    exoPlayer?.let { player ->
      if (player.duration != androidx.media3.common.C.TIME_UNSET) {
        if (kotlin.math.abs(player.duration - lastNotifiedDuration) > 100) {
          lastNotifiedDuration = player.duration
          durationCallback?.invoke(id, player.duration)
        }
      }
    }
  }

  fun cleanup() {
    Log.d(TAG, "Cleaning up video preview: $id")

    // Stop progress tracking
    stopProgressTracking()

    // Stop any ongoing transformation
//        transformer?.cancel()
//        transformer = null

    exoPlayer?.removeListener(playerListener)
    exoPlayer?.release()
    exoPlayer = null

    playerView?.player = null
    playerView = null

    currentLutPath = null
    originalMediaItem = null
    lastNotifiedDuration = 0
    removeStateCallbacks()

    // Clean up temporary files
    cleanupTemporaryFiles()
  }

  private fun cleanupTemporaryFiles() {
    try {
      val cacheDir = context.cacheDir
      cacheDir.listFiles { file ->
        file.name.startsWith("filtered_video_${id}_")
      }?.forEach { file ->
        if (file.delete()) {
          Log.d(TAG, "Deleted temporary file: ${file.name}")
        }
      }
    } catch (e: Exception) {
      Log.w(TAG, "Failed to cleanup temporary files: ${e.message}")
    }
  }

  companion object {
    private const val TAG = "VideoPreview"

    // Error codes matching iOS implementation
    const val SUCCESS = 0
    const val ERROR_FILE_NOT_FOUND = -1
    const val ERROR_PLAYER_CREATION_FAILED = -2
    const val ERROR_FILTER_CREATION_FAILED = -3
  }
}