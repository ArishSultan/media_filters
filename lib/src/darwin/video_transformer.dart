import 'dart:async';
import 'dart:ffi' hide Size;
import 'dart:ui';

import 'package:ffi/ffi.dart';

import 'ffi.dart';
import '../const.dart';
import '../video/video_transformer.dart';

final class VideoTransformerDarwin implements VideoTransformer {
  static const instance = VideoTransformerDarwin._();

  const VideoTransformerDarwin._();

  @override
  Stream<double> transform({
    required String srcPath,
    required String dstPath,
    Size? size,
    bool preserveAspectRatio = true,
    String? lutFile,
    double tint = kDefaultTint,
    double contrast = kDefaultContrast,
    double exposure = kDefaultExposure,
    double saturation = kDefaultSaturation,
    double temperature = kDefaultTemperature,
  }) {
    final id = ++_nextOpId;
    final streamController = StreamController<double>();

    _streamControllerRegister[id] = streamController;

    final srcPathPtr = srcPath.toNativeUtf8();
    final dstPathPtr = dstPath.toNativeUtf8();
    final lutPathPtr = lutFile?.toNativeUtf8() ?? nullptr;

    darwinFFI.transformVideo(
      id,
      size?.width ?? -1,
      size?.height ?? -1,
      preserveAspectRatio,
      tint,
      contrast,
      exposure,
      saturation,
      temperature,
      lutPathPtr,
      srcPathPtr,
      dstPathPtr,
      _onTransformProgress$Native.nativeFunction,
      _onTransformComplete$Native.nativeFunction,
      _onTransformError$Native.nativeFunction,
    );

    malloc.free(srcPathPtr);
    malloc.free(dstPathPtr);

    if (lutPathPtr != nullptr) {
      malloc.free(lutPathPtr);
    }

    return streamController.stream;
  }

  static int _nextOpId = -1;
}

final _streamControllerRegister = <int, StreamController<double>>{};
final _onTransformProgress$Native =
    NativeCallable<FFI$ValueCallback<Float>>.listener(
  (int id, double progress) => _streamControllerRegister[id]?.add(progress),
);

final _onTransformComplete$Native = NativeCallable<FFI$VoidCallback>.listener(
  (int id) => _streamControllerRegister.remove(id)
    ?..add(1.0)
    ..close(),
);
final _onTransformError$Native =
    NativeCallable<FFI$ValueCallback<CString>>.listener(
  (int id, CString error) {
    _streamControllerRegister.remove(id)?.addError(error.toDartString());
    malloc.free(error);
  },
);
