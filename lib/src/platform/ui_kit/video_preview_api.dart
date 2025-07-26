import 'dart:async';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'ffi.dart';
import 'ffi_typedef.dart';

import '../../video_player/video_player_api.dart';
import '../../video_player/video_player_state.dart';

final class VideoPlayerDarwinApi extends VideoPlayerPlatformApi {
  VideoPlayerDarwinApi() {
    DarwinFFI.initialize();
  }

  @override
  Stream<VideoPlayerState> get state => _stateStreamController.stream;

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
    DarwinFFI.vpLoadLutFilter(viewId, filePathPtr);
    malloc.free(filePathPtr);
  }

  @override
  void loadAssetVideo(int viewId, String locator) {
    _loadVideo(viewId, locator, 1);
  }

  @override
  void loadFileVideo(int viewId, String path) {
    _loadVideo(viewId, path, 2);
  }

  @override
  void loadNetworkVideo(int viewId, String url) {
    _loadVideo(viewId, url, 3);
  }

  void _loadVideo(int viewId, String locator, int type) {
    final locatorPtr = locator.toNativeUtf8();
    DarwinFFI.vpLoadVideo(viewId, locatorPtr, type);
    malloc.free(locatorPtr);
  }

  final _stateStreamController = StreamController<VideoPlayerState>.broadcast();
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
      _onDurationCallbackPtr.nativeFunction,
      _onProgressCallbackPtr.nativeFunction,
    );
  }

  ///
  @override
  void setExposure(int viewId, double exposure) {
    DarwinFFI.vpSetExposure(viewId, exposure);
  }

  ///
  @override
  void setContrast(int viewId, double contrast) {
    DarwinFFI.vpSetContrast(viewId, contrast);
  }

  ///
  @override
  void setSaturation(int viewId, double saturation) {
    DarwinFFI.vpSetSaturation(viewId, saturation);
  }

  ///
  @override
  void setTemperature(int viewId, double temperature) {
    DarwinFFI.vpSetTemperature(viewId, temperature);
  }

  ///
  @override
  void setTint(int viewId, double tint) {
    DarwinFFI.vpSetTint(viewId, tint);
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
    // final videoPathPtr = videoPath.toNativeUtf8();
    // final filterPathPtr = filterPath?.toNativeUtf8();
    // final outputPathPtr = outputPath.toNativeUtf8();

    // Create a completer to handle the async result
    // final completer = Completer<String>();
    // final exportId = DateTime.now().millisecondsSinceEpoch;
    // _exportCompleters[exportId] = completer;

    // try {
    //   final result = DarwinFFI.vpExportVideo(
    //     viewId,
    //     videoPathPtr,
    //     filterPathPtr ?? nullptr,
    //     outputPathPtr,
    //     outputWidth,
    //     outputHeight,
    //     maintainAspectRatio ? 1 : 0,
    //     exportId,
    //     _onExportCompletePtr.nativeFunction,
    //   );
    //
    //   if (result != 0) {
    //     _exportCompleters.remove(exportId);
    //     throw Exception('Failed to start video export: error code $result');
    //   }
    //
    //   return await completer.future;
    // } finally {
    //   malloc.free(videoPathPtr);
    //   if (filterPathPtr != null) malloc.free(filterPathPtr);
    //   malloc.free(outputPathPtr);
    // }

    return "";
  }

  static final _onStateCallbackPtr =
      NativeCallable<IntegerValueCallbackFFI>.listener(
    _onStateCallback,
  );

  static final _onProgressCallbackPtr =
      NativeCallable<LongValueCallbackFFI>.listener(
    _onProgressCallback,
  );

  static final _onDurationCallbackPtr =
      NativeCallable<LongValueCallbackFFI>.listener(
    _onDurationCallback,
  );

// static final _onExportCompletePtr =
//     NativeCallable<VPExportCompleteCallbackFFI>.listener(
//   _onExportComplete,
// );
}

// final _exportCompleters = <int, Completer<String>>{};
//
// void _onExportComplete(int exportId, Pointer<Utf8> outputPath, int errorCode) {
//   final completer = _exportCompleters.remove(exportId);
//   if (completer != null) {
//     if (errorCode == 0) {
//       completer.complete(outputPath.toDartString());
//     } else {
//       completer.completeError(
//           Exception('Export failed with error code: $errorCode'));
//     }
//   }
// }

final _durationStreamControllerRegister = <int, StreamController<Duration>>{};
final _progressStreamControllerRegister = <int, StreamController<Duration>>{};
final _stateStreamControllerRegister =
    <int, StreamController<VideoPlayerState>>{};

void _onStateCallback(int viewId, int state) {
  _stateStreamControllerRegister[viewId]?.add(
    switch (state) {
      0 => VideoPlayerState.stopped,
      1 => VideoPlayerState.playing,
      2 => VideoPlayerState.paused,
      3 => VideoPlayerState.ended,
      4 => VideoPlayerState.error,
      _ => throw UnimplementedError(),
    },
  );
}

void _onProgressCallback(int viewId, int progress) {
  _progressStreamControllerRegister[viewId]?.add(
    Duration(milliseconds: progress),
  );
}

void _onDurationCallback(int viewId, int progress) {
  _durationStreamControllerRegister[viewId]?.add(
    Duration(milliseconds: progress),
  );
}
