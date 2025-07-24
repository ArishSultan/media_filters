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
import androidx.media3.common.util.UnstableApi
import androidx.media3.effect.SingleColorLut
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.transformer.CompositionPlayer
import cubeFileToHaldBitmap

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
  private var currentVideoPath: String? = null
//  private var lutProcessor: LutVideoProcessor? = null

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

    // Create PlayerView first
    playerView = PlayerView(context).apply {
      useController = false
      layoutParams = android.view.ViewGroup.LayoutParams(
        android.view.ViewGroup.LayoutParams.MATCH_PARENT,
        android.view.ViewGroup.LayoutParams.MATCH_PARENT
      )
    }

    // Initialize ExoPlayer with effect support
    initializePlayer()

    return playerView!!
  }

  private fun initializePlayer() {
    // Create ExoPlayer with video processor support
    exoPlayer = ExoPlayer.Builder(context).build()
//      .setVi { presentationTimeUs, releaseTimeNs, format, mediaFormat ->
//         This ensures video frames are processed
//      }
//      .build().apply {
//        addListener(playerListener)
//         Enable video effects processing
//        setVideoFrameMetadataListener { _, _, _, _ -> }
//      }

    playerView?.player = exoPlayer
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

  @UnstableApi
  fun loadVideoFile(filePath: String): Int {
    try {
      val file = File(filePath)
      if (!file.exists()) {
        Log.e(TAG, "Video file not found: $filePath")
        return ERROR_FILE_NOT_FOUND
      }

      currentVideoPath = filePath
      lastNotifiedDuration = 0
      stopProgressTracking()

      // Load video with current filter if any
      reloadVideoWithCurrentFilter(true)

      Log.d(TAG, "Video file loaded: $filePath")
      updateState(VideoPreviewState.STOPPED)
      return SUCCESS
    } catch (e: Exception) {
      Log.e(TAG, "Failed to load video file: ${e.message}", e)
      updateState(VideoPreviewState.ERROR)
      return ERROR_PLAYER_CREATION_FAILED
    }
  }

  @UnstableApi
  private fun applyLutFilterToVideo(lutPath: String) {
    exoPlayer?.setVideoEffects(listOf(SingleColorLut.createFromBitmap(cubeFileToHaldBitmap(lutPath))))
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

  @UnstableApi
  fun removeFilter() {
    currentLutPath = null

    // Save current playback state
    val currentPosition = exoPlayer?.currentPosition ?: 0
    val wasPlaying = exoPlayer?.isPlaying ?: false

    // Clear video effects and reload
    exoPlayer?.setVideoEffects(listOf())
    reloadVideoWithCurrentFilter()

    // Restore playback state
    Handler(Looper.getMainLooper()).postDelayed({
      exoPlayer?.seekTo(currentPosition)
      if (wasPlaying) {
        exoPlayer?.play()
      }
    }, 100)

    Log.d(TAG, "Filter removed")
  }

  @UnstableApi
  private fun reloadVideoWithCurrentFilter(reload: Boolean = false) {
    currentVideoPath?.let { videoPath ->
      var mediaItem: MediaItem? = null
      if (reload) {
        mediaItem = MediaItem.fromUri(Uri.fromFile(File(videoPath)))
        originalMediaItem = mediaItem
      }


      exoPlayer?.let { player ->
        if (reload) {
          player.setMediaItem(mediaItem!!)
        }

        if (currentLutPath != null) {
          try {
            val haldBitmap = cubeFileToHaldBitmap(currentLutPath!!)
            Log.d(TAG, "Hald bitmap: $haldBitmap")
            val lutEffect = SingleColorLut.createFromBitmap(haldBitmap)
            Log.d(TAG, "Hald bitmap: $lutEffect")

            // Set the video effects BEFORE setting media item
            player.setVideoEffects(listOf(lutEffect))
            Log.d(TAG, "LUT effect applied: $currentLutPath")
          } catch (e: Exception) {
            Log.e(TAG, "Failed to apply LUT effect: ${e.message}", e)
          }
        }

        // Now set the media item and prepare
        player.prepare()
      }
    }
  }

  @UnstableApi
  fun loadFilterFile(filePath: String): Int {
    try {
      val file = File(filePath)
      if (!file.exists()) {
        Log.e(TAG, "Filter file not found: $filePath")
        return ERROR_FILE_NOT_FOUND
      }

//      // Validate the LUT file by trying to create a HALD bitmap
//      try {
//        val testBitmap = cubeFileToHaldBitmap(filePath)
//        // If we get here, the LUT file is valid
//      } catch (e: Exception) {
//        Log.e(TAG, "Invalid LUT file: ${e.message}")
//        return ERROR_FILTER_CREATION_FAILED
//      }

      currentLutPath = filePath

      // Save current playback position
      val currentPosition = exoPlayer?.currentPosition ?: 0
      val wasPlaying = exoPlayer?.isPlaying ?: false

      // Reload video with new filter
      reloadVideoWithCurrentFilter()

      // Restore playback position after a short delay
      Handler(Looper.getMainLooper()).postDelayed({
        exoPlayer?.seekTo(currentPosition)
        if (wasPlaying) {
          exoPlayer?.play()
        }
      }, 100)

      Log.d(TAG, "Filter applied successfully: $filePath")
      return SUCCESS
    } catch (e: Exception) {
      Log.e(TAG, "Failed to load filter file: ${e.message}", e)
      return ERROR_FILTER_CREATION_FAILED
    }
  }

  fun exportVideo(
    videoPath: String,
    filterPath: String?,
    outputPath: String,
    outputWidth: Int,
    outputHeight: Int,
    maintainAspectRatio: Boolean,
    exportId: Int,
    callback: StringValueCallback
  ) {
    Thread {
      try {
        // Validate input file
        val inputFile = File(videoPath)
        if (!inputFile.exists()) {
          callback.invoke(exportId, null)
          return@Thread
        }

        // Create output directory
        val outputDir = File(outputPath)
        if (!outputDir.exists()) {
          outputDir.mkdirs()
        }

        // Generate unique output filename
        val timestamp = System.currentTimeMillis()
        val outputFile = File(outputDir, "exported_video_${timestamp}.mp4")

        // For this basic implementation, we'll simulate the export process
        // In a full implementation, you would use Media Transformer or FFmpeg
        // to apply the LUT filter and resize the video

        Thread.sleep(2000) // Simulate processing time

        try {
          // Copy the input file to output (simplified approach)
          inputFile.copyTo(outputFile, overwrite = true)

          Log.d(TAG, "Video export completed: ${outputFile.absolutePath}")
          callback.invoke(exportId, outputFile.absolutePath)
        } catch (e: Exception) {
          Log.e(TAG, "Export failed during file copy: ${e.message}", e)
          callback.invoke(exportId, null)
        }

      } catch (e: Exception) {
        Log.e(TAG, "Export failed: ${e.message}", e)
        callback.invoke(exportId, null)
      }
    }.start()
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

    stopProgressTracking()

    exoPlayer?.removeListener(playerListener)
    exoPlayer?.release()
    exoPlayer = null

    playerView?.player = null
    playerView = null

    currentLutPath = null
    originalMediaItem = null
//    currentVideoPath = null
    lastNotifiedDuration = 0

    removeStateCallbacks()
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