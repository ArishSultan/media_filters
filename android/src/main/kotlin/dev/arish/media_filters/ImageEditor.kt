package dev.arish.media_filters

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.opengl.*
import android.util.Log
import androidx.media3.common.util.UnstableApi
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer
import javax.microedition.khronos.opengles.GL10

/**
 * Real-time Image Editor class for applying GL effects to images with on-screen rendering
 */
@UnstableApi
class ImageEditor(private val id: Int, private val context: Context): GLSurfaceView.Renderer {

  /**
   * The GLSurfaceView for on-screen rendering.
   * It's created lazily on first access.
   */
  val view: GLSurfaceView by lazy {
    GLSurfaceView(context).apply {
      setEGLContextClientVersion(2)
      setRenderer(this@ImageEditor)
      // Render only when requested, which is efficient for an editor
      renderMode = GLSurfaceView.RENDERMODE_WHEN_DIRTY
    }
  }

  /**
   * GL objects
   */
  private var textureId = 0
  private var program = 0
  private var vertexBuffer: FloatBuffer? = null

  /**
   * Current loaded image bitmap and dimensions
   */
  private var originalBitmap: Bitmap? = null
  private var pendingBitmap: Bitmap? = null
  private var imageWidth: Int = 0
  private var imageHeight: Int = 0

  /**
   * Callbacks
   */
  var processCompleteCb: ByteArrayCallback? = null

  /**
   * Enhanced filters instance
   */
  val filters = EnhancedFilters()

  /**
   * GL handles
   */
  private var mvpMatrixHandle = 0
  private var textureHandle = 0
  private var lutTextureHandle = 0
  private var useLutHandle = 0
  private var exposureHandle = 0
  private var contrastHandle = 0
  private var saturationHandle = 0
  private var temperatureHandle = 0
  private var tintHandle = 0
  private var positionHandle = 0
  private var texCoordHandle = 0

  /**
   * Matrices
   */
  private val mvpMatrix = FloatArray(16)
  private val projectionMatrix = FloatArray(16)
  private val viewMatrix = FloatArray(16)

  /**
   * Surface dimensions
   */
  private var surfaceWidth = 0
  private var surfaceHeight = 0

  /**
   * Viewport dimensions for maintaining aspect ratio
   */
  private var viewportX = 0
  private var viewportY = 0
  private var viewportWidth = 0
  private var viewportHeight = 0

  /**
   * Flag to check if GL is initialized
   */
  private var isGLInitialized = false

  override fun onSurfaceCreated(gl: GL10?, config: javax.microedition.khronos.egl.EGLConfig?) {
    // Initialize OpenGL when surface is created
    initializeGL()
    isGLInitialized = true

    // If we have a pending bitmap, use it
    if (pendingBitmap != null) {
      pendingBitmap?.let {
        originalBitmap = it
        pendingBitmap = null
        uploadTextureToGPU()
      }
    } else if (originalBitmap != null && !originalBitmap!!.isRecycled) {
      // If we already have a bitmap loaded and it's not recycled, upload it to GPU
      uploadTextureToGPU()
    }
  }

  override fun onSurfaceChanged(gl: GL10?, width: Int, height: Int) {
    surfaceWidth = width
    surfaceHeight = height

    // Calculate viewport to maintain aspect ratio
    calculateViewport()

    // Set the viewport
    GLES20.glViewport(viewportX, viewportY, viewportWidth, viewportHeight)

    // Use simple orthographic projection
    Matrix.orthoM(projectionMatrix, 0, -1f, 1f, -1f, 1f, -1f, 1f)
  }

  override fun onDrawFrame(gl: GL10?) {
    // Clear the entire screen with black
    GLES20.glViewport(0, 0, surfaceWidth, surfaceHeight)
    GLES20.glClearColor(0.0f, 0.0f, 0.0f, 1.0f)
    GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)

    // Only render if we have a texture and bitmap is not recycled
    if (textureId != 0 && originalBitmap != null && !originalBitmap!!.isRecycled) {
      // Set viewport to maintain aspect ratio
      GLES20.glViewport(viewportX, viewportY, viewportWidth, viewportHeight)

      // Update matrices
      Matrix.setIdentityM(viewMatrix, 0)
      Matrix.multiplyMM(mvpMatrix, 0, projectionMatrix, 0, viewMatrix, 0)

      // Render the image with effects
      renderWithEffects()
    }
  }

  /**
   * Calculate viewport dimensions to maintain aspect ratio
   */
  private fun calculateViewport() {
    if (imageWidth > 0 && imageHeight > 0 && surfaceWidth > 0 && surfaceHeight > 0) {
      val imageAspectRatio = imageWidth.toFloat() / imageHeight.toFloat()
      val viewAspectRatio = surfaceWidth.toFloat() / surfaceHeight.toFloat()

      if (viewAspectRatio > imageAspectRatio) {
        // View is wider than image - fit to height
        viewportHeight = surfaceHeight
        viewportWidth = (surfaceHeight * imageAspectRatio).toInt()
        viewportX = (surfaceWidth - viewportWidth) / 2
        viewportY = 0
      } else {
        // View is taller than or equal to image - fit to width
        viewportWidth = surfaceWidth
        viewportHeight = (surfaceWidth / imageAspectRatio).toInt()
        viewportX = 0
        viewportY = (surfaceHeight - viewportHeight) / 2
      }
    } else {
      // Default to full surface if dimensions not available
      viewportX = 0
      viewportY = 0
      viewportWidth = surfaceWidth
      viewportHeight = surfaceHeight
    }
  }

  /**
   * Initialize OpenGL objects
   */
  private fun initializeGL() {
    GLES20.glEnable(GLES20.GL_BLEND)
    GLES20.glBlendFunc(GLES20.GL_SRC_ALPHA, GLES20.GL_ONE_MINUS_SRC_ALPHA)

    // Create vertex buffer
    val vertices = floatArrayOf(
      -1f, -1f, 0f, 1f,  // Bottom left (note: texture coords are flipped on Y)
      1f, -1f, 1f, 1f,   // Bottom right
      -1f,  1f, 0f, 0f,  // Top left
      1f,  1f, 1f, 0f    // Top right
    )

    val bb = ByteBuffer.allocateDirect(vertices.size * 4)
    bb.order(ByteOrder.nativeOrder())
    vertexBuffer = bb.asFloatBuffer()
    vertexBuffer?.put(vertices)
    vertexBuffer?.position(0)

    // Create shader program
    program = createShaderProgram()

    // Get uniform and attribute locations
    mvpMatrixHandle = GLES20.glGetUniformLocation(program, "uMVPMatrix")
    textureHandle = GLES20.glGetUniformLocation(program, "uTexture")
    lutTextureHandle = GLES20.glGetUniformLocation(program, "uLutTexture")
    useLutHandle = GLES20.glGetUniformLocation(program, "uUseLut")
    exposureHandle = GLES20.glGetUniformLocation(program, "uExposure")
    contrastHandle = GLES20.glGetUniformLocation(program, "uContrast")
    saturationHandle = GLES20.glGetUniformLocation(program, "uSaturation")
    temperatureHandle = GLES20.glGetUniformLocation(program, "uTemperature")
    tintHandle = GLES20.glGetUniformLocation(program, "uTint")
    positionHandle = GLES20.glGetAttribLocation(program, "vPosition")
    texCoordHandle = GLES20.glGetAttribLocation(program, "vTexCoord")

    // Generate texture
    val textures = IntArray(1)
    GLES20.glGenTextures(1, textures, 0)
    textureId = textures[0]
  }

  /**
   * Load an image file
   */
  fun loadImageFile(filePath: String): Int {
    val file = File(filePath)
    if (!file.exists() || !file.isFile) return ERROR_FILE_NOT_FOUND

    try {
      val options = BitmapFactory.Options().apply {
        inJustDecodeBounds = false
        inSampleSize = calculateInSampleSize(filePath, 4096, 4096)
        inPreferredConfig = Bitmap.Config.ARGB_8888
      }

      // Load the new bitmap
      val newBitmap = BitmapFactory.decodeFile(filePath, options)
      if (newBitmap == null) return ERROR_IMAGE_DECODE_FAILED

      imageWidth = newBitmap.width
      imageHeight = newBitmap.height

      // Handle bitmap replacement on GL thread
      view.queueEvent {
        // Store old bitmap for recycling after texture upload
        val oldBitmap = originalBitmap

        // Set the new bitmap
        originalBitmap = newBitmap

        // Update viewport and upload texture
        calculateViewport()
        uploadTextureToGPU()

        // Now safely recycle the old bitmap
        oldBitmap?.recycle()

        view.requestRender()
      }

      return SUCCESS
    } catch (e: Exception) {
      Log.e(TAG, "Failed to load image: ${e.message}", e)
      return ERROR_IMAGE_DECODE_FAILED
    }
  }

  /**
   * Upload bitmap to GPU texture
   */
  private fun uploadTextureToGPU() {
    if (!isGLInitialized) return

    originalBitmap?.let { bitmap ->
      if (!bitmap.isRecycled) {
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textureId)
        GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, 0, bitmap, 0)

        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE)
      }
    }
  }

  /**
   * Load a LUT filter file
   */
  fun loadFilterFile(filePath: String): Int {
    val file = File(filePath)
    if (!(file.exists() && file.isFile)) {
      return ERROR_FILE_NOT_FOUND
    }

    try {
      filters.loadLutFilter(filePath)
      view.requestRender()
      return SUCCESS
    } catch (e: Exception) {
      Log.e(TAG, "Failed to load filter: ${e.message}", e)
      return ERROR_FILTER_LOAD_FAILED
    }
  }

  /**
   * Remove LUT filter
   */
  fun removeLutFilter() {
    filters.removeLutFilter()
    view.requestRender()
  }

  /**
   * Set exposure value
   */
  fun setExposure(value: Float) {
    filters.exposure.value = value
    view.requestRender()
  }

  /**
   * Set contrast value
   */
  fun setContrast(value: Float) {
    filters.contrast.value = value
    view.requestRender()
  }

  /**
   * Set saturation value
   */
  fun setSaturation(value: Float) {
    filters.saturation.value = value
    view.requestRender()
  }

  /**
   * Set temperature value
   */
  fun setTemperature(value: Float) {
    filters.temperature.value = value
    view.requestRender()
  }

  /**
   * Set tint value
   */
  fun setTint(value: Float) {
    filters.tint.value = value
    view.requestRender()
  }

  /**
   * Capture current frame as ByteArray
   * This can be called when you need to export the current state
   */
  fun captureCurrentFrame(): Int {
    if (originalBitmap == null) {
      return ERROR_NO_IMAGE_LOADED
    }

    view.queueEvent {
      try {
        // Wait for the current frame to be rendered
        GLES20.glFinish()

        // Read pixels only from the viewport area where the image is rendered
        val pixelBuffer = ByteBuffer.allocateDirect(viewportWidth * viewportHeight * 4)
        pixelBuffer.order(ByteOrder.nativeOrder())

        GLES20.glReadPixels(
          viewportX, viewportY, viewportWidth, viewportHeight,
          GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, pixelBuffer
        )

        val pixelArray = ByteArray(viewportWidth * viewportHeight * 4)
        pixelBuffer.rewind()
        pixelBuffer.get(pixelArray)

        // OpenGL reads pixels from bottom-left, but images are typically top-left
        // Flip the image vertically
        val flippedArray = ByteArray(viewportWidth * viewportHeight * 4)
        val bytesPerRow = viewportWidth * 4

        for (y in 0 until viewportHeight) {
          val sourceRow = (viewportHeight - 1 - y) * bytesPerRow
          val destRow = y * bytesPerRow
          System.arraycopy(pixelArray, sourceRow, flippedArray, destRow, bytesPerRow)
        }

        processCompleteCb?.invoke(id, flippedArray)
      } catch (e: Exception) {
        Log.e(TAG, "Failed to capture frame: ${e.message}", e)
      }
    }

    return SUCCESS
  }

  /**
   * Render the image with applied effects
   */
  private fun renderWithEffects() {
    // Use shader program
    GLES20.glUseProgram(program)

    // Bind texture
    GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
    GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textureId)

    // Set uniforms
    GLES20.glUniformMatrix4fv(mvpMatrixHandle, 1, false, mvpMatrix, 0)
    GLES20.glUniform1i(textureHandle, 0)

    // Set effect parameters
    GLES20.glUniform1f(exposureHandle, filters.exposure.value)
    GLES20.glUniform1f(contrastHandle, filters.contrast.value)
    GLES20.glUniform1f(saturationHandle, filters.saturation.value)
    GLES20.glUniform1f(temperatureHandle, filters.temperature.value)
    GLES20.glUniform1f(tintHandle, filters.tint.value)

    // Handle LUT
    GLES20.glUniform1i(useLutHandle, if (filters.lutFilter != null) 1 else 0)

    // Enable vertex arrays
    GLES20.glEnableVertexAttribArray(positionHandle)
    GLES20.glEnableVertexAttribArray(texCoordHandle)

    // Set vertex data
    vertexBuffer?.position(0)
    GLES20.glVertexAttribPointer(positionHandle, 2, GLES20.GL_FLOAT, false, 16, vertexBuffer)

    vertexBuffer?.position(2)
    GLES20.glVertexAttribPointer(texCoordHandle, 2, GLES20.GL_FLOAT, false, 16, vertexBuffer)

    // Draw
    GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)

    // Disable vertex arrays
    GLES20.glDisableVertexAttribArray(positionHandle)
    GLES20.glDisableVertexAttribArray(texCoordHandle)
  }

  /**
   * Calculate appropriate sample size for large images
   */
  private fun calculateInSampleSize(filePath: String, reqWidth: Int, reqHeight: Int): Int {
    val options = BitmapFactory.Options().apply {
      inJustDecodeBounds = true
    }
    BitmapFactory.decodeFile(filePath, options)

    val height = options.outHeight
    val width = options.outWidth
    var inSampleSize = 1

    if (height > reqHeight || width > reqWidth) {
      val halfHeight = height / 2
      val halfWidth = width / 2

      while (halfHeight / inSampleSize >= reqHeight && halfWidth / inSampleSize >= reqWidth) {
        inSampleSize *= 2
      }
    }

    return inSampleSize
  }

  /**
   * Reset all filters to default values
   */
  fun resetFilters() {
    filters.resetAll()
    view.requestRender()
  }

  /**
   * Create shader program with all effects
   */
  private fun createShaderProgram(): Int {
    val vertexShaderCode = """
            uniform mat4 uMVPMatrix;
            attribute vec4 vPosition;
            attribute vec2 vTexCoord;
            varying vec2 texCoord;
            
            void main() {
                gl_Position = uMVPMatrix * vPosition;
                texCoord = vTexCoord;
            }
        """.trimIndent()

    val fragmentShaderCode = """
            precision mediump float;
            varying vec2 texCoord;
            uniform sampler2D uTexture;
            uniform sampler2D uLutTexture;
            uniform int uUseLut;
            
            uniform float uExposure;
            uniform float uContrast;
            uniform float uSaturation;
            uniform float uTemperature;
            uniform float uTint;
            
            vec3 applyExposure(vec3 color, float exposure) {
                return color * pow(2.0, exposure);
            }
            
            vec3 applyContrast(vec3 color, float contrast) {
                return (color - 0.5) * contrast + 0.5;
            }
            
            vec3 applySaturation(vec3 color, float saturation) {
                float gray = dot(color, vec3(0.2126, 0.7152, 0.0722));
                return mix(vec3(gray), color, saturation);
            }
            
            vec3 applyTemperature(vec3 color, float temp) {
                float scaledTemp = (temp - 6500.0) / 4500.0 * 0.2;
                color.r += scaledTemp;
                color.b -= scaledTemp;
                return color;
            }
            
            vec3 applyTint(vec3 color, float tint) {
                float scaledTint = tint / 200.0 * 0.2;
                color.g += scaledTint;
                return color;
            }
            
            void main() {
                vec4 texColor = texture2D(uTexture, texCoord);
                vec3 color = texColor.rgb;
                
                color = applyExposure(color, uExposure);
                color = applyContrast(color, uContrast);
                color = applySaturation(color, uSaturation);
                color = applyTemperature(color, uTemperature);
                color = applyTint(color, uTint);
                
                color = clamp(color, 0.0, 1.0);
                gl_FragColor = vec4(color, texColor.a);
            }
        """.trimIndent()

    val vertexShader = loadShader(GLES20.GL_VERTEX_SHADER, vertexShaderCode)
    val fragmentShader = loadShader(GLES20.GL_FRAGMENT_SHADER, fragmentShaderCode)

    val program = GLES20.glCreateProgram()
    GLES20.glAttachShader(program, vertexShader)
    GLES20.glAttachShader(program, fragmentShader)
    GLES20.glLinkProgram(program)

    val linkStatus = IntArray(1)
    GLES20.glGetProgramiv(program, GLES20.GL_LINK_STATUS, linkStatus, 0)
    if (linkStatus[0] == 0) {
      Log.e(TAG, "Error linking program: ${GLES20.glGetProgramInfoLog(program)}")
      GLES20.glDeleteProgram(program)
      return 0
    }

    return program
  }

  private fun loadShader(type: Int, shaderCode: String): Int {
    val shader = GLES20.glCreateShader(type)
    GLES20.glShaderSource(shader, shaderCode)
    GLES20.glCompileShader(shader)

    val compileStatus = IntArray(1)
    GLES20.glGetShaderiv(shader, GLES20.GL_COMPILE_STATUS, compileStatus, 0)
    if (compileStatus[0] == 0) {
      Log.e(TAG, "Error compiling shader: ${GLES20.glGetShaderInfoLog(shader)}")
      GLES20.glDeleteShader(shader)
      return 0
    }

    return shader
  }

  /**
   * Dispose of all resources
   */
  fun dispose() {
    view.queueEvent {
      // Clean up GL resources
      if (textureId != 0) {
        GLES20.glDeleteTextures(1, intArrayOf(textureId), 0)
        textureId = 0
      }
      if (program != 0) {
        GLES20.glDeleteProgram(program)
        program = 0
      }
    }

    // Clean up bitmap
    originalBitmap?.recycle()
    originalBitmap = null
  }

  companion object {
    private const val TAG = "ImageEditor"

    const val SUCCESS = 0
    const val ERROR_FILE_NOT_FOUND = -1
    const val ERROR_IMAGE_DECODE_FAILED = -2
    const val ERROR_FILTER_LOAD_FAILED = -3
    const val ERROR_GL_PROCESSING_FAILED = -4
    const val ERROR_NO_IMAGE_LOADED = -5
  }
}