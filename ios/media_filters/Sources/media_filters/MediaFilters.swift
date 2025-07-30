import Metal
import CoreImage
import SwiftCube
import AVFoundation

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
  
  // Cache invalidation flag
  private var _filtersNeedUpdate = true
  
  public var lutFilter: CIFilter? {
    get { return _lutFilter }
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
    get {
      return CustomCompositeFilter(filters: self)
    }
  }
  
  public func unloadLutFilter() {
    if _lutFilter != nil {
      _lutFilter = nil
      _filtersNeedUpdate = true
    }
  }
  
  public func loadLutFilter(lutUrl: URL) {
    guard let sc3dFilter = try? SC3DLut(contentsOf: lutUrl),
          let ciFilter = try? sc3dFilter.ciFilter() else {
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
  
  @objc dynamic var inputImage: CIImage?
  
  init(filters: MediaFilters) {
    self.filterSettings = filters
    super.init()
    buildFilterChain()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override public var outputImage: CIImage? {
    guard let inputImage = inputImage else { return nil }
    
    // Rebuild chain if settings changed
    if filterSettings.filtersNeedUpdate {
      buildFilterChain()
      filterSettings.markFiltersUpdated()
    }
    
    return applyFilterChain(inputImage: inputImage)
  }
  
  private func buildFilterChain() {
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
  }
  
  private func applyFilterChain(inputImage: CIImage) -> CIImage? {
    guard !cachedFilterChain.isEmpty else { return inputImage }
    
    var currentImage = inputImage
    
    // Apply all cached filters in sequence
    for filter in cachedFilterChain {
      filter.setValue(currentImage, forKey: kCIInputImageKey)
      guard let output = filter.outputImage else { return nil }
      currentImage = output
    }
    
    return currentImage
  }
}
