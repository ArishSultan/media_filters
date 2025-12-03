import UIKit
import CoreImage
import AVFoundation
import Metal

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

      // Declare targetStorageSize in outer scope
      var targetStorageSize: CGSize = .zero
      var targetDisplaySize: CGSize = .zero
      var preferredTransform: CGAffineTransform = .identity

      do {
        guard let sourceVideoTrack = asset.tracks(withMediaType: .video).first else {
          reportError("Source file does not contain a video track.")
          return
        }
        videoTrack = sourceVideoTrack
        let audioTracks = asset.tracks(withMediaType: .audio)

        // Get original transform
        preferredTransform = videoTrack.preferredTransform
        // print("PREFFERED TRANSFORM \(preferredTransform.isIdentity)  a: \(preferredTransform.a)\nb: \(preferredTransform.b)\nc: \(preferredTransform.c)\nd: \(preferredTransform.d)\ntx: \(preferredTransform.tx)\nty: \(preferredTransform.ty) ")

        // Calculate the target video size
        let naturalSize = videoTrack.naturalSize

        // Determine if rotation is 90° or 270°
        let isRotated = abs(preferredTransform.a) == 0 && abs(preferredTransform.b) == 1

        // Calculate display size (after applying transform)
        var displaySize = naturalSize.applying(preferredTransform)
        displaySize = CGSize(width: abs(displaySize.width), height: abs(displaySize.height))

        // Calculate target display size
        targetDisplaySize = displaySize
        if width > 0 || height > 0 {
          if preserveAspectRatio {
            let aspectRatio = displaySize.width / displaySize.height
            if width > 0 && height > 0 {
              // Both dimensions specified - fit within bounds
              let targetRatio = CGFloat(width) / CGFloat(height)
              if aspectRatio > targetRatio {
                targetDisplaySize.width = CGFloat(width)
                targetDisplaySize.height = targetDisplaySize.width / aspectRatio
              } else {
                targetDisplaySize.height = CGFloat(height)
                targetDisplaySize.width = targetDisplaySize.height * aspectRatio
              }
            } else if height > 0 {
              targetDisplaySize.height = CGFloat(height)
              targetDisplaySize.width = targetDisplaySize.height * aspectRatio
            } else {
              targetDisplaySize.width = CGFloat(width)
              targetDisplaySize.height = targetDisplaySize.width / aspectRatio
            }
          } else {
            if width > 0 { targetDisplaySize.width = CGFloat(width) }
            if height > 0 { targetDisplaySize.height = CGFloat(height) }
          }
        }

        // Calculate storage size (what we write to file)
        targetStorageSize = isRotated ?
          CGSize(width: targetDisplaySize.height, height: targetDisplaySize.width) :
          targetDisplaySize

        // Ensure even dimensions
        targetStorageSize.width = floor(targetStorageSize.width / 2) * 2
        targetStorageSize.height = floor(targetStorageSize.height / 2) * 2
        targetDisplaySize.width = floor(targetDisplaySize.width / 2) * 2
        targetDisplaySize.height = floor(targetDisplaySize.height / 2) * 2

        reader = try AVAssetReader(asset: asset)
        writer = try AVAssetWriter(url: dstUrl, fileType: .mov)

        // Configure video reader output
        let videoReaderSettings: [String: Any] = [
          kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
          kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]
        videoReaderOutput = AVAssetReaderTrackOutput(
          track: videoTrack,
          outputSettings: videoReaderSettings
        )
        videoReaderOutput.alwaysCopiesSampleData = false
        if reader.canAdd(videoReaderOutput) { reader.add(videoReaderOutput) }

        // Configure video writer input
        let videoWriterSettings: [String: Any] = [
          AVVideoCodecKey: AVVideoCodecType.h264,
          AVVideoWidthKey: targetStorageSize.width,
          AVVideoHeightKey: targetStorageSize.height,
          AVVideoCompressionPropertiesKey: [
            AVVideoAverageBitRateKey: Int(targetStorageSize.width * targetStorageSize.height * 4),
            AVVideoExpectedSourceFrameRateKey: videoTrack.nominalFrameRate,
            AVVideoMaxKeyFrameIntervalKey: 60,
            AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
          ]
        ]
        videoWriterInput = AVAssetWriterInput(
          mediaType: .video,
          outputSettings: videoWriterSettings
        )
        videoWriterInput.transform = preferredTransform
        videoWriterInput.expectsMediaDataInRealTime = false

        // Pixel buffer attributes
        let pixelBufferAttributes: [String: Any] = [
          kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
          kCVPixelBufferWidthKey as String: targetStorageSize.width,
          kCVPixelBufferHeightKey as String: targetStorageSize.height,
          kCVPixelBufferCGImageCompatibilityKey as String: true,
          kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
          kCVPixelBufferIOSurfacePropertiesKey as String: [:],
          kCVPixelBufferMetalCompatibilityKey as String: true
        ]
        pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
          assetWriterInput: videoWriterInput,
          sourcePixelBufferAttributes: pixelBufferAttributes
        )
        if writer.canAdd(videoWriterInput) { writer.add(videoWriterInput) }

        // Configure audio pass-through
        for audioTrack in audioTracks {
          let audioReaderOutput = AVAssetReaderTrackOutput(
            track: audioTrack,
            outputSettings: nil
          )
          audioReaderOutput.alwaysCopiesSampleData = false
          if reader.canAdd(audioReaderOutput) {
            reader.add(audioReaderOutput)
            audioReaderOutputs.append(audioReaderOutput)

            let audioWriterInput = AVAssetWriterInput(
              mediaType: .audio,
              outputSettings: nil
            )
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

      let processingQueue = DispatchQueue(label: "media-processing-queue", qos: .userInteractive)
      let dispatchGroup = DispatchGroup()

      let durationInSeconds = CMTimeGetSeconds(asset.duration)
      let frameRate = videoTrack.nominalFrameRate
      let totalFrames = max(1, Int(durationInSeconds * Double(frameRate)))
      var framesProcessed: Int = 0
      let progressReportThreshold = max(1, totalFrames / 100)

      var ciContext: CIContext
      if let metalDevice = MTLCreateSystemDefaultDevice() {
        ciContext = CIContext(mtlDevice: metalDevice, options: [
          .workingColorSpace: CGColorSpace(name: CGColorSpace.linearSRGB)!,
          .outputPremultiplied: true,
          .cacheIntermediates: false
        ])
      } else {
        ciContext = CIContext(options: [
          .workingColorSpace: CGColorSpace(name: CGColorSpace.linearSRGB)!,
          .outputPremultiplied: true,
          .useSoftwareRenderer: false
        ])
      }

      let filter: CIFilter = filters.getCiFilter(!preferredTransform.isIdentity)

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

      let processingSemaphore = DispatchSemaphore(value: 2)
      let appendSemaphore = DispatchSemaphore(value: 1)

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

              processingSemaphore.wait()

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

              // Apply filters
              // 1. Create the raw image
              let rawImage = CIImage(cvPixelBuffer: pixelBuffer)

              // 2. DETECT ORIENTATION CORRECTLY
              // This logic checks if the video has a rotation metadata (preferredTransform).
              // If it does (like iOS Portrait video), we apply it to make the image Upright.
              // If it doesn't (like a Landscape video or pre-rendered Android video), this transform is likely .identity.

              var workingImage = rawImage.transformed(by: preferredTransform)

              // CORRECTION 1: Fix Origin Shift
              // Rotations often throw the image origin into negative coordinates.
              // We force the origin back to (0,0) so the filter applies at the correct "bottom-left" of the visible area.
              workingImage = workingImage.transformed(by: CGAffineTransform(
                  translationX: -workingImage.extent.origin.x,
                  y: -workingImage.extent.origin.y
              ))

              // 3. APPLY FILTER
              // Now workingImage is guaranteed to be "Upright" and at (0,0).
              filter.setValue(workingImage, forKey: kCIInputImageKey)

              guard let filteredImage = filter.outputImage else {
                  processingSemaphore.signal()
                  CMSampleBufferInvalidate(sampleBuffer)
                  return
              }

              // 4. PREPARE FOR OUTPUT
              // The AVAssetWriter expects frames in the *original* raw orientation (e.g., sideways for Portrait video).
              // We must undo the rotation we did in step 2.

              var finalImage = filteredImage.transformed(by: preferredTransform.inverted())

              // CORRECTION 2: Fix Origin Shift (Again)
              // The inverse rotation might also throw coordinates off. Fix them again.
              finalImage = finalImage.transformed(by: CGAffineTransform(
                  translationX: -finalImage.extent.origin.x,
                  y: -finalImage.extent.origin.y
              ))

              // 5. SCALE TO BUFFER
              // This ensures that whether the video was Landscape or Portrait, 
              // the final image fits perfectly into the pixel buffer we are about to write.
              let targetWidth = CGFloat(CVPixelBufferGetWidth(outputBuffer))
              let targetHeight = CGFloat(CVPixelBufferGetHeight(outputBuffer))

              // We use the extent of the *rotated* image to calculate scale.
              let scaleX = targetWidth / finalImage.extent.width
              let scaleY = targetHeight / finalImage.extent.height

              // Scale to fit (stretching if necessary to fill the buffer completely)
              finalImage = finalImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

              // Center (safety measure)
              let offsetX = (targetWidth - finalImage.extent.width) / 2
              let offsetY = (targetHeight - finalImage.extent.height) / 2
              finalImage = finalImage.transformed(by: CGAffineTransform(translationX: offsetX, y: offsetY))

              // 6. RENDER
              CVPixelBufferLockBaseAddress(outputBuffer, [])
              ciContext.render(
                  finalImage,
                  to: outputBuffer,
                  bounds: CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight),
                  colorSpace: rawImage.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)
              )
              CVPixelBufferUnlockBaseAddress(outputBuffer, [])
              // }

                appendSemaphore.wait()
                let appendSuccess = pixelBufferAdaptor.append(outputBuffer, withPresentationTime: presentationTime)
                appendSemaphore.signal()

                if !appendSuccess {
                  processingSemaphore.signal()
                  reportError("Failed to append processed frame. Writer status: \(writer.status.rawValue)")
                  return
                }
              // }

              processingSemaphore.signal()
              CMSampleBufferInvalidate(sampleBuffer)

              framesProcessed += 1
              if framesProcessed % progressReportThreshold == 0 || framesProcessed == totalFrames {
                let progress = min(1.0, Float(framesProcessed) / Float(totalFrames))
                DispatchQueue.main.async {
                  onProgress(id, progress)
                }
              }

            } else {
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

      // Process Audio Tracks
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
              } else {
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
              onProgress(id, 1.0)
              onCompletion(id)
            case .failed:
              reportError("The writer failed to save the video: \(writer.error?.localizedDescription ?? "Unknown error")")
            case .cancelled:
              reportError("Video processing was cancelled.")
            default: break
            }
          }
        }
      }
    }
  }
}
