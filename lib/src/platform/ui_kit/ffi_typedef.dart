import 'dart:ffi';

import 'package:ffi/ffi.dart';

typedef VPTrigger = void Function(int);
typedef VPTriggerFFI = Void Function(Int);

typedef VPSeek = void Function(int, int);
typedef VPSeekFFI = Void Function(Int, Int64);

typedef VPFilter = void Function(int, double);
typedef VPFilterFFI = Void Function(Int, Float);

typedef VPLoadLutFilter = int Function(int, Pointer<Utf8>);
typedef VPLoadLutFilterFFI = Int Function(Int, Pointer<Utf8>);

typedef VPLoadVideo = int Function(int, int, Pointer<Utf8>);
typedef VPLoadVideoFFI = Int Function(Int, Int, Pointer<Utf8>);

typedef VoidCallbackFFI = Void Function(Int);
typedef LongValueCallbackFFI = Void Function(Int, Int64);
typedef FloatValueCallbackFFI = Void Function(Int, Float);
typedef DoubleValueCallbackFFI = Void Function(Int, Double);
typedef IntegerValueCallbackFFI = Void Function(Int, Int);

typedef VPCreate = int Function(
  int,
  Pointer<NativeFunction<IntegerValueCallbackFFI>>,
  Pointer<NativeFunction<LongValueCallbackFFI>>,
  Pointer<NativeFunction<LongValueCallbackFFI>>,
  Pointer<NativeFunction<DoubleValueCallbackFFI>>,
);

typedef VPCreateFFI = Int Function(
  Int,
  Pointer<NativeFunction<IntegerValueCallbackFFI>>,
  Pointer<NativeFunction<LongValueCallbackFFI>>,
  Pointer<NativeFunction<LongValueCallbackFFI>>,
  Pointer<NativeFunction<DoubleValueCallbackFFI>>,
);

typedef VPRemoveStateCallbacks = int Function(int);
typedef VPRemoveStateCallbacksFFI = Int Function(Int);

typedef ExportVideo = void Function(
  int,
  Pointer<Utf8>,
  Pointer<Utf8>,
  Pointer<Utf8>,
  double,
  double,
  double,
  double,
  double,
  Pointer<NativeFunction<FloatValueCallbackFFI>>,
  Pointer<NativeFunction<VoidCallbackFFI>>,
);
typedef ExportVideoFFI = Void Function(
  Int,
  Pointer<Utf8>,
  Pointer<Utf8>,
  Pointer<Utf8>,
  Float,
  Float,
  Float,
  Float,
  Float,
  Pointer<NativeFunction<FloatValueCallbackFFI>>,
  Pointer<NativeFunction<VoidCallbackFFI>>,
);
