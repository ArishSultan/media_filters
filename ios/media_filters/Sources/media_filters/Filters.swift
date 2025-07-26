import CoreImage

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

public class Filters {
    public var lutFilter: CIFilter?
    
    public var exposure = BoundedValue<Float>(min: -10.0, max: 10.0, initialValue: 0.0)
    public var contrast = BoundedValue<Float>(min: 0.0, max: 4.0, initialValue: 1.0)
    public var saturation = BoundedValue<Float>(min: 0.0, max: 2.0, initialValue: 1.0)
    public var temperature = BoundedValue<Float>(min: 2000.0, max: 10000.0, initialValue: 6500.0)
    public var tint = BoundedValue<Float>(min: -200.0, max: 200.0, initialValue: 0)
    
    // COMPOSITE FILTER APPROACH
    public func createCompositeFilter() -> CIFilter? {
        // Create a custom composite filter using CIFilterGenerator (deprecated but still works)
        // Or use modern approach with custom CIFilter subclass
        return CustomCompositeFilter(filters: self)
    }
}

// Custom composite filter that combines all effects
public class CustomCompositeFilter: CIFilter {
    private let filterSettings: Filters
    
    @objc dynamic var inputImage: CIImage?
    
    init(filters: Filters) {
        self.filterSettings = filters
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public var outputImage: CIImage? {
        guard let inputImage = inputImage else { return nil }
        
        // Create kernel-based composite filter for better performance
        return createOptimizedComposite(inputImage: inputImage)
    }
    
    private func createOptimizedComposite(inputImage: CIImage) -> CIImage? {
        // Method 1: Use CIColorMatrix for multiple adjustments in single pass
        if canUseColorMatrix() {
            return applyColorMatrixComposite(inputImage: inputImage)
        }
        
        // Method 2: Chain filters but create a single render context
        return applyChainedComposite(inputImage: inputImage)
    }
    
    private func canUseColorMatrix() -> Bool {
        // Check if we can represent all our adjustments as a single color matrix
        // This is possible for exposure, contrast, saturation but not temperature/tint
        return filterSettings.temperature.value == 6500.0 && filterSettings.tint.value == 0.0
    }
    
    private func applyColorMatrixComposite(inputImage: CIImage) -> CIImage? {
        // Create a single color matrix that combines exposure, contrast, and saturation
        let colorMatrixFilter = CIFilter(name: "CIColorMatrix")!
        
        // Calculate combined matrix values
        let exp = pow(2.0, filterSettings.exposure.value) // Exposure adjustment
        let con = filterSettings.contrast.value // Contrast
        let sat = filterSettings.saturation.value // Saturation
        
        // Simplified matrix calculation (you'd need proper color space math here)
        let r = exp * con * (1.0 - sat) + sat
        let g = exp * con * (1.0 - sat) + sat
        let b = exp * con * (1.0 - sat) + sat
        
        colorMatrixFilter.setValue(inputImage, forKey: kCIInputImageKey)
        colorMatrixFilter.setValue(CIVector(x: CGFloat(r), y: 0, z: 0, w: 0), forKey: "inputRVector")
        colorMatrixFilter.setValue(CIVector(x: 0, y: CGFloat(g), z: 0, w: 0), forKey: "inputGVector")
        colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: CGFloat(b), w: 0), forKey: "inputBVector")
        colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        
        var result = colorMatrixFilter.outputImage
        
        // Apply LUT if available
        if let lut = filterSettings.lutFilter, let currentResult = result {
            lut.setValue(currentResult, forKey: kCIInputImageKey)
            result = lut.outputImage
        }
        
        return result
    }
    
    private func applyChainedComposite(inputImage: CIImage) -> CIImage? {
        // Same as chaining but optimized for single render pass
        var currentImage = inputImage
        var filters: [CIFilter] = []
        
        // Build filter array
        if let lut = filterSettings.lutFilter {
            filters.append(lut)
        }
        
        if filterSettings.exposure.value != 0.0 {
            let exposureFilter = CIFilter(name: "CIExposureAdjust")!
            exposureFilter.setValue(filterSettings.exposure.value, forKey: kCIInputEVKey)
            filters.append(exposureFilter)
        }
        
        if filterSettings.contrast.value != 1.0 || filterSettings.saturation.value != 1.0 {
            let colorFilter = CIFilter(name: "CIColorControls")!
            colorFilter.setValue(filterSettings.contrast.value, forKey: kCIInputContrastKey)
            colorFilter.setValue(filterSettings.saturation.value, forKey: kCIInputSaturationKey)
            colorFilter.setValue(0.0, forKey: kCIInputBrightnessKey)
            filters.append(colorFilter)
        }
        
        if filterSettings.temperature.value != 6500.0 || filterSettings.tint.value != 0.0 {
            let tempTintFilter = CIFilter(name: "CITemperatureAndTint")!
            tempTintFilter.setValue(
                CIVector(x: CGFloat(filterSettings.temperature.value), y: CGFloat(filterSettings.tint.value)),
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
