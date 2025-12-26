 import AVFoundation
 import CoreImage
 import Metal
 import UIKit

 enum AppError: Error {
     case customError(String)

 }


enum VideoQuality: CGFloat {
    case uhd4k = 2160
    case fhd1080 = 1080
    case hd720 = 720
    case sd480 = 480
    case sd360 = 360
}

 public class VideoTransformer {
   public static func transform(
     id: Int,
     width: Float,
     height: Float,
     preserveAspectRatio: Bool,
     srcUrl: URL,
    dstUrl: URL,
    overlayUrl: URL?,
    filters: MediaFilters,
     onProgress: @escaping (Float) -> Void

   ) async throws {



      let exportQuality: VideoQuality = 
      if width == 3840.0 && height == 2160.0 {
        // AVAssetExportPreset3840x2160
        .uhd4k
      } else if width == 1920.0 && height == 1080.0 {
        // AVAssetExportPreset1920x1080
        .fhd1080
      } else if width == 1280.0 && height == 720.0 {
        // AVAssetExportPreset1280x720
        .hd720
      } else if width == 854.0 && height == 480.0 {
        // AVAssetExportPreset640x480
        .sd480
      } else if width == 640.0 && height == 360.0 {
        // AVAssetExportPresetMediumQuality
        .sd360
      } else {
        // AVAssetExportPresetHighestQuality
        .fhd1080
      }


      // print("Export Target Size \(exportTargetSize)")

      func orientation(from transform: CGAffineTransform) -> (
       orientation: UIImage.Orientation, isPortrait: Bool
     ) {
       var assetOrientation = UIImage.Orientation.up
       var isPortrait = false
       if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
         assetOrientation = .right
         isPortrait = true
       } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
         assetOrientation = .left
         isPortrait = true
       } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
         assetOrientation = .up
       } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
         assetOrientation = .down
       }

       return (assetOrientation, isPortrait)
     }


     func calculateTargetSize(originalSize: CGSize, quality: VideoQuality, isPortrait: Bool) -> CGSize {
        let targetDimension = quality.rawValue
        // let isPortrait = originalSize.height > originalSize.width
        let aspectRatio = originalSize.width / originalSize.height
        
        var newWidth: CGFloat
        var newHeight: CGFloat
        
        if isPortrait {
            // Option A: "Social Media Style" (High Quality Portrait)
            // We set the WIDTH to the target (e.g., 1080 wide)
            newWidth = targetDimension
            newHeight = targetDimension / aspectRatio
            
            // Option B: "TV Style" (Fit inside TV screen)
            // If you prefer the video to fit INSIDE a 1920x1080 screen, uncomment this:
            /*
            newHeight = targetDimension
            newWidth = targetDimension * aspectRatio
            */
            
        } else {
            // Landscape: We set the HEIGHT to the target (Standard)
            newHeight = targetDimension
            newWidth = targetDimension * aspectRatio
        }
        
        // Ensure Divisible by 2 (Critical for Export)
        let finalWidth = floor(newWidth / 2.0) * 2.0
        let finalHeight = floor(newHeight / 2.0) * 2.0
        
        return CGSize(width: finalWidth, height: finalHeight)
      }


     func compositionLayerInstruction(for track: AVCompositionTrack, assetTrack: AVAssetTrack)
       -> AVMutableVideoCompositionLayerInstruction
     {
       let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
       let transform = assetTrack.preferredTransform

       instruction.setTransform(transform, at: .zero)

       return instruction
     }


     func resizeImage(inputImage: CIImage?, scale: Float, aspectRatio: Float) -> CIImage? {    
        guard let inputImage = inputImage else {
          return nil
        }

        let lanczosScaleFilter = CIFilter.lanczosScaleTransform()
        lanczosScaleFilter.inputImage = inputImage
        lanczosScaleFilter.scale = scale
        lanczosScaleFilter.aspectRatio = aspectRatio
        return lanczosScaleFilter.outputImage
    }



      // DispatchQueue.global(qos: .userInitiated).async {

       try? FileManager.default.removeItem(at: dstUrl)
       let asset = AVAsset(url: srcUrl)

       let composition = AVMutableComposition()

       guard
         let compositionTrack = composition.addMutableTrack(
           withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
         let assetTrack = asset.tracks(withMediaType: .video).first
       else {
         let assetTrack = asset.tracks(withMediaType: .video)
        //  print("Something is wrong with the asset. \(assetTrack.count)")
          // onComplete(nil)
         throw AppError.customError("Something is wrong with the asset.")
          // return
       }

       do {
         let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
         try compositionTrack.insertTimeRange(timeRange, of: assetTrack, at: .zero)

         if let audioAssetTrack = asset.tracks(withMediaType: .audio).first,
           let compositionAudioTrack = composition.addMutableTrack(
             withMediaType: .audio,
             preferredTrackID: kCMPersistentTrackID_Invalid)
         {
           try compositionAudioTrack.insertTimeRange(
             timeRange,
             of: audioAssetTrack,
             at: .zero)
         }
       } catch {
        //  print(error)
          // onComplete(nil)
          // onError()
         throw AppError.customError("Error while inserting time range to audio composition track")
          // return
       }

       compositionTrack.preferredTransform = assetTrack.preferredTransform
       let videoInfo = orientation(from: assetTrack.preferredTransform)

       let videoSize: CGSize
        if videoInfo.isPortrait {
          videoSize = CGSize(
            width: assetTrack.naturalSize.height,
            height: assetTrack.naturalSize.width)
        } else {
          videoSize = assetTrack.naturalSize
        }
      //   if videoInfo.isPortrait {
      //    videoSize =  CGSize(
      //      width: Double(height),
      //      height: Double(width))
      //  } else {
      //   videoSize =  CGSize(
      //      width: Double(width),
      //      height: Double(height)
      //      )
      //  }
      // //  print("Before creating filter")

        let targetSize =  calculateTargetSize(originalSize: videoSize, quality: exportQuality, isPortrait: videoInfo.isPortrait)
        let scale = Float(targetSize.height) / Float(videoSize.height)
        let aspectRatio = Float(targetSize.width)/(Float(videoSize.width) * scale)


       let filter: CIFilter = filters.ciFilter
      //  print("After creating filter")
       let videoComposition = AVMutableVideoComposition(
         asset: composition,
         applyingCIFiltersWithHandler: {  request in


          //  print("Before source image")
            let source = request.sourceImage 

          


            // print("SOURCE IMAGE SIZE \(source.extent.width)x\(source.extent.height)")
            // print("REQUEST RENDER SIZE \(request.renderSize.width)x\(request.renderSize.height)")

//            let scaleX =  request.renderSize.width / source.extent.width
//            let scaleY = request.renderSize.height / source.extent.height
//           //  print("After Setting value")
// // filter.outputImage?.transformed(by: CGAffineTransform(scaleX: , y: ))
//            if  let filteredImage = resizeImage(inputImage: filter.outputImage, scale: Float(scaleY), aspectRatio: Float(scaleX / scaleY)) {
          //  print("After source image")
           filter.setValue(source ,  forKey: kCIInputImageKey)
            // let scale = Float(request.renderSize.height) / Float(source.extent.height)
            // let aspectRatio = Float(request.renderSize.width)/(Float(source.extent.width) * scale)
          //  print("After Setting value")
// filter.outputImage?.transformed(by: CGAffineTransform(scaleX: , y: ))
           if  let filteredImage = resizeImage(inputImage: filter.outputImage, scale: scale, aspectRatio: aspectRatio) {
          //  print("Finish Perfectly")
             request.finish(with: filteredImage, context: nil)
           } else {
          //  print("Finish With error")
               request.finish(with: AppError.customError("Error while applying filter"))

           }

         }
       )


        // TODO (arbaz): Issue is here
       videoComposition.renderSize = targetSize
      //  videoSize

//      print("VIDEO COMPOSITION RENDER SIZE \(videoSize.width)x\(videoSize.height)")

      // videoComposition.renderSize = CGSize(width: Double(height), height: Double(width))

       videoComposition.frameDuration = CMTime(value: 1, timescale: 30)



      //  let videoComposition = AVMutableVideoComposition()

      // // 1. Set global properties
      // videoComposition.renderSize = videoSize
      // videoComposition.frameDuration = CMTime(value: 1, timescale: 30)

      // // 2. Enable Custom Compositor (Handles Filter + Scaling)
      // videoComposition.customVideoCompositorClass = FilterCompositor.self

      // // 3. Create Instruction (Pass Filter Data)
      // let instruction = FilterInstruction(
      //   timeRange: CMTimeRange(start: .zero, duration: composition.duration),
      //   filter: filter,
      //   transform: compositionTrack.preferredTransform,
      //       // transform: rotationTransform,  // e.g., CGAffineTransform(rotationAngle: .pi/2)
      //   naturalSize: videoSize,  // Pass the original video size
      //   trackID: compositionTrack.trackID,
      // )
      // // instruction.requiredSourceTrackIDs = [NSNumber(value: kCMPersistentTrackID_Invalid)]

      // videoComposition.instructions = [instruction]

      

      // if let overlayUrl = overlayUrl {
       
      //       let parentLayer = CALayer()
      //       parentLayer.frame = CGRect(origin: .zero, size: videoSize)
      //       parentLayer.isGeometryFlipped = true 

      //       let videoLayer = CALayer()
      //       videoLayer.frame = CGRect(origin: .zero, size: videoSize)
            
      //       let overlayLayer = CALayer()
      //       overlayLayer.frame = CGRect(origin: .zero, size: videoSize)
            
      //       if let data = try? Data(contentsOf: overlayUrl),
      //          let image = UIImage(data: data) {
                
      //           overlayLayer.contents = image.cgImage
      //           overlayLayer.contentsGravity = .resizeAspectFill 
      //       }

      //       parentLayer.addSublayer(videoLayer)  
      //       parentLayer.addSublayer(overlayLayer) 

      //       let animationTool = AVVideoCompositionCoreAnimationTool(
      //           postProcessingAsVideoLayer: videoLayer,
      //           in: parentLayer
      //       )
            
      //       videoComposition.animationTool = animationTool

      //       print("Applied overlay layer")
      //   }



       guard
         let export = AVAssetExportSession(
           asset: composition,
           presetName: AVAssetExportPresetHighestQuality)
       else {
        //  print("Cannot create export session.")
         throw AppError.customError("Cannot create export session.")

       }

       export.videoComposition = videoComposition
       do {

        
        

         let exportTask = Task {
             try await export.export(to: dstUrl, as: .mp4)

         } 



           if #available(iOS 18.0, *) {
             for await progressState in export.states(updateInterval: 0.1) {
               switch progressState {
               case .waiting:
                  break
                //  print("Export is waiting...")
               case .pending:
                  break
                //  print("Export is pending...")
               case .exporting(let progress):
                 let currentProgress = Float(progress.fractionCompleted)
                    
                    //  print("Export progress: \(currentProgress * 100)%")
                    
                         onProgress( currentProgress)

               default:
                 break
               }
             }

           } else {
               while export.status == .waiting || export.status == .exporting {
                  
                   if export.status == .exporting {
                       let progress = export.progress
                          onProgress(progress)
                         
                   }
                  
                   try? await Task.sleep(nanoseconds: 100_000_000) 
               }
           }

           let _ = await exportTask


       } catch {
        //  print("Error while exporting \(error)")
         throw AppError.customError("Error while exporting ")
       }

  //  }

   }





   private static func isPortraitVideoTrack(_ track: AVAssetTrack) -> Bool {
        let transform = track.preferredTransform
        let tfA = transform.a
        let tfB = transform.b
        let tfC = transform.c
        let tfD = transform.d
        
        if (tfA == 0 && tfB == 1 && tfC == -1 && tfD == 0) ||
            (tfA == 0 && tfB == 1 && tfC == 1 && tfD == 0) ||
            (tfA == 0 && tfB == -1 && tfC == 1 && tfD == 0) {
            return true
        } else {
            return false
        }
    }

    private static func getNaturalSize(videoTrack: AVAssetTrack) -> CGSize {
        var size = videoTrack.naturalSize
        if isPortraitVideoTrack(videoTrack) {
            swap(&size.width, &size.height)
        }
        return size
    }


 }


// class FilterInstruction: NSObject, AVVideoCompositionInstructionProtocol {
//     var timeRange: CMTimeRange
//     var enablePostProcessing: Bool = true
//     var containsTweening: Bool = true  // Must be true when applying filters
//     var requiredSourceTrackIDs: [NSValue]? 
//     var passthroughTrackID: CMPersistentTrackID = kCMPersistentTrackID_Invalid
    
//     let filter: CIFilter
//     let rotateTransform: CGAffineTransform
//     let naturalSize: CGSize  // Add this to track original video size
    
//     init(timeRange: CMTimeRange, filter: CIFilter, transform: CGAffineTransform, naturalSize: CGSize, trackID: CMPersistentTrackID) {
//         self.timeRange = timeRange
//         self.filter = filter
//         self.rotateTransform = transform
//         self.naturalSize = naturalSize
//         self.requiredSourceTrackIDs = [NSNumber(value: trackID)]
//         super.init()
//     }
// }

// class FilterCompositor: NSObject, AVVideoCompositing {
    
//  var sourcePixelBufferAttributes: [String: Any]? = [
//         kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
//     ]
    
//     var requiredPixelBufferAttributesForRenderContext: [String: Any] = [
//         kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
//     ]
    
//     private let ciContext: CIContext
    
//     override init() {
//         // Standard high-performance Context setup
//         if let device = MTLCreateSystemDefaultDevice() {
//             self.ciContext = CIContext(mtlDevice: device)
//         } else {
//             self.ciContext = CIContext()
//         }
//         super.init()
//     }
    
//     func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) { }
    
//     func startRequest(_ request: AVAsynchronousVideoCompositionRequest) {
//         // 1. Extract Instruction & Track ID
//         guard let instruction = request.videoCompositionInstruction as? FilterInstruction,
//               let trackIDs = instruction.requiredSourceTrackIDs,
//               let trackID = trackIDs.first as? NSNumber else {
//             request.finish(with: AppError.customError("Invalid Instruction"))
//             return
//         }
        
//         // 2. Fetch the Frame using the REAL Track ID
//         guard let sourceBuffer = request.sourceFrame(byTrackID: trackID.int32Value) else {
//             request.finish(with: AppError.customError("Missing source frame"))
//             return
//         }
        
//         let sourceImage = CIImage(cvPixelBuffer: sourceBuffer).clampedToExtent()
        
//         // 3. Apply Transform (The Simple Way)
//         // Just apply the preference. If it rotates 90 deg, it might move to negative coords.
//         let orientedImage = sourceImage.transformed(by: instruction.rotateTransform)
        
//         // 4. Re-center (Fix Origin)
//         // Shift the image so its new origin is at (0,0)
//         let centeredImage = orientedImage.transformed(by: CGAffineTransform(
//             translationX: -orientedImage.extent.origin.x,
//             y: -orientedImage.extent.origin.y
//         ))
        
//         // 5. Scale to Output Size
//         let renderSize = request.renderContext.size
//         let scaleX = renderSize.width / centeredImage.extent.width
//         let scaleY = renderSize.height / centeredImage.extent.height
        
//         // Use max() for Aspect Fill (Cover), min() for Aspect Fit
//         // We use distinct scales here to ensure it fills the frame exactly as requested
//         let scaledImage = centeredImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
//         // 6. Apply Filter
//         instruction.filter.setValue(scaledImage, forKey: kCIInputImageKey)
        
//         guard let outputImage = instruction.filter.outputImage,
//               let destinationBuffer = request.renderContext.newPixelBuffer() 
//         else {
//             request.finish(with: AppError.customError("Render failed"))
//             return
//         }
        
//         // 7. Render
//         // Crop to exact renderSize to avoid glitches
//         let finalOutput = outputImage.cropped(to: CGRect(origin: .zero, size: renderSize))
        
//         ciContext.render(finalOutput, to: destinationBuffer)
//         request.finish(withComposedVideoFrame: destinationBuffer)
//     }
//     func cancelAllPendingVideoCompositionRequests() {
//         // Implement cancellation if needed
//         // For basic implementation, this can be empty
//     }
// }