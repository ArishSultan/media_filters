import 'dart:async';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/cupertino.dart';
import 'package:media_filters/src/video_player/video_exporter_api.dart';

import 'ffi.dart';
import 'ffi_typedef.dart';

final class VideoExporterDarwinApi implements VideoExporterApi {
  @override
  double? progress;

  @override
  Stream<double> get progressStream => _progressStreamController.stream;

  final _progressStreamController = StreamController<double>.broadcast();

  static final _onCompletionCallbackPtr =
      NativeCallable<VoidCallbackFFI>.listener(
    _onCompletionCallback,
  );

  static final _onProgressCallbackPtr =
      NativeCallable<FloatValueCallbackFFI>.listener(
    _onProgressCallback,
  );

  @override
  void export({
    required int id,
    required String input,
    required String output,
    required String? filter,
    required double contrast,
    required double saturation,
    required double exposure,
    required double temperature,
    required double tint,
  }) {
    _completionControllerRegister[id] = () {
      _progressStreamController.close();
    };

    _progressStreamControllerRegister[id] = (value) {
      _progressStreamController.add(value);
      progress = value;
    };

    DarwinFFI.exportVideo(
      id,
      input.toNativeUtf8(),
      output.toNativeUtf8(),
      filter?.toNativeUtf8() ?? nullptr,
      contrast,
      saturation,
      exposure,
      temperature,
      tint,
      _onProgressCallbackPtr.nativeFunction,
      _onCompletionCallbackPtr.nativeFunction,
    );
  }
}

final _completionControllerRegister = <int, VoidCallback>{};
final _progressStreamControllerRegister = <int, ValueChanged<double>>{};

void _onProgressCallback(int viewId, double progress) {
  _progressStreamControllerRegister[viewId]?.call(progress);
}

void _onCompletionCallback(int viewId) {
  _completionControllerRegister[viewId]?.call();
}
