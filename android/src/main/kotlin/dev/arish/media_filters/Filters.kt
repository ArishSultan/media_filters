package dev.arish.media_filters

import android.graphics.Bitmap
import android.graphics.Color
import androidx.annotation.FloatRange
import androidx.media3.common.util.UnstableApi
import androidx.media3.effect.GlEffect
import androidx.media3.effect.RgbMatrix
import androidx.media3.effect.SingleColorLut
import java.io.BufferedReader
import java.io.File
import java.io.FileInputStream
import java.io.InputStreamReader
import kotlin.math.pow


class BoundedValue<T : Comparable<T>>(
  val min: T,
  val max: T,
  value: T
) {
  var value: T = value
    set(newValue) {
      field = when {
        newValue < min -> min
        newValue > max -> max
        else -> newValue
      }
    }

  init {
    require(min <= max) { "The minimum value cannot be greater than the maximum value." }
  }
}

@UnstableApi
class Saturation(@FloatRange(from = 0.0, to = 2.0) saturation: Float) : RgbMatrix {
  private val saturation: Float
  private val saturationMatrix: FloatArray

  /**
   * Creates a new instance for the given saturation value.
   *
   *
   * Saturation values range from 0.0 (grayscale) to 2.0 (hyper-saturated), with 1.0 being
   * the original, unchanged color.
   *
   * @param saturation The saturation level.
   */
  init {
    require(
      saturation >= 0.0f && saturation <= 2.0f,
      { "Saturation needs to be in the interval [0.0, 2.0]." }
    )
    this.saturation = saturation

    val desaturation = 1.0f - saturation
    val r = LUMA_R * desaturation
    val g = LUMA_G * desaturation
    val b = LUMA_B * desaturation

    // The matrix is column-major
    saturationMatrix =
      floatArrayOf(
        r + saturation, g, b, 0.0f,
        r, g + saturation, b, 0.0f,
        r, g, b + saturation, 0.0f,
        0.0f, 0.0f, 0.0f, 1.0f
      )
  }

  override fun getMatrix(presentationTimeUs: Long, useHdr: Boolean): FloatArray {
    return saturationMatrix
  }

  override fun isNoOp(inputWidth: Int, inputHeight: Int): Boolean {
    return saturation == 1.0f
  }

  companion object {
    // Standard luminance weights for Rec. 709 / sRGB
    private const val LUMA_R = 0.2126f
    private const val LUMA_G = 0.7152f
    private const val LUMA_B = 0.0722f
  }
}

/** A [RgbMatrix] to control the color temperature of video frames.  */
@UnstableApi
class Temperature(@FloatRange(from = 2000.0, to = 10000.0) temperature: Float) : RgbMatrix {
  private val temperature: Float
  private val temperatureMatrix: FloatArray

  /**
   * Creates a new instance for the given temperature value in Kelvin.
   *
   *
   * Temperature values range from 2000.0K (very warm) to 10000.0K (very cool). A value of
   * 6500.0K is neutral and results in no change.
   *
   * @param temperature The temperature adjustment value in Kelvin.
   */
  init {
    require(
      temperature >= 2000.0f && temperature <= 10000.0f,
      { "Temperature needs to be in the interval [2000.0, 10000.0]." }
    )
    this.temperature = temperature

    val sliderValue: Float
    if (temperature < NEUTRAL_TEMPERATURE) {
      // Map Kelvin range [2000, 6500) to a warm slider value (0, 1]
      sliderValue = (NEUTRAL_TEMPERATURE - temperature) / (NEUTRAL_TEMPERATURE - 2000.0f)
    } else {
      // Map Kelvin range [6500, 10000] to a cool slider value [0, -1]
      sliderValue = (NEUTRAL_TEMPERATURE - temperature) / (10000.0f - NEUTRAL_TEMPERATURE)
    }

    // A scaling factor to control the effect's strength.
    val scaledEffect = sliderValue * 0.2f

    // The matrix is column-major. Additive effects are in the 4th column (translation).
    // A positive sliderValue (warm) adds to red and subtracts from blue.
    temperatureMatrix =
      floatArrayOf(
        1.0f, 0.0f, 0.0f, 0.0f,
        0.0f, 1.0f, 0.0f, 0.0f,
        0.0f, 0.0f, 1.0f, 0.0f,
        scaledEffect, 0.0f, -scaledEffect, 1.0f
      )
  }

  override fun getMatrix(presentationTimeUs: Long, useHdr: Boolean): FloatArray {
    return temperatureMatrix
  }

  override fun isNoOp(inputWidth: Int, inputHeight: Int): Boolean {
    return temperature == NEUTRAL_TEMPERATURE
  }

  companion object {
    private const val NEUTRAL_TEMPERATURE = 6500.0f
  }
}

/** A [RgbMatrix] to control the color tint of video frames.  */
@UnstableApi
class Tint(@FloatRange(from = -200.0, to = 200.0) tint: Float) : RgbMatrix {
  private val tint: Float
  private val tintMatrix: FloatArray

  /**
   * Creates a new instance for the given tint value.
   *
   *
   * Tint values range from -200 (magenta) to 200 (green). A value of 0 means no change.
   *
   * @param tint The tint adjustment value.
   */
  init {
    require(
      tint >= -200.0f && tint <= 200.0f,
      { "Tint needs to be in the interval [-200.0, 200.0]." }
    )
    this.tint = tint

    // Normalize the [-200, 200] range to [-1, 1] and then apply a scaling factor.
    val scaledTint = (tint / 200.0f) * 0.2f

    // The matrix is column-major. Additive effects are in the 4th column (translation).
    tintMatrix =
      floatArrayOf(
        1.0f, 0.0f, 0.0f, 0.0f,
        0.0f, 1.0f, 0.0f, 0.0f,
        0.0f, 0.0f, 1.0f, 0.0f,
        0.0f, scaledTint, 0.0f, 1.0f
      )
  }

  override fun getMatrix(presentationTimeUs: Long, useHdr: Boolean): FloatArray {
    return tintMatrix
  }

  override fun isNoOp(inputWidth: Int, inputHeight: Int): Boolean {
    return tint == 0.0f
  }
}

/** A [RgbMatrix] to control the exposure of video frames.  */
@UnstableApi
class Exposure(@FloatRange(from = -10.0, to = 10.0) exposure: Float) : RgbMatrix {
  private val exposure: Float
  private val exposureMatrix: FloatArray

  /**
   * Creates a new instance for the given exposure value.
   *
   *
   * Exposure values range from -10.0 (dark) to 10.0 (bright). A value of 0.0 means no
   * change. The effect is calculated as 2<sup>exposure</sup>.
   *
   * @param exposure The exposure adjustment value.
   */
  init {
    require(
      exposure >= -10.0f && exposure <= 10.0f,
      { "Exposure needs to be in the interval [-10.0, 10.0]." }
    )
    this.exposure = exposure

    val exposureFactor = 2.0.pow(exposure.toDouble()).toFloat()

    // The matrix is column-major. Exposure is a multiplicative effect on the diagonal.
    exposureMatrix =
      floatArrayOf(
        exposureFactor, 0.0f, 0.0f, 0.0f,
        0.0f, exposureFactor, 0.0f, 0.0f,
        0.0f, 0.0f, exposureFactor, 0.0f,
        0.0f, 0.0f, 0.0f, 1.0f
      )
  }

  override fun getMatrix(presentationTimeUs: Long, useHdr: Boolean): FloatArray {
    return exposureMatrix
  }

  override fun isNoOp(inputWidth: Int, inputHeight: Int): Boolean {
    return exposure == 0.0f
  }
}

@UnstableApi
class Contrast(@FloatRange(from = 0.0, to = 4.0) contrast: Float) : RgbMatrix {
  private val contrast: Float
  private val contrastMatrix: FloatArray

  /**
   * Creates a new instance for the given contrast value.
   *
   *
   * Contrast values range from 0.0 (all gray) to 4.0 (high contrast). A value of 1.0 means
   * no contrast is applied.
   *
   * @param contrast The contrast adjustment value.
   */
  init {
    require(
      contrast >= 0.0f && contrast <= 4.0f,
      { "Contrast needs to be in the interval [0.0, 4.0]." }
    )
    this.contrast = contrast

    // The input 'contrast' value is now the direct factor for the matrix.
    val contrastFactor = this.contrast
    val translation = (1.0f - contrastFactor) * 0.5f

    contrastMatrix =
      floatArrayOf(
        contrastFactor, 0.0f, 0.0f, 0.0f,
        0.0f, contrastFactor, 0.0f, 0.0f,
        0.0f, 0.0f, contrastFactor, 0.0f,
        translation, translation, translation, 1.0f
      )
  }

  override fun getMatrix(presentationTimeUs: Long, useHdr: Boolean): FloatArray {
    return contrastMatrix
  }

  override fun isNoOp(inputWidth: Int, inputHeight: Int): Boolean {
    return contrast == 1.0f
  }
}

/**
 * Enhanced Filters class with all adjustments
 */
@UnstableApi
class EnhancedFilters {
  var lutFilter: SingleColorLut? = null

  var exposure = BoundedValue(-10.0f, 10.0f, 0.0f)
  var contrast = BoundedValue(0.0f, 4.0f, 1.0f)
  var saturation = BoundedValue(0.0f, 2.0f, 1.0f)
  var temperature = BoundedValue(2000.0f, 10000.0f, 6500.0f)
  var tint = BoundedValue(-200.0f, 200.0f, 0.0f)

  /**
   * Create a list of video effects to apply to the player
   */
  fun createEffects(): List<GlEffect> {
    val effects = mutableListOf<GlEffect>()

    // Add LUT filter first if available
    lutFilter?.let { effects.add(it) }

    // Add exposure effect if not default
    if (exposure.value != 0.0f) {
      effects.add(Exposure(exposure.value))
    }

    // Add contrast and saturation effect if not default
    if (contrast.value != 1.0f) {
      effects.add(Contrast(contrast.value))
    }

    if (saturation.value != 1.0f) {
      effects.add(Saturation(saturation.value))
    }

    // Add temperature and tint effect if not default
    if (temperature.value != 6500.0f) {
      effects.add(Temperature(temperature.value))
    }

    if (tint.value != 0.0f) {
      effects.add(Tint(tint.value))
    }

    return effects
  }

  /**
   * Load a LUT filter from file path
   */
  fun loadLutFilter(filePath: String) {
    try {
      val bitmap = cubeFileToHaldBitmap(filePath)
      lutFilter = SingleColorLut.createFromBitmap(bitmap)
    } catch (e: Exception) {
      throw RuntimeException("Failed to load LUT filter: ${e.message}", e)
    }
  }

  /**
   * Remove the LUT filter
   */
  fun removeLutFilter() {
    lutFilter = null
  }

  /**
   * Reset all filters to default values
   */
  fun resetAll() {
    exposure.value = 0.0f
    contrast.value = 1.0f
    saturation.value = 1.0f
    temperature.value = 6500.0f
    tint.value = 0.0f
    lutFilter = null
  }
}

fun cubeFileToHaldBitmap(filePath: String): Bitmap {
  val file = File(filePath)
  require(file.exists()) { "File does not exist: $filePath" }

  return FileInputStream(file).use { inputStream ->
    cubeStreamToHaldBitmap(inputStream)
  }
}

/**
 * Converts a .cube file input stream to a HALD bitmap
 */
private fun cubeStreamToHaldBitmap(inputStream: java.io.InputStream): Bitmap {
  val reader = BufferedReader(InputStreamReader(inputStream))

  var lutSize: Int? = null
  val colorData = mutableListOf<Triple<Float, Float, Float>>()

  // Parse the .cube file
  reader.useLines { lines ->
    lines.forEach { line ->
      val trimmed = line.trim()

      when {
        trimmed.isEmpty() || trimmed.startsWith("#") -> {
          // Skip empty lines and comments
        }

        trimmed.startsWith("LUT_3D_SIZE") -> {
          lutSize = trimmed.split(" ")[1].toInt()
        }

        trimmed.startsWith("TITLE") ||
            trimmed.startsWith("DOMAIN_MIN") ||
            trimmed.startsWith("DOMAIN_MAX") ||
            trimmed.startsWith("LUT_1D_SIZE") -> {
          // Skip these lines
        }

        else -> {
          // Parse color data
          val values = trimmed.split(" ")
          if (values.size >= 3) {
            try {
              val r = values[0].toFloat()
              val g = values[1].toFloat()
              val b = values[2].toFloat()
              colorData.add(Triple(r, g, b))
            } catch (e: NumberFormatException) {
              // Skip invalid data lines
            }
          }
        }
      }
    }
  }

  requireNotNull(lutSize) { "LUT_3D_SIZE not found in .cube file" }
  require(colorData.size == lutSize * lutSize * lutSize) {
    "Expected ${lutSize * lutSize * lutSize} color values, but found ${colorData.size}"
  }

  val size = lutSize
  val bitmapWidth = size
  val bitmapHeight = size * size
  val bitmap = Bitmap.createBitmap(bitmapWidth, bitmapHeight, Bitmap.Config.ARGB_8888)

  var dataIndex = 0

  // Fill the bitmap with LUT data
  // HALD format: for each red plane, for each green row, for each blue column
  for (r in 0 until size) {
    for (g in 0 until size) {
      for (b in 0 until size) {
        val (red, green, blue) = colorData[dataIndex]

        // Convert from float [0,1] to int [0,255]
        val redInt = (red.coerceIn(0f, 1f) * 255).toInt()
        val greenInt = (green.coerceIn(0f, 1f) * 255).toInt()
        val blueInt = (blue.coerceIn(0f, 1f) * 255).toInt()

        // Create ARGB color
        val color = Color.argb(255, redInt, greenInt, blueInt)

        // Set pixel at correct HALD position
        // X coordinate = blue index
        // Y coordinate = red * size + green
        bitmap.setPixel(b, r * size + g, color)

        dataIndex++
      }
    }
  }

  return bitmap
}
