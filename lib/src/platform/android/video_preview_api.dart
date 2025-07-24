import 'dart:async';

import 'package:jni/jni.dart';

import 'jni.dart';

import '../../video_preview/video_preview_api.dart';
import '../../video_preview/video_preview_state.dart';

final class VideoPreviewAndroidApi extends VideoPreviewPlatformApi {
  @override
  Stream<VideoPreviewState> get state => _stateStreamController.stream;

  @override
  Stream<Duration> get progress => _progressStreamController.stream;

  @override
  Stream<Duration> get duration => _durationStreamController.stream;

  final _stateStreamController =
      StreamController<VideoPreviewState>.broadcast();
  final _progressStreamController = StreamController<Duration>.broadcast();
  final _durationStreamController = StreamController<Duration>.broadcast();

  @override
  void pause(int viewId) {
    ApiVideoPreview.pause(viewId);
  }

  @override
  void play(int viewId) {
    ApiVideoPreview.play(viewId);
  }

  @override
  void seekTo(int viewId, int value) {
    ApiVideoPreview.seekTo(viewId, value);
  }

  @override
  void loadFilterFile(int viewId, String filePath) {
    ApiVideoPreview.loadFilterFile(viewId, filePath.toJString());
  }

  @override
  void loadVideoFile(int viewId, String filePath) {
    ApiVideoPreview.loadVideoFile(viewId, filePath.toJString());
  }

  @override
  void removeStateCallbacks(int viewId) {
    _stateStreamControllerRegister.remove(viewId);
    _progressStreamControllerRegister.remove(viewId);
    _durationStreamControllerRegister.remove(viewId);

    ApiVideoPreview.removeStateCallbacks(viewId);
  }

  @override
  void setStateCallbacks(int viewId) {
    _stateStreamControllerRegister[viewId] = _stateStreamController;
    _progressStreamControllerRegister[viewId] = _progressStreamController;
    _durationStreamControllerRegister[viewId] = _durationStreamController;

    ApiVideoPreview.setStateCallbacks(
      viewId,
      IntegerValueCallback.implement(_StateCallback.instance),
      IntegerValueCallback.implement(_DurationCallback.instance),
      IntegerValueCallback.implement(_ProgressCallback.instance),
    );
  }

  @override
  Future<String> exportVideo({
    required int viewId,
    required String videoPath,
    String? filterPath,
    required String outputPath,
    required int outputWidth,
    required int outputHeight,
    required bool maintainAspectRatio,
  }) async {
    return "";
    // final completer = Completer<String>();
    // final exportId = DateTime.now().millisecondsSinceEpoch;
    // _exportCompleters[exportId] = completer;
    //
    // // Create callback for export completion
    // final callback = StringValueCallback.implement(_ExportCallback(exportId));
    //
    // ApiVideoPreview.exportVideo(
    //   viewId,
    //   videoPath.toJString(),
    //   filterPath?.toJString(),
    //   outputPath.toJString(),
    //   outputWidth,
    //   outputHeight,
    //   maintainAspectRatio,
    //   exportId,
    //   callback,
    // );
    //
    // return completer.future;
  }
}

final _exportCompleters = <int, Completer<String>>{};

// final class _ExportCallback with $StringValueCallback {
//   final int exportId;
//
//   _ExportCallback(this.exportId);
//
//   @override
//   void invoke(int id, JString? result) {
//     final completer = _exportCompleters.remove(exportId);
//     if (completer != null) {
//       if (result != null) {
//         completer.complete(result.toDartString());
//       } else {
//         completer.completeError(Exception('Export failed'));
//       }
//     }
//     result?.release();
//   }
// }

final _durationStreamControllerRegister = <int, StreamController<Duration>>{};
final _progressStreamControllerRegister = <int, StreamController<Duration>>{};
final _stateStreamControllerRegister =
    <int, StreamController<VideoPreviewState>>{};

final class _StateCallback with $IntegerValueCallback {
  static final instance = _StateCallback();

  @override
  void invoke(int viewId, int state) {
    _stateStreamControllerRegister[viewId]?.add(
      switch (state) {
        0 => VideoPreviewState.stopped,
        1 => VideoPreviewState.playing,
        2 => VideoPreviewState.paused,
        3 => VideoPreviewState.ended,
        4 => VideoPreviewState.error,
        _ => throw UnimplementedError(),
      },
    );
  }
}

final class _ProgressCallback with $IntegerValueCallback {
  static final instance = _ProgressCallback();

  @override
  void invoke(int viewId, int progress) {
    _progressStreamControllerRegister[viewId]?.add(
      Duration(milliseconds: progress),
    );
  }
}

final class _DurationCallback with $IntegerValueCallback {
  static final instance = _DurationCallback();

  @override
  void invoke(int viewId, int duration) {
    _durationStreamControllerRegister[viewId]?.add(
      Duration(milliseconds: duration),
    );
  }
}
