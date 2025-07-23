import 'video_preview_state.dart';

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
abstract class VideoPreviewPlatformApi {
  ///
  Stream<VideoPreviewState> get state;

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
  void loadVideoFile(int viewId, String filePath);

  ///
  void loadFilterFile(int viewId, String filePath);

  ///
  void setStateCallbacks(int viewId);

  ///
  void removeStateCallbacks(int viewId);
}
