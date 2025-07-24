import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'video_preview_api.dart';
import 'video_preview_state.dart';

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
final class VideoPreviewController extends ChangeNotifier {
  /// Internal constructor for creating a [VideoPreviewController].
  ///
  /// This is used by the factory constructor to inject the appropriate
  /// platform-specific API implementation.
  VideoPreviewController._(this.api);

  /// Creates a [VideoPreviewController] with a platform-specific implementation.
  ///
  /// This factory detects the current operating system and initializes the
  /// controller with the correct underlying API implementation.
  ///
  /// - For iOS, it uses [VideoPreviewDarwinApi].
  /// - For Android, it uses [VideoPreviewAndroidApi].
  ///
  /// Throws an [UnimplementedError] if the target platform is not supported.
  factory VideoPreviewController() {
    return VideoPreviewController._(switch (defaultTargetPlatform) {
      TargetPlatform.iOS => VideoPreviewDarwinApi(),
      TargetPlatform.android => VideoPreviewAndroidApi(),
      _ => throw UnimplementedError(),
    });
  }

  /// The underlying platform-specific API used to control the native video view.
  ///
  /// This object handles the actual communication with the native code.
  @protected
  final VideoPreviewPlatformApi api;

  /// Whether the controller is currently bound to a [VideoPreview] widget.
  ///
  /// A controller is considered "bound" after associated platform view has been
  /// created and its unique identifier ([viewId]) has been set.
  ///
  /// Playback control methods like [play], [pause] and [seekTo] etc.. will throw
  /// an exception if called when [isBound] is `false`.
  bool get isBound => _viewId != null;

  ///
  Stream<VideoPreviewState> get state => api.state;

  ///
  Stream<Duration> get progress => api.progress;

  ///
  Stream<Duration> get duration => api.duration;

  /// Starts or resumes video playback.
  ///
  /// If the video is paused, it will resume from the current position, if the
  /// video has finished, it will restart from the beginning.
  ///
  /// Throws and [Exception] if the controller is not yet bound.
  void play() {
    validateIsBound();

    api.play(viewId);
  }

  /// Seeks the video to a specific position.
  ///
  /// [value] The time position to seek to, specified in seconds.
  ///
  /// Throws an [Exception] if the controller is not yet bound.
  void seekTo(int value) {
    validateIsBound();

    api.seekTo(viewId, value);
  }

  /// Pauses video playback.
  ///
  /// If the video is already paused, this method has no effect.
  ///
  /// Throws an [Exception] if the controller is not yet bound.
  void pause() {
    validateIsBound();

    api.pause(viewId);
  }

  ///
  void loadFilterFile(String filePath) {
    validateIsBound();

    api.loadFilterFile(viewId, filePath);
  }

  ///
  void loadVideoFile(String filePath) {
    validateIsBound();

    api.loadVideoFile(viewId, filePath);
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
    validateIsBound();

    return api.exportVideo(
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
  @protected
  int get viewId => _viewId!;

  /// Ensures that the controller is bound to a view before proceeding.
  ///
  /// This is an internal utility to prevent calling platform methods with a
  /// null `viewId`.
  ///
  /// Throws an [Exception] with a descriptive message if the controller
  /// is not bound.
  @protected
  void validateIsBound() {
    if (isBound) {
      return;
    }

    throw Exception('This [$this] has not been found to any [VideoPreview]');
  }

  @override
  void dispose() {
    if (_viewId != null) {
      // api.dispose(_viewId!);
    }

    super.dispose();
  }

  /// A private nullable field to store the unique identifier of the native view.
  ///
  /// This value is `null` until the controller is bound to a [VideoPreview] widget.
  int? _viewId;

  ///
  void _bindPlatformView(int viewId) {
    _viewId = viewId;

    api.setStateCallbacks(viewId);
  }

  ///
  void _unbindPlatformView() {
    _viewId = null;

    api.removeStateCallbacks(viewId);
  }
}

class VideoPreview extends StatefulWidget {
  const VideoPreview({super.key, required this.controller});

  final VideoPreviewController controller;

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  @override
  Widget build(BuildContext context) {
    const kViewType = 'media_filters.preview';

    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => UiKitView(
          viewType: kViewType,
          onPlatformViewCreated: widget.controller._bindPlatformView,
        ),
      TargetPlatform.android => AndroidView(
          viewType: kViewType,
          onPlatformViewCreated: widget.controller._bindPlatformView,
        ),
      _ => throw UnimplementedError(),
    };
  }

  @override
  void dispose() {
    widget.controller._unbindPlatformView();
    super.dispose();
  }
}
