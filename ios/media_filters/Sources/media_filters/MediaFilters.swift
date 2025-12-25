import AVFoundation
import CoreImage
import Metal
import SwiftCube

/// A generic struct to hold a value that is clamped between a minimum and maximum.
public struct BoundedValue<T: Numeric & Comparable> {
  /// The minimum allowable value.
  public let min: T

  /// The maximum allowable value.
  public let max: T

  /// The private backing store for the value.
  private var _value: T

  /// The clamped value. When set, it's automatically constrained within the min/max bounds.
  public var value: T {
    get {
      return _value
    }
    set {
      // Use Swift's min/max to clamp the new value
      _value = Swift.max(min, Swift.min(max, newValue))
    }
  }

  /// Initializes a new BoundedValue.
  /// - Parameters:
  ///   - min: The minimum value.
  ///   - max: The maximum value.
  ///   - initialValue: The starting value.
  public init(min: T, max: T, initialValue: T) {
    precondition(min <= max, "The minimum value cannot be greater than the maximum value.")

    self.min = min
    self.max = max
    self._value = initialValue
  }
}

/// A class that manages a collection of Core Image filters and their settings.
public class MediaFilters {
  private var _lutFilter: CIFilter?

  private var _tint = BoundedValue<Float>(min: -200.0, max: 200.0, initialValue: 0)
  private var _exposure = BoundedValue<Float>(min: -10.0, max: 10.0, initialValue: 0.0)
  private var _contrast = BoundedValue<Float>(min: 0.0, max: 4.0, initialValue: 1.0)
  private var _saturation = BoundedValue<Float>(min: 0.0, max: 2.0, initialValue: 1.0)
  private var _temperature = BoundedValue<Float>(min: 2000.0, max: 10000.0, initialValue: 6500.0)

  public var overlayPath: URL? = nil

  // public var overlayPath: String? = {
  //   get { return _overlayPath }
  //   set {

  //   }
  // }

  // Cache invalidation flag
  private var _filtersNeedUpdate = true



  public var lutFilter: CIFilter? {
    return _lutFilter
  }

  public var tint: Float {
    set {
      if _tint.value != newValue {
        _tint.value = newValue
        _filtersNeedUpdate = true
      }
    }
    get { return _tint.value }
  }

  public var exposure: Float {
    set {
      if _exposure.value != newValue {
        _exposure.value = newValue
        _filtersNeedUpdate = true
      }
    }
    get { return _exposure.value }
  }

  public var contrast: Float {
    set {
      if _contrast.value != newValue {
        _contrast.value = newValue
        _filtersNeedUpdate = true
      }
    }
    get { return _contrast.value }
  }

  public var saturation: Float {
    set {
      if _saturation.value != newValue {
        _saturation.value = newValue
        _filtersNeedUpdate = true
      }
    }
    get { return _saturation.value }
  }

  public var temperature: Float {
    set {
      if _temperature.value != newValue {
        _temperature.value = newValue
        _filtersNeedUpdate = true
      }
    }
    get { return _temperature.value }
  }

  public var ciFilter: CIFilter {
    return CustomCompositeFilter(filters: self)
  }

  // public func getCiFilter(_ isInverted: Bool) -> CIFilter {
  //   return CustomCompositeFilter(filters: self, isInverted: isInverted)
  // }

  public func unloadLutFilter() {
    if _lutFilter != nil {
      _lutFilter = nil
      _filtersNeedUpdate = true
    }
  }

  public func loadLutFilter(lutUrl: URL) {
    guard let sc3dFilter = try? SC3DLut(contentsOf: lutUrl),
      let ciFilter = try? sc3dFilter.ciFilter()
    else {
      if _lutFilter != nil {
        _lutFilter = nil
        _filtersNeedUpdate = true
      }
      return
    }

    _lutFilter = ciFilter
    _filtersNeedUpdate = true
  }

  // Internal method to check if filters need updating
  internal var filtersNeedUpdate: Bool {
    return _filtersNeedUpdate
  }

  // Internal method to mark filters as updated
  internal func markFiltersUpdated() {
    _filtersNeedUpdate = false
  }
}

/// A custom CIFilter that chains multiple filters together based on MediaFilters settings.
public class CustomCompositeFilter: CIFilter {
  private let filterSettings: MediaFilters
  private var cachedFilterChain: [CIFilter] = []
  // private var isInverted: Bool
  private var overlayImage: CIImage?  = nil
  private var cachedOverlayImage: CIImage?   
  private var lastInputSize: CGSize = .zero

  @objc dynamic var inputImage: CIImage? {
    didSet {
      guard let image = inputImage else { return }
      
        // let size = CGSize(width: image.extent.width, height: image.extent.height)
      if image.extent.size != lastInputSize {
        // print("Calculated Size \(size.width) \(image.extent.width) \(image.extent.height)")
        updateOverlayGeometry(videoSize: image.extent.size)
        lastInputSize = image.extent.size
      }
    }
  }


  private func updateOverlayGeometry(videoSize: CGSize) {
    guard let cleanOverlay = self.overlayImage else { 
      cachedOverlayImage = nil
      return 
    }
    
    // // A. Scale Logic (e.g. 20% width)
    let targetWidth =  if videoSize.width > videoSize.height {
        videoSize.width * 0.2
    } else {
        videoSize.height * 0.2
    }
    
    let scale = targetWidth / cleanOverlay.extent.width
    // print("Scaling by \(targetWidth) with scale \(scale) cleanOVerlay SIze \(cleanOverlay.extent.width) \(videoSize.width)")
    let scaledOverlay = cleanOverlay.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    
    // print("Scale IMage Size \(scaledOverlay.extent.width)x\(scaledOverlay.extent.height)")
    // // B. Position Logic (Bottom-Right with padding)
    let padding: CGFloat = 20.0
    
    // Core Image Coordinates: (0,0) is BOTTOM-Left
    let targetX = videoSize.width - scaledOverlay.extent.width - padding
    let targetY = padding 
    
    let translate = CGAffineTransform(
        translationX: targetX - scaledOverlay.extent.origin.x,
        y: targetY - scaledOverlay.extent.origin.y
    )
    
    // Save the result to cache
    self.cachedOverlayImage = scaledOverlay.transformed(by: translate)
    // .transformed(by: 
    //     CGAffineTransform(scaleX: 1, y: -1)
    // ).transformed(by: 
    //     CGAffineTransform(translationX: 0, y: videoSize.height)
    // )


    // self.cachedOverlayImage = scaledOverlay


    // self.cachedOverlayImage = self.cachedOverlayImage.transformed(by: 
    //     CGAffineTransform(scaleX: 1, y: -1)
    // ).transformed(by: 
    //     CGAffineTransform(translationX: 0, y: videoSize.height)
    // )
    
    print("Overlay geometry updated for size: \(videoSize)")
  }

  init(filters: MediaFilters) {
    self.filterSettings = filters
    // self.isInverted  = isInverted
    super.init()
    buildFilterChain()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public var outputImage: CIImage? {
    guard let inputImage: CIImage = inputImage else { return nil }

    // Rebuild chain if settings changed
    if filterSettings.filtersNeedUpdate {
      buildFilterChain()
      filterSettings.markFiltersUpdated()
    }

    return applyFilterChain(inputImage: inputImage)
  }

  private func buildFilterChain() {
    print("Updating filter chain")
    cachedFilterChain.removeAll()

    // Build filter array based on which settings are active
    if let lut = filterSettings.lutFilter {
      cachedFilterChain.append(lut)
    }

    if filterSettings.exposure != 0.0 {
      let exposureFilter = CIFilter.exposureAdjust()
      exposureFilter.ev = filterSettings.exposure
      cachedFilterChain.append(exposureFilter)
    }

    if filterSettings.contrast != 1.0 || filterSettings.saturation != 1.0 {
      let colorFilter = CIFilter.colorControls()
      colorFilter.contrast = filterSettings.contrast
      colorFilter.saturation = filterSettings.saturation
      colorFilter.brightness = 0.0
      cachedFilterChain.append(colorFilter)
    }

    if filterSettings.temperature != 6500.0 || filterSettings.tint != 0.0 {
      let tempTintFilter = CIFilter.temperatureAndTint()
      tempTintFilter.setValue(
        CIVector(x: CGFloat(filterSettings.temperature), y: CGFloat(filterSettings.tint)),
        forKey: "inputNeutral"
      )
      tempTintFilter.setValue(CIVector(x: 6500, y: 0), forKey: "inputTargetNeutral")
      cachedFilterChain.append(tempTintFilter)
    }

    if let overlayPath = filterSettings.overlayPath {
      let colorBlendFilter = CIFilter.sourceOverCompositing()

      // print("OVERLAYPATH \(overlayPath)")
      // let imageUrl = URL(fileURLWithPath: overlayPath)
      // let backgroundImage = CIImage(contentsOf: imageUrl)

      // colorBlendFilter.inputImage = backgroundImage
      // colorBlendFilter.backgroundImage = backgroundImage
      // let imageUrl = URL(fileURLWithPath: overlayPath)
      overlayImage = CIImage(contentsOf: overlayPath) 


        // print("overimage isNull \(overlayImage == nil)")
      // if var overlayImage = overlayImage {
      //   // print("overimage isInverted \(self.isInverted)")
      //   // if self.isInverted {
      //   //   print("IMAGE INVERTED")
      //   //   overlayImage = overlayImage.transformed(by: CGAffineTransform(scaleX: -1, y: -1)) // Flip Vertical only
      //   //   overlayImage = overlayImage.transformed(by: CGAffineTransform(translationX: overlayImage.extent.width, y: overlayImage.extent.height))
      //   // }

      //   colorBlendFilter.setValue(overlayImage, forKey: kCIInputImageKey)
      // }

      cachedFilterChain.append(colorBlendFilter)


    }

  }




  private func applyFilterChain(inputImage: CIImage) -> CIImage? {
    guard !cachedFilterChain.isEmpty else { return inputImage }

    var currentImage = inputImage

    // Apply all cached filters in sequence
    for filter in cachedFilterChain {
      let overlayFilter = filter as? CICompositeOperation
    //  print("FILTER NAME \(filter.name) \(overlayFilter)")
      // if filter is CICompositeOperation && filter.name == "CIOverlayBlendMode"{
      // let backgroundImageKey = kCIInputBackgroundImageKey
      // TODO(arbaz): This branch will apply to all filters that contain the backgroundkey.
      if filter.inputKeys.contains(kCIInputBackgroundImageKey) {


        guard let cleanOverlay = self.cachedOverlayImage else {
            continue 
        }


  
        
        // print("Applying overlay")
        filter.setValue(cleanOverlay, forKey: kCIInputImageKey)


      // if let overlayPath = filterSettings.overlayPath {
                //  print("APPLYING OVERLAY FILTER \(overlayPath)")
      // let imageUrl = URL(fileURLWithPath: overlayPath)
      // if let overlayImage: CIImage = overlayImage {

      // inside CustomCompositeFilter.swift

      //  print("OVERLAY isInverted \(self.isInverted)")


      // overlayFilter.backgroundImage = currentImage
      filter.setValue(currentImage, forKey: kCIInputBackgroundImageKey)

      //  }
      // }

      } else {
            //  print("APPLYING NORMAL FILTER")
      filter.setValue(currentImage, forKey: kCIInputImageKey)
      }
      guard let output = filter.outputImage else { return nil }
      currentImage = output
    }

    return currentImage
  }
}
