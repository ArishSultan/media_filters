// import 'dart:async';
// import 'dart:ffi';
//
// import 'package:ffi/ffi.dart';
// import 'package:flutter/cupertino.dart';
//
// import 'ffi.dart';
// import 'ffi_typedef.dart';
//
// import '../../video_player/video_player_api.dart';
// import '../../video_player/video_player_state.dart';
//
// final class VideoPlayerDarwinApi extends VideoPlayerPlatformApi {
//   VideoPlayerDarwinApi() {
//     DarwinFFI.initialize();
//   }
//
//   @override
//   Stream<VideoPlayerState> get stateStream => _stateStreamController.stream;
//
//   @override
//   VideoPlayerState? state;
//
//   @override
//   Stream<Duration> get progressStream => _progressStreamController.stream;
//
//   @override
//   Duration? progress;
//
//   @override
//   Stream<Duration> get durationStream => _durationStreamController.stream;
//
//   @override
//   Duration? duration;
//
//   @override
//   Stream<double> get aspectRatioStream => _aspectRatioStreamController.stream;
//
//   @override
//   double? aspectRatio;
//
//   @override
//   void create(int viewId) {
//     _stateStreamControllerRegister[viewId] = (value) {
//       _stateStreamController.add(value);
//       state = value;
//     };
//     _durationStreamControllerRegister[viewId] = (value) {
//       _durationStreamController.add(value);
//       duration = value;
//     };
//     _progressStreamControllerRegister[viewId] = (value) {
//       _progressStreamController.add(value);
//       progress = value;
//     };
//     _aspectRatioStreamControllerRegister[viewId] = (value) {
//       _aspectRatioStreamController.add(value);
//       aspectRatio = value;
//     };
//
//     DarwinFFI.vpCreate(
//       viewId,
//       _onStateCallbackPtr.nativeFunction,
//       _onDurationCallbackPtr.nativeFunction,
//       _onProgressCallbackPtr.nativeFunction,
//       _onAspectRatioCallbackPtr.nativeFunction,
//     );
//   }
//
//   @override
//   void remove(int viewId) {
//     DarwinFFI.vpRemove(viewId);
//   }
//
//   @override
//   void pause(int viewId) {
//     DarwinFFI.vpPause(viewId);
//   }
//
//   @override
//   void play(int viewId) {
//     DarwinFFI.vpPlay(viewId);
//   }
//
//   @override
//   void seekTo(int viewId, int value) {
//     DarwinFFI.vpSeek(viewId, value);
//   }
//
//   @override
//   void loadFilterFile(int viewId, String filePath) {
//     final filePathPtr = filePath.toNativeUtf8();
//     DarwinFFI.vpLoadLutFilter(viewId, filePathPtr);
//     malloc.free(filePathPtr);
//   }
//
//   @override
//   void removeFilterFile(int viewId) {
//     DarwinFFI.vpRemoveLutFilter(viewId);
//   }
//
//   @override
//   void loadAssetVideo(int viewId, String locator) {
//     _loadVideo(viewId, locator, 1);
//   }
//
//   @override
//   void loadFileVideo(int viewId, String path) {
//     _loadVideo(viewId, path, 2);
//   }
//
//   @override
//   void loadNetworkVideo(int viewId, String url) {
//     _loadVideo(viewId, url, 3);
//   }
//
//   void _loadVideo(int viewId, String locator, int type) {
//     final locatorPtr = locator.toNativeUtf8();
//     DarwinFFI.vpLoadVideo(viewId, type, locatorPtr);
//     malloc.free(locatorPtr);
//   }
//
//   final _stateStreamController = StreamController<VideoPlayerState>.broadcast();
//   final _progressStreamController = StreamController<Duration>.broadcast();
//   final _durationStreamController = StreamController<Duration>.broadcast();
//   final _aspectRatioStreamController = StreamController<double>.broadcast();
//
//   ///
//   @override
//   void setExposure(int viewId, double exposure) {
//     DarwinFFI.vpSetExposure(viewId, exposure);
//   }
//
//   ///
//   @override
//   void setContrast(int viewId, double contrast) {
//     DarwinFFI.vpSetContrast(viewId, contrast);
//   }
//
//   ///
//   @override
//   void setSaturation(int viewId, double saturation) {
//     DarwinFFI.vpSetSaturation(viewId, saturation);
//   }
//
//   ///
//   @override
//   void setTemperature(int viewId, double temperature) {
//     DarwinFFI.vpSetTemperature(viewId, temperature);
//   }
//
//   ///
//   @override
//   void setTint(int viewId, double tint) {
//     DarwinFFI.vpSetTint(viewId, tint);
//   }
//
//   @override
//   Future<String> exportVideo({
//     required int viewId,
//     required String videoPath,
//     String? filterPath,
//     required String outputPath,
//     required int outputWidth,
//     required int outputHeight,
//     required bool maintainAspectRatio,
//   }) async {
//     // final videoPathPtr = videoPath.toNativeUtf8();
//     // final filterPathPtr = filterPath?.toNativeUtf8();
//     // final outputPathPtr = outputPath.toNativeUtf8();
//
//     // Create a completer to handle the async result
//     // final completer = Completer<String>();
//     // final exportId = DateTime.now().millisecondsSinceEpoch;
//     // _exportCompleters[exportId] = completer;
//
//     // try {
//     //   final result = DarwinFFI.vpExportVideo(
//     //     viewId,
//     //     videoPathPtr,
//     //     filterPathPtr ?? nullptr,
//     //     outputPathPtr,
//     //     outputWidth,
//     //     outputHeight,
//     //     maintainAspectRatio ? 1 : 0,
//     //     exportId,
//     //     _onExportCompletePtr.nativeFunction,
//     //   );
//     //
//     //   if (result != 0) {
//     //     _exportCompleters.remove(exportId);
//     //     throw Exception('Failed to start video export: error code $result');
//     //   }
//     //
//     //   return await completer.future;
//     // } finally {
//     //   malloc.free(videoPathPtr);
//     //   if (filterPathPtr != null) malloc.free(filterPathPtr);
//     //   malloc.free(outputPathPtr);
//     // }
//
//     return "";
//   }
//
//   static final _onStateCallbackPtr =
//       NativeCallable<IntegerValueCallbackFFI>.listener(
//     _onStateCallback,
//   );
//
//   static final _onProgressCallbackPtr =
//       NativeCallable<LongValueCallbackFFI>.listener(
//     _onProgressCallback,
//   );
//
//   static final _onDurationCallbackPtr =
//       NativeCallable<LongValueCallbackFFI>.listener(
//     _onDurationCallback,
//   );
//
//   static final _onAspectRatioCallbackPtr =
//       NativeCallable<DoubleValueCallbackFFI>.listener(
//     _onAspectRatioCallback,
//   );
//
// // static final _onExportCompletePtr =
// //     NativeCallable<VPExportCompleteCallbackFFI>.listener(
// //   _onExportComplete,
// // );
// }
//
// // final _exportCompleters = <int, Completer<String>>{};
// //
// // void _onExportComplete(int exportId, Pointer<Utf8> outputPath, int errorCode) {
// //   final completer = _exportCompleters.remove(exportId);
// //   if (completer != null) {
// //     if (errorCode == 0) {
// //       completer.complete(outputPath.toDartString());
// //     } else {
// //       completer.completeError(
// //           Exception('Export failed with error code: $errorCode'));
// //     }
// //   }
// // }
//
// final _durationStreamControllerRegister = <int, ValueChanged<Duration>>{};
// final _progressStreamControllerRegister = <int, ValueChanged<Duration>>{};
// final _aspectRatioStreamControllerRegister = <int, ValueChanged<double>>{};
// final _stateStreamControllerRegister = <int, ValueChanged<VideoPlayerState>>{};
//
// void _onStateCallback(int viewId, int state) {
//   _stateStreamControllerRegister[viewId]?.call(
//     switch (state) {
//       0 => VideoPlayerState.idle,
//       1 => VideoPlayerState.loading,
//       2 => VideoPlayerState.ready,
//       3 => VideoPlayerState.playing,
//       4 => VideoPlayerState.paused,
//       5 => VideoPlayerState.stopped,
//       6 => VideoPlayerState.completed,
//       7 => VideoPlayerState.error,
//       _ => throw UnimplementedError(),
//     },
//   );
// }
//
// void _onProgressCallback(int viewId, int progress) {
//   _progressStreamControllerRegister[viewId]?.call(
//     Duration(milliseconds: progress),
//   );
// }
//
// void _onDurationCallback(int viewId, int duration) {
//   print(duration);
//   _durationStreamControllerRegister[viewId]?.call(
//     Duration(milliseconds: duration),
//   );
// }
//
// void _onAspectRatioCallback(int viewId, double aspectRatio) {
//   _aspectRatioStreamControllerRegister[viewId]?.call(aspectRatio);
// }
