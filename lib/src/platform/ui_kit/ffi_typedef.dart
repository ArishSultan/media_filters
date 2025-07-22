part of 'ffi.dart';

typedef _VPStateCallback = void Function(int, int, double, double);
typedef _VPStateCallbackFFI = Void Function(Int, Int, Double, Double);

typedef _VPCreate = int Function();
typedef _VPCreateFFI = Int Function();

typedef _VPDestroy = void Function(int);
typedef _VPDestroyFFI = Void Function(Int);

typedef _VPPlay = void Function(int);
typedef _VPPlayFFI = Void Function(Int);

typedef _VPPause = void Function(int);
typedef _VPPauseFFI = Void Function(Int);

typedef _VPSeek = void Function(int, double);
typedef _VPSeekFFI = Void Function(Int, Double);

typedef _VPLoadVideo = int Function(int, Pointer<Utf8>);
typedef _VPLoadVideoFFI = Int Function(Int, Pointer<Utf8>);

typedef _VPLoadLutFromPath = int Function(int, Pointer<Utf8>);
typedef _VPLoadLutFromPathFFI = Int Function(Int, Pointer<Utf8>);

typedef _VPSetStateCallback = void Function(
  int,
  Pointer<NativeFunction<_VPStateCallbackFFI>>,
);

typedef _VPSetStateCallbackFFI = Void Function(
  Int,
  Pointer<NativeFunction<_VPStateCallbackFFI>>,
);

// /// Video preview state callback
// /// - Parameters:
// ///   - previewId: Preview ID
// ///   - state: State value (0=stopped, 1=playing, 2=paused, 3=ended, 4=error)
// ///   - currentTime: Current playback time in seconds
// ///   - duration: Total duration in seconds

//
// /// Video preview progress callback
// /// - Parameters:
// ///   - previewId: Preview ID
// ///   - progress: Progress value (0.0 to 1.0)
// typedef VideoPreviewProgressCallbackNative = Void Function(Int, Double);
// typedef VideoPreviewProgressCallbackDart = void Function(int, double);
//
// /// Video preview frame callback
// /// - Parameters:
// ///   - previewId: Preview ID
// ///   - pixelBuffer: Processed pixel buffer (can be null)
// ///   - width: Frame width
// ///   - height: Frame height
// typedef VideoPreviewFrameCallbackNative = Void Function(
//     Int, Pointer<Void>, Int, Int);
// typedef VideoPreviewFrameCallbackDart = void Function(
//     int, Pointer<Void>, int, int);
//
// // MARK: - FFI Function Signatures
//
// typedef CreateVideoPreviewNative = Int Function();
// typedef CreateVideoPreviewDart = int Function();
//

//
// typedef DestroyAllVideoPreviewsNative = Void Function();
// typedef DestroyAllVideoPreviewsDart = void Function();
//
//
// typedef SetProgressCallbackNative = Void Function(
//     Int, Pointer<NativeFunction<VideoPreviewProgressCallbackNative>>);
// typedef SetProgressCallbackDart = void Function(
//     int, Pointer<NativeFunction<VideoPreviewProgressCallbackNative>>);
//
// typedef SetFrameCallbackNative = Void Function(
//     Int, Pointer<NativeFunction<VideoPreviewFrameCallbackNative>>);
// typedef SetFrameCallbackDart = void Function(
//     int, Pointer<NativeFunction<VideoPreviewFrameCallbackNative>>);
//

//
// typedef LoadLutFromDataNative = Int Function(Int, Pointer<Uint8>, Int32);
// typedef LoadLutFromDataDart = int Function(int, Pointer<Uint8>, int);
//

// typedef SetVolumeNative = Void Function(Int, Float);
// typedef SetVolumeDart = void Function(int, double);
