package dev.arish.media_filters

import android.content.Context
import android.util.Log
import java.util.concurrent.ConcurrentHashMap

class VideoPreviewManager private constructor() {
    private val previews = ConcurrentHashMap<Int, VideoPreview>()
    
    companion object {
        @Volatile
        private var INSTANCE: VideoPreviewManager? = null
        
        fun getInstance(): VideoPreviewManager {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: VideoPreviewManager().also { INSTANCE = it }
            }
        }
        
        private const val TAG = "VideoPreviewManager"
    }
    
    fun getCount(): Int = previews.size
    
    fun createPreview(viewId: Int, context: Context): VideoPreview {
        return previews.getOrPut(viewId) {
            Log.d(TAG, "Creating new video preview with ID: $viewId")
            VideoPreview(viewId, context)
        }
    }
    
    fun getPreview(viewId: Int): VideoPreview? {
        return previews[viewId]
    }
    
    fun destroyPreview(viewId: Int) {
        previews.remove(viewId)?.let { preview ->
            Log.d(TAG, "Destroying video preview with ID: $viewId")
            preview.cleanup()
        }
    }
    
    fun destroyAllPreviews() {
        Log.d(TAG, "Destroying all video previews")
        previews.values.forEach { it.cleanup() }
        previews.clear()
    }
}