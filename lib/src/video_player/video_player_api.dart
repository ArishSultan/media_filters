import 'video_player_state.dart';

/// Defines the interface for platform-specific video preview implementations.
///
/// This abstract class establishes a contract that all platform-specific API
/// classes (e.g., [VideoPreviewAndroidApi], [VideoPreviewDarwinApi]) must follow.
/// This allows [VideoPreviewController] to interact with the native video player
/// in a platform-agnostic manner.
///
/// Implementations of this class are responsible for forwarding commands to the
/// corresponding native video player instance using a platform channel or a
/// similar mechanism.
abstract class VideoPlayerPlatformApi {
  ///
  Stream<VideoPlayerState> get state;

  ///
  Stream<Duration> get progress;

  ///
  Stream<Duration> get duration;

  /// Starts or resumes playback for the specified native view.
  ///
  /// [viewId] The unique identifier of the native view to control.
  void play(int viewId);

  /// Pauses playback for the specified native view.
  ///
  /// [viewId] The unique identifier of the native view to control.
  void pause(int viewId);

  /// Seeks to a new position in the video for the specified native view.
  ///
  /// [viewId] The unique identifier of the native view to control.
  /// [value] The time position to seek to, in seconds.
  void seekTo(int viewId, int value);

  ///
  void loadAssetVideo(int viewId, String locator);

  ///
  void loadFileVideo(int viewId, String path);

  ///
  void loadNetworkVideo(int viewId, String url);

  ///
  void loadFilterFile(int viewId, String filePath);

  ///
  void setStateCallbacks(int viewId);

  ///
  void removeStateCallbacks(int viewId);

  ///
  void setExposure(int viewId, double exposure);

  ///
  void setContrast(int viewId, double contrast);

  ///
  void setSaturation(int viewId, double saturation);

  ///
  void setTemperature(int viewId, double temperature);

  ///
  void setTint(int viewId, double tint);

  /// Exports a video with applied filter to a specified location.
  ///
  /// [viewId] The unique identifier of the native view.
  /// [videoPath] Path to the input video file.
  /// [filterPath] Path to the filter/LUT file to apply (can be null for no filter).
  /// [outputPath] Directory where the exported video should be saved.
  /// [outputWidth] Desired output width in pixels.
  /// [outputHeight] Desired output height in pixels.
  /// [maintainAspectRatio] Whether to maintain the original aspect ratio.
  /// Returns a [Future<String>] containing the path to the exported video file.
  Future<String> exportVideo({
    required int viewId,
    required String videoPath,
    String? filterPath,
    required String outputPath,
    required int outputWidth,
    required int outputHeight,
    required bool maintainAspectRatio,
  });
}
