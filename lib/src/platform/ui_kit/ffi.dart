import 'dart:ffi';
import 'package:ffi/ffi.dart';

import '../../widgets/video_preview.dart';

part 'ffi_typedef.dart';

final _controllerRegistry = <int, UiKitVideoPreviewController>{};

class UiKitVideoPreviewController extends VideoPreviewController {
  UiKitVideoPreviewController() {
    _loadNativeFunctions();
  }

  /// The iOS ffi library will already be loaded in the process, no need to
  /// manually link to it, unlike android or any other 3rd party ffi library.
  final _lib = DynamicLibrary.process();

  @override
  void setup() {
    if (_viewId != null) {
      return;
    }

    _viewId = _vpCreate();
    _controllerRegistry[_viewId!] = this;

    // Set the callback
    // _vpSetStateCallback(0, );
  }

  int get viewId => _viewId!;

  @override
  void play() => _vpPlay(_viewId!);

  @override
  void pause() => _vpPause(_viewId!);

  @override
  void seekTo(double value) => _vpSeek(_viewId!, value);

  @override
  void loadVideo(String path) {
    final videoPathNative = path.toNativeUtf8();

    try {
      _vpLoadVideo(_viewId!, videoPathNative);
    } finally {
      malloc.free(videoPathNative);
    }
  }

  @override
  void loadFilter(String path) {
    final videoPathNative = path.toNativeUtf8();

    try {
      _vpLoadLutPath(_viewId!, videoPathNative);
    } finally {
      malloc.free(videoPathNative);
    }
  }

  @override
  void dispose() {
    _vpDestroy(_viewId!);
    _controllerRegistry.remove(_viewId!);

    super.dispose();
  }

  @override
  VideoPreviewState get state => throw UnimplementedError();

  int? _viewId;

  late final _VPPlay _vpPlay;
  late final _VPSeek _vpSeek;
  late final _VPPause _vpPause;

  late final _VPCreate _vpCreate;
  late final _VPDestroy _vpDestroy;

  late final _VPLoadVideo _vpLoadVideo;
  late final _VPLoadLutFromPath _vpLoadLutPath;

  late final _VPSetStateCallback _vpSetStateCallback;

  // late final SetVolumeDart _setVolume;
  // late final LoadLutFromPathDart _loadLutFromPath;
  // late final LoadLutFromDataDart _loadLutFromData;
  // late final SeekVideoPreviewDart _seekVideoPreview;
  // late final SetStateCallbackDart _setStateCallback;
  // late final SetFrameCallbackDart _setFrameCallback;
  // late final SetProgressCallbackDart _setProgressCallback;

  void _loadNativeFunctions() {
    _vpCreate = _lib
        .lookup<NativeFunction<_VPCreateFFI>>('vp_create')
        .asFunction<_VPCreate>();

    _vpDestroy = _lib
        .lookup<NativeFunction<_VPDestroyFFI>>('vp_destroy')
        .asFunction<_VPDestroy>();

    _vpPlay = _lib
        .lookup<NativeFunction<_VPPlayFFI>>('vp_play')
        .asFunction<_VPPlay>();

    // _vpSeek = _lib
    //     .lookup<NativeFunction<_VPSeekFFI>>('vp_seek')
    //     .asFunction<_VPSeek>();
    //
    _vpPause = _lib
        .lookup<NativeFunction<_VPPauseFFI>>('vp_pause')
        .asFunction<_VPPause>();

    _vpLoadVideo = _lib
        .lookup<NativeFunction<_VPLoadVideoFFI>>('vp_load_video')
        .asFunction<_VPLoadVideo>();

    _vpLoadLutPath = _lib
        .lookup<NativeFunction<_VPLoadLutFromPathFFI>>('vp_load_lut_path')
        .asFunction<_VPLoadLutFromPath>();

    // _vpSetStateCallback = _lib
    //     .lookup<NativeFunction<_VPSetStateCallbackFFI>>('vp_state_callback')
    //     .asFunction<_VPSetStateCallback>();

    // _destroyAllVideoPreviews = _lib
    //     .lookup<NativeFunction<DestroyAllVideoPreviewsNative>>(
    //         'destroy_all_video_previews')
    //     .asFunction<DestroyAllVideoPreviewsDart>();

    //
    // _setProgressCallback = _lib
    //     .lookup<NativeFunction<SetProgressCallbackNative>>(
    //         'set_video_preview_progress_callback')
    //     .asFunction<SetProgressCallbackDart>();
    //
    // _setFrameCallback = _lib
    //     .lookup<NativeFunction<SetFrameCallbackNative>>(
    //         'set_video_preview_frame_callback')
    //     .asFunction<SetFrameCallbackDart>();
    //
    // _loadLutFromPath = _lib
    //     .lookup<NativeFunction<LoadLutFromPathNative>>(
    //         'load_lut_for_preview_from_path')
    //     .asFunction<LoadLutFromPathDart>();
    //
    // _loadLutFromData = _lib
    //     .lookup<NativeFunction<LoadLutFromDataNative>>(
    //         'load_lut_for_preview_from_data')
    //     .asFunction<LoadLutFromDataDart>();
    //
    // _setVolume = _lib
    //     .lookup<NativeFunction<SetVolumeNative>>('set_video_preview_volume')
    //     .asFunction<SetVolumeDart>();
  }

// static void _onStateCallback(
//     int previewId, int state, double currentTime, double duration) {
//   final callback = _stateCallbacks[previewId];
//   if (callback != null) {
//     final videoState = VideoPreviewState.fromValue(state);
//     callback(videoState, currentTime, duration);
//   }
// }
}

// enum VideoPreviewState {
//   stopped(0),
//   playing(1),
//   paused(2),
//   ended(3),
//   error(4);
//
//   const VideoPreviewState(this.value);
//
//   final int value;
//
//   static VideoPreviewState fromValue(int value) {
//     return VideoPreviewState.values.firstWhere(
//       (state) => state.value == value,
//       orElse: () => VideoPreviewState.error,
//     );
//   }
// }
//
// class VideoPreviewController1 {
//   late final DynamicLibrary _lib;
//
//   // Function pointers
//
//   // Callbacks
//   static final _stateCallbacks =
//       <int, void Function(VideoPreviewState, double, double)>{};
//   static final _progressCallbacks = <int, void Function(double)>{};
//   static final _frameCallbacks =
//       <int, void Function(Pointer<Void>, int, int)>{};
//
//   // Native callbacks
//   static final _nativeStateCallback =
//       NativeCallable<_VPStateCallback>.listener(
//           _onStateCallback);
//   static final _nativeProgressCallback =
//       NativeCallable<VideoPreviewProgressCallbackNative>.listener(
//           _onProgressCallback);
//   static final _nativeFrameCallback =
//       NativeCallable<VideoPreviewFrameCallbackNative>.listener(
//           _onFrameCallback);
//
//   VideoPreviewController() {
//     _lib = _loadLibrary();
//     _initializeFunctions();
//   }
//
//   DynamicLibrary _loadLibrary() {
//     if (Platform.isIOS) {
//       return DynamicLibrary.process();
//     } else if (Platform.isAndroid) {
//       return DynamicLibrary.open('liblutprocessor.so');
//     } else {
//       throw UnsupportedError('Platform not supported');
//     }
//   }
//
//   void _initializeFunctions() {
//     _createVideoPreview = _lib
//         .lookup<NativeFunction<CreateVideoPreviewNative>>(
//             'create_video_preview')
//         .asFunction<CreateVideoPreviewDart>();
//
//     _destroyVideoPreview = _lib
//         .lookup<NativeFunction<DestroyVideoPreviewNative>>(
//             'destroy_video_preview')
//         .asFunction<DestroyVideoPreviewDart>();
//
//     _destroyAllVideoPreviews = _lib
//         .lookup<NativeFunction<DestroyAllVideoPreviewsNative>>(
//             'destroy_all_video_previews')
//         .asFunction<DestroyAllVideoPreviewsDart>();
//
//     _setStateCallback = _lib
//         .lookup<NativeFunction<SetStateCallbackNative>>(
//             'set_video_preview_state_callback')
//         .asFunction<SetStateCallbackDart>();
//
//     _setProgressCallback = _lib
//         .lookup<NativeFunction<SetProgressCallbackNative>>(
//             'set_video_preview_progress_callback')
//         .asFunction<SetProgressCallbackDart>();
//
//     _setFrameCallback = _lib
//         .lookup<NativeFunction<SetFrameCallbackNative>>(
//             'set_video_preview_frame_callback')
//         .asFunction<SetFrameCallbackDart>();
//
//     _loadVideo = _lib
//         .lookup<NativeFunction<LoadVideoNative>>('load_video_for_preview')
//         .asFunction<LoadVideoDart>();
//
//     _loadLutFromPath = _lib
//         .lookup<NativeFunction<LoadLutFromPathNative>>(
//             'load_lut_for_preview_from_path')
//         .asFunction<LoadLutFromPathDart>();
//
//     _loadLutFromData = _lib
//         .lookup<NativeFunction<LoadLutFromDataNative>>(
//             'load_lut_for_preview_from_data')
//         .asFunction<LoadLutFromDataDart>();
//
//     _playVideoPreview = _lib
//         .lookup<NativeFunction<PlayVideoPreviewNative>>('play_video_preview')
//         .asFunction<PlayVideoPreviewDart>();
//
//     _pauseVideoPreview = _lib
//         .lookup<NativeFunction<PauseVideoPreviewNative>>('pause_video_preview')
//         .asFunction<PauseVideoPreviewDart>();
//
//     _seekVideoPreview = _lib
//         .lookup<NativeFunction<SeekVideoPreviewNative>>('seek_video_preview')
//         .asFunction<SeekVideoPreviewDart>();
//
//     _setVolume = _lib
//         .lookup<NativeFunction<SetVolumeNative>>('set_video_preview_volume')
//         .asFunction<SetVolumeDart>();
//   }
//
//   // MARK: - Public API
//
//   /// Create a new video preview instance
//   int createPreview() {
//     return _createVideoPreview();
//   }
//
//   /// Destroy a video preview instance
//   void destroyPreview(int previewId) {
//     _stateCallbacks.remove(previewId);
//     _progressCallbacks.remove(previewId);
//     _frameCallbacks.remove(previewId);
//     _destroyVideoPreview(previewId);
//   }
//
//   /// Destroy all video preview instances
//   void destroyAllPreviews() {
//     _stateCallbacks.clear();
//     _progressCallbacks.clear();
//     _frameCallbacks.clear();
//     _destroyAllVideoPreviews();
//   }
//
//   /// Set state callback for a preview
//   void setStateCallback(
//     int previewId,
//     void Function(VideoPreviewState state, double currentTime, double duration)?
//         callback,
//   ) {
//     if (callback != null) {
//       _stateCallbacks[previewId] = callback;
//       _setStateCallback(previewId, _nativeStateCallback.nativeFunction);
//     } else {
//       _stateCallbacks.remove(previewId);
//       _setStateCallback(previewId, nullptr);
//     }
//   }
//
//   /// Set progress callback for a preview
//   void setProgressCallback(
//     int previewId,
//     void Function(double progress)? callback,
//   ) {
//     if (callback != null) {
//       _progressCallbacks[previewId] = callback;
//       _setProgressCallback(previewId, _nativeProgressCallback.nativeFunction);
//     } else {
//       _progressCallbacks.remove(previewId);
//       _setProgressCallback(previewId, nullptr);
//     }
//   }
//
//   /// Set frame callback for a preview
//   void setFrameCallback(
//     int previewId,
//     void Function(Pointer<Void> pixelBuffer, int width, int height)? callback,
//   ) {
//     if (callback != null) {
//       _frameCallbacks[previewId] = callback;
//       _setFrameCallback(previewId, _nativeFrameCallback.nativeFunction);
//     } else {
//       _frameCallbacks.remove(previewId);
//       _setFrameCallback(previewId, nullptr);
//     }
//   }
//
//   /// Load video for preview
//   bool loadVideo(int previewId, String videoPath) {
//     final videoPathNative = videoPath.toNativeUtf8();
//     try {
//       return _loadVideo(previewId, videoPathNative) == 1;
//     } finally {
//       malloc.free(videoPathNative);
//     }
//   }
//
//   /// Load LUT from path for preview
//   bool loadLutFromPath(int previewId, String lutPath) {
//     final lutPathNative = lutPath.toNativeUtf8();
//     try {
//       return _loadLutFromPath(previewId, lutPathNative) == 1;
//     } finally {
//       malloc.free(lutPathNative);
//     }
//   }
//
//   /// Load LUT from data for preview
//   bool loadLutFromData(int previewId, Uint8List lutData) {
//     final lutDataNative = malloc<Uint8>(lutData.length);
//     try {
//       lutDataNative.asTypedList(lutData.length).setAll(0, lutData);
//       return _loadLutFromData(previewId, lutDataNative, lutData.length) == 1;
//     } finally {
//       malloc.free(lutDataNative);
//     }
//   }
//
//   /// Play video preview
//   void play(int previewId) {
//     _playVideoPreview(previewId);
//   }
//
//   /// Pause video preview
//   void pause(int previewId) {
//     _pauseVideoPreview(previewId);
//   }
//
//   /// Seek video preview to specific time
//   void seek(int previewId, double time) {
//     _seekVideoPreview(previewId, time);
//   }
//
//   /// Set volume for video preview
//   void setVolume(int previewId, double volume) {
//     _setVolume(previewId, volume);
//   }
//
//   static void _onStateCallback(
//       int previewId, int state, double currentTime, double duration) {
//     final callback = _stateCallbacks[previewId];
//     if (callback != null) {
//       final videoState = VideoPreviewState.fromValue(state);
//       callback(videoState, currentTime, duration);
//     }
//   }
//
//   static void _onProgressCallback(int previewId, double progress) {
//     final callback = _progressCallbacks[previewId];
//     if (callback != null) {
//       callback(progress);
//     }
//   }
//
//   static void _onFrameCallback(
//       int previewId, Pointer<Void> pixelBuffer, int width, int height) {
//     final callback = _frameCallbacks[previewId];
//     if (callback != null) {
//       callback(pixelBuffer, width, height);
//     }
//   }
// }
//
// // Global instance
// final videoPreviewController = VideoPreviewController();
