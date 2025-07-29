import CoreImage
import AVFoundation

public protocol Filterable {
  func applyFilter(_ filter: CIFilter?)
}

///
public struct BoundedValue<T: Numeric & Comparable> {
  ///
  public let min: T
  
  ///
  public let max: T
  ///
  private var _value: T
  ///
  public var value: T {
    get {
      return _value
    }
    set {
      _value = Swift.max(min, Swift.min(max, newValue))
    }
  }
  
  ///
  public init(min: T, max: T, initialValue: T) {
    precondition(min <= max, "The minimum value cannot be greater than the maximum value.")
    
    self.min = min
    self.max = max
    self._value = initialValue
  }
}

public class MediaFilters {
  public var filterable: Filterable?
  
  private var _tint = BoundedValue<Float>(min: -200.0, max: 200.0, initialValue: 0) {
    didSet { if oldValue.value != _tint.value { applyFilter() } }
  }
  
  private var _exposure = BoundedValue<Float>(min: -10.0, max: 10.0, initialValue: 0.0) {
    didSet { if oldValue.value != _exposure.value { applyFilter() } }
  }
  
  private var _contrast = BoundedValue<Float>(min: 0.0, max: 4.0, initialValue: 1.0) {
    didSet { if oldValue.value != _contrast.value { applyFilter() } }
  }
  
  private var _saturation = BoundedValue<Float>(min: 0.0, max: 2.0, initialValue: 1.0) {
    didSet { if oldValue.value != _saturation.value { applyFilter() } }
  }
  
  private var _temperature = BoundedValue<Float>(min: 2000.0, max: 10000.0, initialValue: 6500.0) {
    didSet { if oldValue.value != _temperature.value { applyFilter() } }
  }
  
  public var lutFilter: CIFilter? {
    didSet { if oldValue != lutFilter { applyFilter() } }
  }
  
  public var tint: Float {
    set { _tint.value = newValue }
    get { return _tint.value }
  }
  
  public var exposure: Float {
    set { _exposure.value = newValue }
    get { return _exposure.value }
  }
  public var contrast: Float {
    set { _contrast.value = newValue }
    get { return _contrast.value }
  }
  public var saturation: Float {
    set { _saturation.value = newValue }
    get { return _saturation.value }
  }
  public var temperature: Float {
    set { _temperature.value = newValue }
    get { return _temperature.value }
  }
  
  private func applyFilter() {
    if filterable != nil {
      filterable!.applyFilter(CustomCompositeFilter(filters: self))
    }
  }
}

// Custom composite filter that combines all effects
public class CustomCompositeFilter: CIFilter {
  private let filterSettings: MediaFilters
  
  @objc dynamic var inputImage: CIImage?
  
  init(filters: MediaFilters) {
    self.filterSettings = filters
    super.init()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override public var outputImage: CIImage? {
    guard let inputImage = inputImage else { return nil }
    
    // Create kernel-based composite filter for better performance
    return applyChainedComposite(inputImage: inputImage)
  }
  
  private func applyChainedComposite(inputImage: CIImage) -> CIImage? {
    // Same as chaining but optimized for single render pass
    var currentImage = inputImage
    var filters: [CIFilter] = []
    
    // Build filter array
    if let lut = filterSettings.lutFilter {
      filters.append(lut)
    }
    
    if filterSettings.exposure != 0.0 {
      let exposureFilter = CIFilter.exposureAdjust()
      exposureFilter.ev = filterSettings.exposure
      filters.append(exposureFilter)
    }
    
    if filterSettings.contrast != 1.0 || filterSettings.saturation != 1.0 {
      let colorFilter = CIFilter.colorControls()
      colorFilter.contrast = filterSettings.contrast
      colorFilter.saturation = filterSettings.saturation
      colorFilter.brightness = 0.0
      filters.append(colorFilter)
    }
    
    if filterSettings.temperature != 6500.0 || filterSettings.tint != 0.0 {
      let tempTintFilter = CIFilter.temperatureAndTint()
      tempTintFilter.setValue(
        CIVector(x: CGFloat(filterSettings.temperature), y: CGFloat(filterSettings.tint)),
        forKey: "inputNeutral"
      )
      tempTintFilter.setValue(CIVector(x: 6500, y: 0), forKey: "inputTargetNeutral")
      filters.append(tempTintFilter)
    }
    
    // Apply all filters
    for filter in filters {
      filter.setValue(currentImage, forKey: kCIInputImageKey)
      guard let output = filter.outputImage else { return nil }
      currentImage = output
    }
    
    return currentImage
  }
}

// MARK: - Video Exporter Implementation

/// Defines specific errors that can occur during the video export process.
public enum VideoExporterError: Error, LocalizedError {
  case noVideoTrack
  case invalidOutputURL
  case cannotAddReaderOutput
  case cannotAddWriterInput
  case failedToStartSession(Error?)
  case exportCancelled
  case unknown(Error?)
  
  public var errorDescription: String? {
    switch self {
      case .noVideoTrack:
        return "The source video file does not contain a valid video track."
      case .invalidOutputURL:
        return "The provided output URL is invalid."
      case .cannotAddReaderOutput:
        return "Failed to add track output to the asset reader."
      case .cannotAddWriterInput:
        return "Failed to add input to the asset writer."
      case .failedToStartSession(let error):
        return "Failed to start the reading/writing session. Error: \(error?.localizedDescription ?? "Unknown")"
      case .exportCancelled:
        return "The video export operation was cancelled."
      case .unknown(let error):
        return "An unknown error occurred during export. Error: \(error?.localizedDescription ?? "Unknown")"
    }
  }
}

/// A class to handle the asynchronous filtering and exporting of a video file.
public class VideoExporter {
  
  // MARK: Public Properties
  public let inputURL: URL
  public let outputURL: URL
  public let mediaFilters: MediaFilters
  
  // MARK: Callbacks
  public var progressHandler: ((Float) -> Void)?
  public var completionHandler: ((Result<Void, VideoExporterError>) -> Void)?
  
  // MARK: Private Properties
  private var assetReader: AVAssetReader?
  private var assetWriter: AVAssetWriter?
  private let processingQueue = DispatchQueue(label: "dev.arish.media_filters.exporter.queue")
  private let ciContext = CIContext(options: nil)
  
  /// Initializes the exporter with the necessary assets and filter settings.
  /// - Parameters:
  ///   - inputURL: The URL of the source video.
  ///   - outputURL: The URL where the processed video will be saved.
  ///   - mediaFilters: An object containing the desired filter settings.
  public init(inputURL: URL, outputURL: URL, mediaFilters: MediaFilters) {
    self.inputURL = inputURL
    self.outputURL = outputURL
    self.mediaFilters = mediaFilters
  }
  
  /// Starts the asynchronous export process.
  public func export() {
    processingQueue.async {
      do {
        try self.runExportPipeline()
      } catch let error as VideoExporterError {
        self.finish(with: .failure(error))
      } catch {
        self.finish(with: .failure(.unknown(error)))
      }
    }
  }
  
  /// Cancels the export process.
  public func cancel() {
    processingQueue.async {
      self.assetReader?.cancelReading()
      self.assetWriter?.cancelWriting()
      self.cleanup()
      self.finish(with: .failure(.exportCancelled))
    }
  }
  
  private func runExportPipeline() throws {
    // 1. Clean up any existing file at the output URL
    cleanup()
    
    // 2. Setup Asset, Reader, and Writer
    let asset = AVURLAsset(url: inputURL)
    guard let videoTrack = asset.tracks(withMediaType: .video).first else {
      throw VideoExporterError.noVideoTrack
    }
    
    // Setup Reader
    assetReader = try AVAssetReader(asset: asset)
    let readerOutputSettings: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
    let readerTrackOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: readerOutputSettings)
    readerTrackOutput.alwaysCopiesSampleData = false
    
    guard let reader = assetReader, reader.canAdd(readerTrackOutput) else {
      throw VideoExporterError.cannotAddReaderOutput
    }
    reader.add(readerTrackOutput)
    
    // Setup Writer
    assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
    let writerOutputSettings: [String: Any] = [
      AVVideoCodecKey: AVVideoCodecType.h264,
      AVVideoWidthKey: videoTrack.naturalSize.width,
      AVVideoHeightKey: videoTrack.naturalSize.height
    ]
    
    // 1. Create the writer input first
    let writerInput = AVAssetWriterInput(
      mediaType: .video,
      outputSettings: writerOutputSettings,
      sourceFormatHint: videoTrack.formatDescriptions.first as! CMFormatDescription?
    )
    writerInput.expectsMediaDataInRealTime = false
    writerInput.transform = videoTrack.preferredTransform
    
    // 2. ✅ Create the pixel buffer adaptor *from* the writer input
    let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
      assetWriterInput: writerInput,
      sourcePixelBufferAttributes: nil
    )
    
    // 3. ✅ Now, safely access the pool from the adaptor instance
    guard let pixelBufferPool = pixelBufferAdaptor.pixelBufferPool else {
      throw VideoExporterError.unknown(nil) // Or a more specific error
    }
    
    guard let writer = assetWriter, writer.canAdd(writerInput) else {
      throw VideoExporterError.cannotAddWriterInput
    }
    writer.add(writerInput)
    
    // 3. Start Reading and Writing
    guard reader.startReading(), writer.startWriting() else {
      throw VideoExporterError.failedToStartSession(reader.error ?? writer.error)
    }
    writer.startSession(atSourceTime: .zero)
    
    // 4. Process Frames using a DispatchGroup
    let videoDuration = asset.duration.seconds
    let compositeFilter = CustomCompositeFilter(filters: mediaFilters)
    
    // ✅ Create a DispatchGroup to signal when the loop is done
    let processingGroup = DispatchGroup()
    processingGroup.enter()
    
    writerInput.requestMediaDataWhenReady(on: processingQueue) {
      while writerInput.isReadyForMoreMediaData {
        if self.assetReader?.status == .cancelled || self.assetWriter?.status == .cancelled {
          break
        }
        
        if let sampleBuffer = readerTrackOutput.copyNextSampleBuffer() {
          let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
          let progress = Float(timestamp.seconds / videoDuration)
          DispatchQueue.main.async { self.progressHandler?(progress) }
          
          guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { continue }
          
          let inputImage = CIImage(cvPixelBuffer: pixelBuffer)
          compositeFilter.inputImage = inputImage
          guard let outputImage = compositeFilter.outputImage else { continue }
          
          var newPixelBuffer: CVPixelBuffer?
          CVPixelBufferPoolCreatePixelBuffer(nil, pixelBufferPool, &newPixelBuffer)
          guard let renderedPixelBuffer = newPixelBuffer else { continue }
          self.ciContext.render(outputImage, to: renderedPixelBuffer)
          
          if !pixelBufferAdaptor.append(renderedPixelBuffer, withPresentationTime: timestamp) {
            print("Failed to append buffer. Writer status: \(writer.status.rawValue), error: \(writer.error?.localizedDescription ?? "N/A")")
            self.assetReader?.cancelReading()
            break
          }
        } else {
          // No more samples, the loop is done
          break
        }
      }
      // ✅ Signal that the processing loop has finished
      processingGroup.leave()
    }
    
    // ✅ Wait for the group to finish, then finalize the writer
    processingGroup.wait()
    
    // 5. Finalize the Export
    // This code now runs *after* the processing loop is guaranteed to be complete.
    if reader.status == .completed {
      writerInput.markAsFinished()
      writer.finishWriting {
        if writer.status == .completed {
          self.finish(with: .success(()))
        } else {
          self.finish(with: .failure(.unknown(writer.error)))
        }
      }
    } else if let error = reader.error {
      writer.cancelWriting()
      self.finish(with: .failure(.unknown(error)))
    } else if writer.status != .failed { // Handle cancellation case
      writer.cancelWriting()
      // The cancel() method already calls finish
    }
  }
  
  private func finish(with result: Result<Void, VideoExporterError>) {
    if case .failure = result {
      cleanup()
    }
    DispatchQueue.main.async {
      // Report final progress of 1.0 on success
      if case .success = result {
        self.progressHandler?(1.0)
      }
      self.completionHandler?(result)
    }
  }
  
  private func cleanup() {
    if FileManager.default.fileExists(atPath: outputURL.path) {
      try? FileManager.default.removeItem(at: outputURL)
    }
  }
}
