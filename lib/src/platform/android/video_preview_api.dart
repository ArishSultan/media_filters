import 'dart:async';

import 'package:jni/jni.dart';

import 'jni.dart';

import '../../video_player/video_player_api.dart';
import '../../video_player/video_player_state.dart';

final class VideoPlayerAndroidApi extends VideoPlayerPlatformApi {
  @override
  Stream<VideoPlayerState> get state => _stateStreamController.stream;

  @override
  Stream<Duration> get progress => _progressStreamController.stream;

  @override
  Stream<Duration> get duration => _durationStreamController.stream;

  final _stateStreamController = StreamController<VideoPlayerState>.broadcast();
  final _progressStreamController = StreamController<Duration>.broadcast();
  final _durationStreamController = StreamController<Duration>.broadcast();

  @override
  void pause(int viewId) {
    ApiVideoPlayer.pause(viewId);
  }

  @override
  void play(int viewId) {
    ApiVideoPlayer.play(viewId);
  }

  @override
  void seekTo(int viewId, int value) {
    ApiVideoPlayer.seekTo(viewId, value);
  }

  @override
  void loadFilterFile(int viewId, String filePath) {
    ApiVideoPlayer.loadFilterFile(viewId, filePath.toJString());
  }

  @override
  void removeFilterFile(int viewId) {
    ApiVideoPlayer.removeLutFilter(viewId);
  }

  @override
  void loadAssetVideo(int viewId, String locator) {
    // TODO: implement loadAssetVideo
  }

  @override
  void loadFileVideo(int viewId, String path) {
    ApiVideoPlayer.loadVideoFile(viewId, path.toJString());
  }

  @override
  void loadNetworkVideo(int viewId, String url) {
    // TODO: implement loadNetworkVideo
  }

  @override
  void removeStateCallbacks(int viewId) {
    _stateStreamControllerRegister.remove(viewId);
    _progressStreamControllerRegister.remove(viewId);
    _durationStreamControllerRegister.remove(viewId);

    ApiVideoPlayer.removeStateCallbacks(viewId);
  }

  @override
  void setStateCallbacks(int viewId) {
    _stateStreamControllerRegister[viewId] = _stateStreamController;
    _progressStreamControllerRegister[viewId] = _progressStreamController;
    _durationStreamControllerRegister[viewId] = _durationStreamController;

    ApiVideoPlayer.setStateCallbacks(
      viewId,
      IntegerValueCallback.implement(_StateCallback.instance),
      LongValueCallback.implement(_DurationCallback.instance),
      LongValueCallback.implement(_ProgressCallback.instance),
    );
  }

  ///
  @override
  void setExposure(int viewId, double exposure) {
    ApiVideoPlayer.setExposure(viewId, exposure);
  }

  ///
  @override
  void setContrast(int viewId, double contrast) {
    ApiVideoPlayer.setContrast(viewId, contrast);
  }

  ///
  @override
  void setSaturation(int viewId, double saturation) {
    ApiVideoPlayer.setSaturation(viewId, saturation);
  }

  ///
  @override
  void setTemperature(int viewId, double temperature) {
    ApiVideoPlayer.setTemperature(viewId, temperature);
  }

  ///
  @override
  void setTint(int viewId, double tint) {
    ApiVideoPlayer.setTint(viewId, tint);
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
    // ApiVideoPlayer.exportVideo(
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

  @override
  void create(int viewId) {
    ApiVideoPlayer.create(viewId);
  }

  @override
  void dispose(int viewId) {
    ApiVideoPlayer.destroy(viewId);
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
    <int, StreamController<VideoPlayerState>>{};

final class _StateCallback with $IntegerValueCallback {
  static final instance = _StateCallback();

  @override
  void invoke(int viewId, int state) {
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
}

final class _ProgressCallback with $LongValueCallback {
  static final instance = _ProgressCallback();

  @override
  void invoke(int viewId, int progress) {
    _progressStreamControllerRegister[viewId]?.add(
      Duration(milliseconds: progress),
    );
  }
}

final class _DurationCallback with $LongValueCallback {
  static final instance = _DurationCallback();

  @override
  void invoke(int viewId, int duration) {
    _durationStreamControllerRegister[viewId]?.add(
      Duration(milliseconds: duration),
    );
  }
}
