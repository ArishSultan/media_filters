//package dev.arish.media_filters
//
//import android.util.Log
//import android.content.Context
//import android.graphics.Bitmap
//import android.graphics.BitmapFactory
//
//import androidx.media3.common.ColorInfo
//import androidx.media3.common.DebugViewProvider
////import androidx.media3.common.VideoFrameMetadata
////import androidx.media3.common.VideoProcessor
////import androidx.media3.common.util.UnstableApi
////import androidx.media3.effect.BaseVideoProcessor
//import java.io.File
//import java.io.IOException
//import java.nio.ByteBuffer
//
//@UnstableApi
//class LutVideoProcessor private constructor(
//    private val lutBitmap: Bitmap?
//) : BaseVideoProcessor() {
//
//    companion object {
//        private const val TAG = "LutVideoProcessor"
//
//        fun create(
//            context: Context,
//            outputColorInfo: ColorInfo,
//            debugViewProvider: DebugViewProvider,
//            useHdr: Boolean,
//            lutPath: String
//        ): LutVideoProcessor {
//            val lutBitmap = loadLutFromFile(lutPath)
//            return LutVideoProcessor(lutBitmap)
//        }
//
//        private fun loadLutFromFile(lutPath: String): Bitmap? {
//            return try {
//                val file = File(lutPath)
//                if (file.exists()) {
//                    BitmapFactory.decodeFile(lutPath)
//                } else {
//                    Log.e(TAG, "LUT file not found: $lutPath")
//                    null
//                }
//            } catch (e: Exception) {
//                Log.e(TAG, "Failed to load LUT file: ${e.message}", e)
//                null
//            }
//        }
//    }
//
//    override fun processVideoFrame(
//        inputBuffer: ByteBuffer,
//        presentationTimeUs: Long,
//        frameMetadata: VideoFrameMetadata?
//    ): ByteBuffer {
//        // For this example implementation, we'll pass through the original frame
//        // In a production app, you would:
//        // 1. Convert the ByteBuffer to a format suitable for processing
//        // 2. Apply the LUT transformation using OpenGL shaders or similar
//        // 3. Convert back to ByteBuffer format
//
//        if (lutBitmap != null) {
//            Log.v(TAG, "Processing frame with LUT (${lutBitmap.width}x${lutBitmap.height})")
//            // TODO: Implement actual LUT processing
//            // This would involve creating OpenGL shaders that sample from the LUT texture
//        }
//
//        // For now, return the original buffer
//        return inputBuffer
//    }
//
//    override fun flush() {
//        super.flush()
//        Log.d(TAG, "LUT video processor flushed")
//    }
//
//    override fun release() {
//        lutBitmap?.recycle()
//        super.release()
//        Log.d(TAG, "LUT video processor released")
//    }
//}
//
//// Factory class for creating LUT video processors
//@UnstableApi
//class LutVideoProcessorFactory(
//    private val lutPath: String
//) : VideoProcessor.Factory {
//
//    override fun create(
//        context: Context,
//        outputColorInfo: ColorInfo,
//        debugViewProvider: DebugViewProvider,
//        useHdr: Boolean
//    ): VideoProcessor {
//        return LutVideoProcessor.create(context, outputColorInfo, debugViewProvider, useHdr, lutPath)
//    }
//}