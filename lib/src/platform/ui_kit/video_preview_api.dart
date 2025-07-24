import 'dart:async';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'ffi.dart';
import 'ffi_typedef.dart';

import '../../video_preview/video_preview_api.dart';
import '../../video_preview/video_preview_state.dart';

final class VideoPreviewDarwinApi extends VideoPreviewPlatformApi {
  VideoPreviewDarwinApi() {
    DarwinFFI.initialize();
  }

  @override
  Stream<VideoPreviewState> get state => _stateStreamController.stream;

  @override
  Stream<Duration> get progress => _progressStreamController.stream;

  @override
  Stream<Duration> get duration => _durationStreamController.stream;

  @override
  void pause(int viewId) {
    DarwinFFI.vpPause(viewId);
  }

  @override
  void play(int viewId) {
    DarwinFFI.vpPlay(viewId);
  }

  @override
  void seekTo(int viewId, int value) {
    DarwinFFI.vpSeek(viewId, value);
  }

  @override
  void loadFilterFile(int viewId, String filePath) {
    final filePathPtr = filePath.toNativeUtf8();
    DarwinFFI.vpLoadLutFile(viewId, filePathPtr);
    malloc.free(filePathPtr);

    // return result;
  }

  @override
  void loadVideoFile(int viewId, String filePath) {
    final filePathPtr = filePath.toNativeUtf8();
    DarwinFFI.vpLoadVideoFile(viewId, filePathPtr);
    malloc.free(filePathPtr);

    // return result;
  }

  final _stateStreamController =
      StreamController<VideoPreviewState>.broadcast();
  final _progressStreamController = StreamController<Duration>.broadcast();
  final _durationStreamController = StreamController<Duration>.broadcast();

  @override
  void removeStateCallbacks(int viewId) {
    _stateStreamControllerRegister.remove(viewId);
    _progressStreamControllerRegister.remove(viewId);
    _durationStreamControllerRegister.remove(viewId);

    DarwinFFI.vpRemoveStateCallbacks(viewId);
  }

  @override
  void setStateCallbacks(int viewId) {
    _stateStreamControllerRegister[viewId] = _stateStreamController;
    _progressStreamControllerRegister[viewId] = _progressStreamController;
    _durationStreamControllerRegister[viewId] = _durationStreamController;

    DarwinFFI.vpSetStateCallbacks(
      viewId,
      _onStateCallbackPtr.nativeFunction,
      _onProgressCallbackPtr.nativeFunction,
      _onDurationCallbackPtr.nativeFunction,
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
    final videoPathPtr = videoPath.toNativeUtf8();
    final filterPathPtr = filterPath?.toNativeUtf8();
    final outputPathPtr = outputPath.toNativeUtf8();

    // Create a completer to handle the async result
    final completer = Completer<String>();
    final exportId = DateTime.now().millisecondsSinceEpoch;
    _exportCompleters[exportId] = completer;

    try {
      final result = DarwinFFI.vpExportVideo(
        viewId,
        videoPathPtr,
        filterPathPtr ?? nullptr,
        outputPathPtr,
        outputWidth,
        outputHeight,
        maintainAspectRatio ? 1 : 0,
        exportId,
        _onExportCompletePtr.nativeFunction,
      );

      if (result != 0) {
        _exportCompleters.remove(exportId);
        throw Exception('Failed to start video export: error code $result');
      }

      return await completer.future;
    } finally {
      malloc.free(videoPathPtr);
      if (filterPathPtr != null) malloc.free(filterPathPtr);
      malloc.free(outputPathPtr);
    }
  }

  static final _onStateCallbackPtr =
      NativeCallable<VPStateCallbackFFI>.listener(
    _onStateCallback,
  );

  static final _onProgressCallbackPtr =
      NativeCallable<VPProgressCallbackFFI>.listener(
    _onProgressCallback,
  );

  static final _onDurationCallbackPtr =
      NativeCallable<VPDurationCallbackFFI>.listener(
    _onDurationCallback,
  );

  static final _onExportCompletePtr =
      NativeCallable<VPExportCompleteCallbackFFI>.listener(
    _onExportComplete,
  );
}

final _exportCompleters = <int, Completer<String>>{};

void _onExportComplete(int exportId, Pointer<Utf8> outputPath, int errorCode) {
  final completer = _exportCompleters.remove(exportId);
  if (completer != null) {
    if (errorCode == 0) {
      completer.complete(outputPath.toDartString());
    } else {
      completer.completeError(Exception('Export failed with error code: $errorCode'));
    }
  }
}

final _durationStreamControllerRegister = <int, StreamController<Duration>>{};
final _progressStreamControllerRegister = <int, StreamController<Duration>>{};
final _stateStreamControllerRegister =
    <int, StreamController<VideoPreviewState>>{};

void _onStateCallback(int viewId, int state) {
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

void _onProgressCallback(int viewId, double progress) {
  _progressStreamControllerRegister[viewId]?.add(
    Duration(microseconds: (progress * 1000000).round()),
  );
}

void _onDurationCallback(int viewId, double progress) {
  _durationStreamControllerRegister[viewId]?.add(
    Duration(microseconds: (progress * 1000000).round()),
  );
}
