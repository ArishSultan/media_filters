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
    // TODO: Implement this function.
    //
    // _getMethodChannel(viewId)
    //     ?.invokeMethod('loadFilterFile', {'filePath': filePath});
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
}

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
