import 'dart:async';
import 'dart:ffi';
import 'dart:ui' as ui;

import 'package:ffi/ffi.dart';
import 'package:flutter/widgets.dart' as widgets;

import 'ffi.dart';

import '../video/video_player_platform.dart';

///
final class VideoPlayerDarwin implements VideoPlayerPlatform {
  static const instance = VideoPlayerDarwin._();

  const VideoPlayerDarwin._();

  @override
  ui.Size readSize(int id) {
    final data = darwinFFI.vpGetSize(id);
    final size = ui.Size(data.ref.width, data.ref.height);

    malloc.free(data);

    return size;
  }

  @override
  VideoPlayerState readState(int id) =>
      _stateFromNumber(darwinFFI.vpGetState(id));

  @override
  Duration readDuration(int id) =>
      Duration(milliseconds: darwinFFI.vpGetDuration(id));

  @override
  Duration readProgress(int id) =>
      Duration(milliseconds: darwinFFI.vpGetProgress(id));

  @override
  void setTintFilter(int id, double value) =>
      darwinFFI.vpSetTintFilter(id, value);

  @override
  void setExposureFilter(int id, double value) =>
      darwinFFI.vpSetExposureFilter(id, value);

  @override
  void setContrastFilter(int id, double value) =>
      darwinFFI.vpSetContrastFilter(id, value);

  @override
  void setSaturationFilter(int id, double value) =>
      darwinFFI.vpSetSaturationFilter(id, value);

  @override
  void setTemperatureFilter(int id, double value) =>
      darwinFFI.vpSetTemperatureFilter(id, value);

  @override
  void setLutFilter(int id, String lutFilePath) {
    final lutFilePathPtr = lutFilePath.toNativeUtf8();
    darwinFFI.vpSetLutFilter(id, lutFilePathPtr);
    malloc.free(lutFilePathPtr);
  }

  @override
  void removeLutFilter(int id) => darwinFFI.vpRemoveLutFilter(id);

  @override
  void applyFilter(int id) => darwinFFI.vpApplyFilter(id);

  @override
  Future<void> load(int id, VideoResourceType type, String locator) {
    final completer = Completer();

    _onLoadCallbackRegister[id] = completer.complete;
    _onLoadErrorCallbackRegister[id] = completer.completeError;

    final locatorPtr = locator.toNativeUtf8();
    final typeNum = switch (type) {
      VideoResourceType.asset => 1,
      VideoResourceType.file => 2,
      VideoResourceType.network => 3,
    };

    darwinFFI.vpLoad(
      id,
      typeNum,
      locatorPtr,
      _onLoad$Native.nativeFunction,
      _onLoadError$Native.nativeFunction,
    );

    malloc.free(locatorPtr);

    return completer.future;
  }

  ///
  @override
  void pause(int id) => darwinFFI.vpPause(id);

  ///
  @override
  void play(int id) => darwinFFI.vpPlay(id);

  ///
  @override
  void prepare(int id) {
    _stateStreamControllerRegister[id] = StreamController.broadcast();
    _progressStreamControllerRegister[id] = StreamController.broadcast();

    darwinFFI.vpPrepare(
      id,
      _onState$Native.nativeFunction,
      _onProgress$Native.nativeFunction,
    );
  }

  ///
  @override
  void release(int id) {
    _stateStreamControllerRegister.remove(id)?.close();
    _progressStreamControllerRegister.remove(id)?.close();

    darwinFFI.vpRelease(id);
  }

  ///
  @override
  void seek(int id, int position) {
    darwinFFI.vpSeek(id, position);
  }

  @override
  Stream<Duration> getProgressStream(int id) =>
      _progressStreamControllerRegister[id]!.stream;

  @override
  Stream<VideoPlayerState> getStateStream(int id) =>
      _stateStreamControllerRegister[id]!.stream;
}

final _progressStreamControllerRegister = <int, StreamController<Duration>>{};
final _onProgress$Native = NativeCallable<FFI$ValueCallback<Long>>.listener(
  (int id, int value) {
    final controller = _progressStreamControllerRegister[id];

    if (controller != null && !controller.isClosed) {
      controller.add(Duration(milliseconds: value));
    }
  },
);

VideoPlayerState _stateFromNumber(int number) {
  return switch (number) {
    0 => VideoPlayerState.idle,
    1 => VideoPlayerState.loading,
    2 => VideoPlayerState.ready,
    3 => VideoPlayerState.playing,
    4 => VideoPlayerState.paused,
    5 => VideoPlayerState.stopped,
    6 => VideoPlayerState.completed,
    7 => VideoPlayerState.error,

    //
    _ => throw UnimplementedError(),
  };
}

final _stateStreamControllerRegister =
    <int, StreamController<VideoPlayerState>>{};
final _onState$Native = NativeCallable<FFI$ValueCallback<Int>>.listener(
  (int id, int value) {
    final controller = _stateStreamControllerRegister[id];

    if (controller != null && !controller.isClosed) {
      controller.add(switch (value) {
        0 => VideoPlayerState.idle,
        1 => VideoPlayerState.loading,
        2 => VideoPlayerState.ready,
        3 => VideoPlayerState.playing,
        4 => VideoPlayerState.paused,
        5 => VideoPlayerState.stopped,
        6 => VideoPlayerState.completed,
        7 => VideoPlayerState.error,

        //
        _ => throw UnimplementedError(),
      });
    }
  },
);

final _onLoadCallbackRegister = <int, widgets.VoidCallback>{};
final _onLoad$Native = NativeCallable<FFI$VoidCallback>.listener(
  (int id) => _onLoadCallbackRegister.remove(id)?.call(),
);

final _onLoadErrorCallbackRegister = <int, widgets.ValueChanged<String>>{};
final _onLoadError$Native =
    NativeCallable<FFI$ValueCallback<Pointer<Utf8>>>.listener(
  (int id, Pointer<Utf8> error) {
    _onLoadErrorCallbackRegister.remove(id)?.call(error.toDartString());

    malloc.free(error);
  },
);
