import 'package:media_filters/src/video_preview/video_preview_state.dart';

import '../../video_preview/video_preview_api.dart';

final class VideoPreviewAndroidApi extends VideoPreviewPlatformApi {
  @override
  void pause(int viewId) {
    // TODO: implement pause
  }

  @override
  void play(int viewId) {
    // TODO: implement play
  }

  @override
  void seekTo(int viewId, int value) {
    // TODO: implement seekTo
  }

  @override
  void loadFilterFile(int viewId, String filePath) {
    // TODO: implement loadFilterFile
  }

  @override
  void loadVideoFile(int viewId, String filePath) {
    // TODO: implement loadVideoFile
  }

  @override
  Stream<VideoPreviewState> get state => throw UnimplementedError();

  @override
  void removeStateCallbacks(int viewId) {
    // TODO: implement removeStateCallbacks
  }

  @override
  void setStateCallbacks(int viewId) {
    // TODO: implement setStateCallbacks
  }

  @override
  // TODO: implement duration
  Stream<Duration> get duration => throw UnimplementedError();

  @override
  // TODO: implement progress
  Stream<Duration> get progress => throw UnimplementedError();
}
