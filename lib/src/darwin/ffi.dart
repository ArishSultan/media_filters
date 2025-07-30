import 'dart:ffi';

import 'package:ffi/ffi.dart';

final class CGSize extends Struct {
  @Double()
  external double width;

  @Double()
  external double height;
}

typedef CString = Pointer<Utf8>;

typedef PtrFn<T extends Function> = Pointer<NativeFunction<T>>;
typedef PtrErrorFn = PtrFn<FFI$ValueCallback<CString>>;
typedef PtrValueFn<T extends SizedNativeType> = PtrFn<FFI$ValueCallback<T>>;

typedef VoidCallback = void Function(int);
typedef ValueCallback<T> = void Function(int, T);

typedef FFI$VoidCallback = Void Function(Int);
typedef FFI$ValueCallback<T extends SizedNativeType> = Void Function(Int, T);

typedef ValueGetter<T> = T Function(int);
typedef ValueSetter<T> = void Function(int, T);

typedef FFI$ValueGetter<T extends SizedNativeType> = T Function(Int);
typedef FFI$ValueSetter<T extends SizedNativeType> = Void Function(Int, T);

typedef VpSizeProp = Pointer<CGSize> Function(int);
typedef VpSeek = void Function(int, int);
typedef VpLoad = void Function(
  int,
  int,
  CString,
  PtrFn<FFI$VoidCallback>,
  PtrValueFn<CString>,
);
typedef VpTrigger = void Function(int);
typedef VpPrepare = void Function(int, PtrValueFn<Int>, PtrValueFn<Long>);

typedef FFI$VpSeek = Void Function(Int, Long);
typedef FFI$VpLoad = Void Function(
  Int,
  Int,
  CString,
  PtrFn<FFI$VoidCallback>,
  PtrValueFn<CString>,
);
typedef FFI$VpTrigger = Void Function(Int);
typedef FFI$VpPrepare = Void Function(Int, PtrValueFn<Int>, PtrValueFn<Long>);

typedef VideoTransform = void Function(
  int,
  double width,
  double height,
  bool preserveAspectRatio,
  double tint,
  double contrast,
  double exposure,
  double saturation,
  double temperature,
  CString lutFile,
  CString srcPath,
  CString dstPath,
  PtrValueFn<Float>,
  PtrFn<FFI$VoidCallback>,
  PtrErrorFn,
);

typedef FFI$VideoTransform = Void Function(
  Int,
  Float width,
  Float height,
  Bool preserveAspectRatio,
  Float tint,
  Float contrast,
  Float exposure,
  Float saturation,
  Float temperature,
  CString lutFile,
  CString srcPath,
  CString dstPath,
  PtrValueFn<Float>,
  PtrFn<FFI$VoidCallback>,
  PtrErrorFn,
);

final class DarwinFFI {
  DarwinFFI._(DynamicLibrary lib)
      : vpSeek = lib.lookupFunction<FFI$VpSeek, VpSeek>('vpSeek'),
        vpLoad = lib.lookupFunction<FFI$VpLoad, VpLoad>('vpLoad'),
        vpPlay = lib.lookupFunction<FFI$VpTrigger, VpTrigger>('vpPlay'),
        vpPause = lib.lookupFunction<FFI$VpTrigger, VpTrigger>('vpPause'),
        vpPrepare = lib.lookupFunction<FFI$VpPrepare, VpPrepare>('vpPrepare'),
        vpRelease = lib.lookupFunction<FFI$VpTrigger, VpTrigger>('vpRelease'),
        vpGetSize = lib.lookupFunction<FFI$ValueGetter<Pointer<CGSize>>,
            ValueGetter<Pointer<CGSize>>>(
          'vpSize',
        ),
        vpGetState = lib.lookupFunction<FFI$ValueGetter<Int>, ValueGetter<int>>(
          'vpState',
        ),
        vpGetDuration =
            lib.lookupFunction<FFI$ValueGetter<Int>, ValueGetter<int>>(
          'vpDuration',
        ),
        vpGetProgress =
            lib.lookupFunction<FFI$ValueGetter<Int>, ValueGetter<int>>(
          'vpProgress',
        ),
        vpSetLutFilter =
            lib.lookupFunction<FFI$ValueSetter<CString>, ValueSetter<CString>>(
          'vpSetLutFilter',
        ),
        vpRemoveLutFilter = lib.lookupFunction<FFI$VpTrigger, VpTrigger>(
          'vpRemoveLutFilter',
        ),
        vpApplyFilter = lib.lookupFunction<FFI$VpTrigger, VpTrigger>(
          'vpApplyFilter',
        ),
        vpSetTintFilter =
            lib.lookupFunction<FFI$ValueSetter<Float>, ValueSetter<double>>(
          'vpSetTintFilter',
        ),
        vpSetExposureFilter =
            lib.lookupFunction<FFI$ValueSetter<Float>, ValueSetter<double>>(
          'vpSetExposureFilter',
        ),
        vpSetContrastFilter =
            lib.lookupFunction<FFI$ValueSetter<Float>, ValueSetter<double>>(
          'vpSetContrastFilter',
        ),
        vpSetSaturationFilter =
            lib.lookupFunction<FFI$ValueSetter<Float>, ValueSetter<double>>(
          'vpSetSaturationFilter',
        ),
        vpSetTemperatureFilter =
            lib.lookupFunction<FFI$ValueSetter<Float>, ValueSetter<double>>(
          'vpSetTemperatureFilter',
        ),
        transformVideo = lib.lookupFunction<FFI$VideoTransform, VideoTransform>(
          'transformVideo',
        );

  final VpSeek vpSeek;
  final VpLoad vpLoad;
  final VpTrigger vpPlay;
  final VpTrigger vpPause;

  final VpPrepare vpPrepare;
  final VpTrigger vpRelease;

  final ValueGetter<int> vpGetState;
  final ValueGetter<int> vpGetDuration;
  final ValueGetter<int> vpGetProgress;
  final ValueGetter<Pointer<CGSize>> vpGetSize;

  final VpTrigger vpApplyFilter;
  final VpTrigger vpRemoveLutFilter;
  final ValueSetter<CString> vpSetLutFilter;
  final ValueSetter<double> vpSetTintFilter;
  final ValueSetter<double> vpSetExposureFilter;
  final ValueSetter<double> vpSetContrastFilter;
  final ValueSetter<double> vpSetSaturationFilter;
  final ValueSetter<double> vpSetTemperatureFilter;

  final VideoTransform transformVideo;
}

final darwinFFI = DarwinFFI._(DynamicLibrary.process());
