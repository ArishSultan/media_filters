import 'dart:ffi';

import 'package:ffi/ffi.dart';

typedef VPCreate = int Function();
typedef VPCreateFFI = Int Function();

typedef VPDestroy = void Function(int);
typedef VPDestroyFFI = Void Function(Int);

typedef VPTrigger = void Function(int);
typedef VPTriggerFFI = Void Function(Int);

typedef VPSeek = void Function(int, int);
typedef VPSeekFFI = Void Function(Int, Int64);

typedef VPLoadResourceStr = int Function(int, Pointer<Utf8>);
typedef VPLoadResourceStrFFI = Int Function(Int, Pointer<Utf8>);

typedef VPStateCallbackFFI = Void Function(Int, Int);
typedef VPProgressCallbackFFI = Void Function(Int, Double);
typedef VPDurationCallbackFFI = Void Function(Int, Double);
typedef VPSetStateCallbacks = int Function(
  int,
  Pointer<NativeFunction<VPStateCallbackFFI>>,
  Pointer<NativeFunction<VPProgressCallbackFFI>>,
  Pointer<NativeFunction<VPDurationCallbackFFI>>,
);

typedef VPSetStateCallbacksFFI = Int Function(
  Int,
  Pointer<NativeFunction<VPStateCallbackFFI>>,
  Pointer<NativeFunction<VPProgressCallbackFFI>>,
  Pointer<NativeFunction<VPDurationCallbackFFI>>,
);

typedef VPRemoveStateCallbacks = int Function(int);
typedef VPRemoveStateCallbacksFFI = Int Function(Int);

typedef VPExportCompleteCallbackFFI = Void Function(Int, Pointer<Utf8>, Int);
typedef VPExportVideo = int Function(
  int,
  Pointer<Utf8>,
  Pointer<Utf8>,
  Pointer<Utf8>,
  int,
  int,
  int,
  int,
  Pointer<NativeFunction<VPExportCompleteCallbackFFI>>,
);
typedef VPExportVideoFFI = Int Function(
  Int,
  Pointer<Utf8>,
  Pointer<Utf8>,
  Pointer<Utf8>,
  Int,
  Int,
  Int,
  Int,
  Pointer<NativeFunction<VPExportCompleteCallbackFFI>>,
);

// typedef VPSetStateCallback = void Function(
//   int,
//   Pointer<NativeFunction<_VPStateCallbackFFI>>,
// );
//
// typedef VPSetStateCallbackFFI = Void Function(
//   Int,
//   Pointer<NativeFunction<_VPStateCallbackFFI>>,
// );
//
// // /// Video preview state callback
// // /// - Parameters:
// // ///   - previewId: Preview ID
// // ///   - state: State value (0=stopped, 1=playing, 2=paused, 3=ended, 4=error)
// // ///   - currentTime: Current playback time in seconds
// // ///   - duration: Total duration in seconds
//
// //
// // /// Video preview progress callback
// // /// - Parameters:
// // ///   - previewId: Preview ID
// // ///   - progress: Progress value (0.0 to 1.0)
// // typedef VideoPreviewProgressCallbackNative = Void Function(Int, Double);
// // typedef VideoPreviewProgressCallbackDart = void Function(int, double);
// //
// // /// Video preview frame callback
// // /// - Parameters:
// // ///   - previewId: Preview ID
// // ///   - pixelBuffer: Processed pixel buffer (can be null)
// // ///   - width: Frame width
// // ///   - height: Frame height
// // typedef VideoPreviewFrameCallbackNative = Void Function(
// //     Int, Pointer<Void>, Int, Int);
// // typedef VideoPreviewFrameCallbackDart = void Function(
// //     int, Pointer<Void>, int, int);
// //
// // // MARK: - FFI Function Signatures
// //
// // typedef CreateVideoPreviewNative = Int Function();
// // typedef CreateVideoPreviewDart = int Function();
// //
//
// //
// // typedef DestroyAllVideoPreviewsNative = Void Function();
// // typedef DestroyAllVideoPreviewsDart = void Function();
// //
// //
// // typedef SetProgressCallbackNative = Void Function(
// //     Int, Pointer<NativeFunction<VideoPreviewProgressCallbackNative>>);
// // typedef SetProgressCallbackDart = void Function(
// //     int, Pointer<NativeFunction<VideoPreviewProgressCallbackNative>>);
// //
// // typedef SetFrameCallbackNative = Void Function(
// //     Int, Pointer<NativeFunction<VideoPreviewFrameCallbackNative>>);
// // typedef SetFrameCallbackDart = void Function(
// //     int, Pointer<NativeFunction<VideoPreviewFrameCallbackNative>>);
// //
//
// //
// // typedef LoadLutFromDataNative = Int Function(Int, Pointer<Uint8>, Int32);
// // typedef LoadLutFromDataDart = int Function(int, Pointer<Uint8>, int);
// //
//
// // typedef SetVolumeNative = Void Function(Int, Float);
// // typedef SetVolumeDart = void Function(int, double);
