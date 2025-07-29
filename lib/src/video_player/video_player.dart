import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'video_player_api.dart';
import 'video_player_state.dart';

import '../platform/android/video_preview_api.dart';
import '../platform/ui_kit/video_preview_api.dart';

/// A controller for a single video preview instance.
///
/// This class manages the playback state of a video preview widget. It acts as
/// a bridge between the Flutter UI and the underlying native video player
/// implementation.
///
/// A [VideoPreviewController] is responsible for a single video preview widget
/// and cannot be used to control multiple previews simultaneously.
///
/// Before any control methods (like [play] or [pause]) can be called, the
/// controller must be "bound" to a [VideoPreview] widget. This binding
/// typically happens when the native view is created. You can check if the
/// controller is bound using the [isBound] property. Attempting to use a
/// method before the controller is bound will result in an [Exception].
final class VideoPlayerController extends ChangeNotifier {
  static final Finalizer<(VideoPlayerPlatformApi, int)> _finalizer =
      Finalizer((value) => value.$1.remove(value.$2));

  /// Internal constructor for creating a [VideoPreviewController].
  ///
  /// This is used by the factory constructor to inject the appropriate
  /// platform-specific API implementation.
  VideoPlayerController._(this._api, this.viewId);

  /// Creates a [VideoPreviewController] with a platform-specific implementation.
  ///
  /// This factory detects the current operating system and initializes the
  /// controller with the correct underlying API implementation.
  ///
  /// - For iOS, it uses [VideoPreviewDarwinApi].
  /// - For Android, it uses [VideoPreviewAndroidApi].
  ///
  /// Throws an [UnimplementedError] if the target platform is not supported.
  factory VideoPlayerController() {
    final controller = VideoPlayerController._(
      switch (defaultTargetPlatform) {
        TargetPlatform.iOS => VideoPlayerDarwinApi(),
        TargetPlatform.android => VideoPlayerAndroidApi(),
        _ => throw UnimplementedError(),
      },
      ++_nextId,
    );

    controller._api.create(controller.viewId);

    // Attach for disposal
    _finalizer.attach(
      controller,
      (controller._api, controller.viewId),
      detach: controller,
    );

    return controller;
  }

  /// The underlying platform-specific API used to control the native video view.
  ///
  /// This object handles the actual communication with the native code.
  @protected
  final VideoPlayerPlatformApi _api;

  ///
  Stream<VideoPlayerState> get stateStream => _api.stateStream;

  ///
  Stream<Duration> get progressStream => _api.progressStream;

  ///
  Stream<Duration> get durationStream => _api.durationStream;

  ///
  Stream<double> get aspectRatioStream => _api.aspectRatioStream;

  ///
  Duration? get progress => _api.progress;

  ///
  Duration? get duration => _api.duration;

  ///
  VideoPlayerState? get state => _api.state;

  ///
  double? get aspectRatio => _api.aspectRatio;

  /// Starts or resumes video playback.
  ///
  /// If the video is paused, it will resume from the current position, if the
  /// video has finished, it will restart from the beginning.
  ///
  /// Throws and [Exception] if the controller is not yet bound.
  void play() {
    _api.play(viewId);
  }

  /// Seeks the video to a specific position.
  ///
  /// [value] The time position to seek to, specified in seconds.
  ///
  /// Throws an [Exception] if the controller is not yet bound.
  void seekTo(int value) {
    _api.seekTo(viewId, value);
  }

  /// Pauses video playback.
  ///
  /// If the video is already paused, this method has no effect.
  ///
  /// Throws an [Exception] if the controller is not yet bound.
  void pause() {
    _api.pause(viewId);
  }

  ///
  void loadFilterFile(String filePath) {
    _api.loadFilterFile(viewId, filePath);
  }

  ///
  void removeFilterFile() {
    _api.removeFilterFile(viewId);
  }

  ///
  void loadAssetVideo(String locator) {
    _api.loadAssetVideo(viewId, locator);
  }

  ///
  void loadFileVideo(String filePath) {
    _api.loadFileVideo(viewId, filePath);
  }

  ///
  void loadNetworkVideo(String url) {
    _api.loadNetworkVideo(viewId, url);
  }

  ///
  void setExposure(double exposure) {
    _api.setExposure(viewId, exposure);
  }

  ///
  void setContrast(double contrast) {
    _api.setContrast(viewId, contrast);
  }

  ///
  void setSaturation(double saturation) {
    _api.setSaturation(viewId, saturation);
  }

  ///
  void setTemperature(double temperature) {
    _api.setTemperature(viewId, temperature);
  }

  ///
  void setTint(double tint) {
    _api.setTint(viewId, tint);
  }

  /// Exports a video with applied filter to a specified location.
  ///
  /// [videoPath] Path to the input video file.
  /// [filterPath] Path to the filter/LUT file to apply (can be null for no filter).
  /// [outputPath] Directory where the exported video should be saved.
  /// [outputWidth] Desired output width in pixels.
  /// [outputHeight] Desired output height in pixels.
  /// [maintainAspectRatio] Whether to maintain the original aspect ratio.
  /// Returns a [Future<String>] containing the path to the exported video file.
  Future<String> exportVideo({
    required String videoPath,
    String? filterPath,
    required String outputPath,
    required int outputWidth,
    required int outputHeight,
    required bool maintainAspectRatio,
  }) {
    return _api.exportVideo(
      viewId: viewId,
      videoPath: videoPath,
      filterPath: filterPath,
      outputPath: outputPath,
      outputWidth: outputWidth,
      outputHeight: outputHeight,
      maintainAspectRatio: maintainAspectRatio,
    );
  }

  /// The unique identifier for the native view associated with this controller.
  ///
  /// This ID is assigned by the Flutter engine when the native view is created
  /// and is used to direct commands to the correct native player instance.
  ///
  /// Throws a [StateError] if accessed before the controller is bound.
  /// This property is intended for internal use and by subclasses.
  final int viewId;

  @override
  void dispose() {
    _api.remove(viewId);
    super.dispose();
  }

  static int _nextId = -1;
}

class VideoPlayer extends StatelessWidget {
  const VideoPlayer({super.key, required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    const kViewType = 'media_filters.preview';

    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => UiKitView(
          viewType: kViewType,
          creationParams: controller.viewId,
          creationParamsCodec: const StandardMessageCodec()),
      TargetPlatform.android => AndroidView(
          viewType: kViewType,
          creationParams: controller.viewId,
          creationParamsCodec: const StandardMessageCodec()),
      _ => throw UnimplementedError(),
    };
  }
}
