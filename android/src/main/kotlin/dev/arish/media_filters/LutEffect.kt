import android.graphics.Bitmap
import android.graphics.Color
import java.io.BufferedReader
import java.io.File
import java.io.FileInputStream
import java.io.InputStreamReader

/**
 * Converts a .cube file to a HALD bitmap
 * @param filePath Path to the .cube file
 * @return HALD bitmap in ARGB_8888 format
 */
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
