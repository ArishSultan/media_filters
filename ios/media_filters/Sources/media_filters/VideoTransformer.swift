import UIKit
import CoreImage
import AVFoundation
import Metal

///
public class VideoTransformer {
  public static func transform(
    id: Int,
    
    width: Float,
    height: Float,
    preserveAspectRatio: Bool,
    
    srcUrl: URL,
    dstUrl: URL,
    filters: MediaFilters,
    
    onProgress: @escaping FloatValueCallback,
    onCompletion: @escaping VoidCallback,
    onError: @escaping StringValueCallback
  ) {
    func reportError(_ message: String) {
      message.withCString { cString in onError(id, cString) }
    }
    
    DispatchQueue.global(qos: .userInitiated).async {
      try? FileManager.default.removeItem(at: dstUrl)
      
      let asset = AVAsset(url: srcUrl)
      let reader: AVAssetReader
      let writer: AVAssetWriter
      
      let videoTrack: AVAssetTrack
      let videoReaderOutput: AVAssetReaderTrackOutput
      let videoWriterInput: AVAssetWriterInput
      let pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor
      
      var audioReaderOutputs: [AVAssetReaderTrackOutput] = []
      var audioWriterInputs: [AVAssetWriterInput] = []
      
      do {
        guard let sourceVideoTrack = asset.tracks(withMediaType: .video).first else {
          reportError("Source file does not contain a video track.")
          return
        }
        videoTrack = sourceVideoTrack
        let audioTracks = asset.tracks(withMediaType: .audio)
        
        // Calculate the target video size
        let naturalSize = videoTrack.naturalSize
        let preferredTransform = videoTrack.preferredTransform
        let originalSize = naturalSize.applying(preferredTransform)
        let positiveSize = CGSize(width: abs(originalSize.width), height: abs(originalSize.height))
        
        var targetSize = positiveSize
        if width > 0 || height > 0 {
          if preserveAspectRatio {
            let aspectRatio = positiveSize.width / positiveSize.height
            if height > 0 { // Height takes precedence
              targetSize.height = CGFloat(height)
              targetSize.width = targetSize.height * aspectRatio
            } else { // Only width is given
              targetSize.width = CGFloat(width)
              targetSize.height = targetSize.width / aspectRatio
            }
          } else { // Stretch to fit
            if width > 0 { targetSize.width = CGFloat(width) }
            if height > 0 { targetSize.height = CGFloat(height) }
          }
        }
        // Ensure dimensions are even numbers, which is required by many codecs
        targetSize.width = floor(targetSize.width / 2) * 2
        targetSize.height = floor(targetSize.height / 2) * 2
        
        reader = try AVAssetReader(asset: asset)
        writer = try AVAssetWriter(url: dstUrl, fileType: .mov)
        
        // Configure video reader output to provide BGRA frames for CoreImage
        let videoReaderSettings: [String: Any] = [
          kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
          kCVPixelBufferIOSurfacePropertiesKey as String: [:] // Enable IOSurface for better GPU performance
        ]
        videoReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: videoReaderSettings)
        videoReaderOutput.alwaysCopiesSampleData = false // Avoid unnecessary copies
        if reader.canAdd(videoReaderOutput) { reader.add(videoReaderOutput) }
        
        // Configure video writer input with target size and codec
        let videoWriterSettings: [String: Any] = [
          AVVideoCodecKey: AVVideoCodecType.h264,
          AVVideoWidthKey: targetSize.width,
          AVVideoHeightKey: targetSize.height,
          AVVideoCompressionPropertiesKey: [
            AVVideoAverageBitRateKey: Int(targetSize.width * targetSize.height * 4), // Adjust bitrate based on size
            AVVideoExpectedSourceFrameRateKey: videoTrack.nominalFrameRate,
            AVVideoMaxKeyFrameIntervalKey: 60,
            AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
          ]
        ]
        videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoWriterSettings)
        videoWriterInput.transform = preferredTransform // Preserve original orientation
        videoWriterInput.expectsMediaDataInRealTime = false // Better performance for non-realtime
        
        let pixelBufferAttributes: [String: Any] = [
          kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
          kCVPixelBufferWidthKey as String: targetSize.width,
          kCVPixelBufferHeightKey as String: targetSize.height,
          kCVPixelBufferCGImageCompatibilityKey as String: true,
          kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
          kCVPixelBufferIOSurfacePropertiesKey as String: [:], // Enable IOSurface
          kCVPixelBufferMetalCompatibilityKey as String: true // Enable Metal compatibility
        ]
        pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput, sourcePixelBufferAttributes: pixelBufferAttributes)
        if writer.canAdd(videoWriterInput) { writer.add(videoWriterInput) }
        
        // Configure pass-through for all audio tracks
        for audioTrack in audioTracks {
          let audioReaderOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: nil)
          audioReaderOutput.alwaysCopiesSampleData = false
          if reader.canAdd(audioReaderOutput) {
            reader.add(audioReaderOutput)
            audioReaderOutputs.append(audioReaderOutput)
            
            let audioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: nil)
            audioWriterInput.expectsMediaDataInRealTime = false
            if writer.canAdd(audioWriterInput) {
              writer.add(audioWriterInput)
              audioWriterInputs.append(audioWriterInput)
            }
          }
        }
        
      } catch {
        reportError("AVFoundation setup failed: \(error.localizedDescription)")
        return
      }
      
      guard reader.startReading(), writer.startWriting() else {
        reportError("Failed to start reader/writer. Reader: \(reader.error?.localizedDescription ?? "OK"), Writer: \(writer.error?.localizedDescription ?? "OK")")
        reader.cancelReading()
        return
      }
      writer.startSession(atSourceTime: .zero)
      
      // Create high-priority processing queue
      let processingQueue = DispatchQueue(label: "media-processing-queue", qos: .userInteractive, attributes: [])
      let dispatchGroup = DispatchGroup()
      
      // Estimate total frames for progress reporting
      let durationInSeconds = CMTimeGetSeconds(asset.duration)
      let frameRate = videoTrack.nominalFrameRate
      let totalFrames = max(1, Int(durationInSeconds * Double(frameRate)))
      var framesProcessed: Int = 0
      let progressReportThreshold = max(1, totalFrames / 100) // Report every 1%
      
      // Create Metal-accelerated CIContext
      var ciContext: CIContext
      if let metalDevice = MTLCreateSystemDefaultDevice() {
        ciContext = CIContext(mtlDevice: metalDevice, options: [
          .workingColorSpace: CGColorSpaceCreateDeviceRGB(),
          .outputPremultiplied: true,
          .cacheIntermediates: false,
          .name: "VideoTransformer",
          .priorityRequestLow: false
        ])
      } else {
        // Fallback to non-Metal context
        ciContext = CIContext(options: [
          .workingColorSpace: CGColorSpaceCreateDeviceRGB(),
          .outputPremultiplied: true,
          .useSoftwareRenderer: false
        ])
      }
      
      let colorSpace = CGColorSpaceCreateDeviceRGB()
      let filter: CIFilter = filters.ciFilter
      
      // Pre-allocate pixel buffers for better performance
      var pixelBufferCache: [CVPixelBuffer] = []
      for _ in 0..<3 {
        var pixelBuffer: CVPixelBuffer?
        if let pool = pixelBufferAdaptor.pixelBufferPool {
          CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer)
          if let buffer = pixelBuffer {
            pixelBufferCache.append(buffer)
          }
        }
      }
      var bufferIndex = 0
      
      // Create semaphore for controlled concurrent processing
      let processingSemaphore = DispatchSemaphore(value: 2) // Process 2 frames concurrently
      let appendSemaphore = DispatchSemaphore(value: 1) // Serialize appends
      
      // Process Video Track
      dispatchGroup.enter()
      videoWriterInput.requestMediaDataWhenReady(on: processingQueue) {
        while videoWriterInput.isReadyForMoreMediaData {
          autoreleasepool {
            if let sampleBuffer = videoReaderOutput.copyNextSampleBuffer() {
              guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                CMSampleBufferInvalidate(sampleBuffer)
                return
              }
              
              let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
              
              // Process frame
              processingSemaphore.wait()
              
              // Get output buffer from cache or create new one
              var outputPixelBuffer: CVPixelBuffer?
              if bufferIndex < pixelBufferCache.count {
                outputPixelBuffer = pixelBufferCache[bufferIndex % pixelBufferCache.count]
              } else {
                CVPixelBufferPoolCreatePixelBuffer(nil, pixelBufferAdaptor.pixelBufferPool!, &outputPixelBuffer)
              }
              bufferIndex += 1
              
              guard let outputBuffer = outputPixelBuffer else {
                processingSemaphore.signal()
                reportError("Failed to create output pixel buffer")
                return
              }
              
              // Apply filters using Metal-accelerated rendering
              let sourceImage = CIImage(cvPixelBuffer: pixelBuffer)
              filter.setValue(sourceImage, forKey: kCIInputImageKey)
              
              if let filteredImage = filter.outputImage {
                // Clear the output buffer first (important for transparency)
                CVPixelBufferLockBaseAddress(outputBuffer, [])
                ciContext.render(filteredImage, to: outputBuffer, bounds: filteredImage.extent, colorSpace: colorSpace)
                CVPixelBufferUnlockBaseAddress(outputBuffer, [])
                
                // Serialize append operations
                appendSemaphore.wait()
                let appendSuccess = pixelBufferAdaptor.append(outputBuffer, withPresentationTime: presentationTime)
                appendSemaphore.signal()
                
                if !appendSuccess {
                  processingSemaphore.signal()
                  reportError("Failed to append processed frame. Writer status: \(writer.status.rawValue)")
                  return
                }
              }
              
              processingSemaphore.signal()
              CMSampleBufferInvalidate(sampleBuffer)
              
              // Update progress
              framesProcessed += 1
              if framesProcessed % progressReportThreshold == 0 || framesProcessed == totalFrames {
                let progress = min(1.0, Float(framesProcessed) / Float(totalFrames))
                DispatchQueue.main.async {
                  onProgress(id, progress)
                }
              }
              
            } else { // End of video track
              // Wait for all processing to complete
              for _ in 0..<2 {
                processingSemaphore.wait()
                processingSemaphore.signal()
              }
              videoWriterInput.markAsFinished()
              dispatchGroup.leave()
              return
            }
          }
        }
      }
      
      // Process Audio Tracks (Pass-through with optimizations)
      for i in 0..<audioWriterInputs.count {
        dispatchGroup.enter()
        let audioWriterInput = audioWriterInputs[i]
        let audioReaderOutput = audioReaderOutputs[i]
        
        audioWriterInput.requestMediaDataWhenReady(on: processingQueue) {
          while audioWriterInput.isReadyForMoreMediaData {
            autoreleasepool {
              if let sampleBuffer = audioReaderOutput.copyNextSampleBuffer() {
                if !audioWriterInput.append(sampleBuffer) {
                  CMSampleBufferInvalidate(sampleBuffer)
                  return
                }
                CMSampleBufferInvalidate(sampleBuffer)
              } else { // End of audio track
                audioWriterInput.markAsFinished()
                dispatchGroup.leave()
                return
              }
            }
          }
        }
      }
      
      // Finalize
      dispatchGroup.notify(queue: .main) {
        if reader.status == .failed {
          reportError("Processing failed because the reader encountered an error: \(reader.error?.localizedDescription ?? "Unknown error")")
          writer.cancelWriting()
          return
        }
        
        writer.finishWriting {
          DispatchQueue.main.async {
            switch writer.status {
            case .completed:
              print("Video processing completed successfully.")
              onProgress(id, 1.0) // Ensure progress hits 100%
              onCompletion(id)
            case .failed:
              reportError("The writer failed to save the video: \(writer.error?.localizedDescription ?? "Unknown error")")
            case .cancelled:
              reportError("Video processing was cancelled.")
            default:
              break
            }
          }
        }
      }
    }
  }
}
