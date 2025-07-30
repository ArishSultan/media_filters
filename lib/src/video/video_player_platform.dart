import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../darwin/video_player.dart';

///
enum VideoResourceType { asset, file, network }

///
enum VideoPlayerState {
  ///
  idle,

  ///
  loading,

  ///
  ready,

  ///
  playing,

  ///
  paused,

  ///
  stopped,

  ///
  completed,

  ///
  error
}

///
abstract interface class VideoPlayerPlatform {
  static VideoPlayerPlatform get instance => switch (defaultTargetPlatform) {
        TargetPlatform.android => throw UnimplementedError(),
        TargetPlatform.iOS ||
        TargetPlatform.macOS =>
          VideoPlayerDarwin.instance,
        _ => throw UnimplementedError(),
      };

  static int _nextPlayerId = -1;

  static int get nextPlayerId => ++_nextPlayerId;

  ///
  const VideoPlayerPlatform();

  ///
  Stream<VideoPlayerState> getStateStream(int id);

  ///
  Stream<Duration> getProgressStream(int id);

  ///
  Size readSize(int id);

  ///
  VideoPlayerState readState(int id);

  ///
  Duration readProgress(int id);

  ///
  Duration readDuration(int id);

  ///
  void prepare(int id);

  ///
  void release(int id);

  ///
  Future<void> load(int id, VideoResourceType type, String locator);

  ///
  void seek(int id, int position);

  ///
  void play(int id);

  ///
  void pause(int id);

  void setTintFilter(int id, double value);

  void setExposureFilter(int id, double value);

  void setContrastFilter(int id, double value);

  void setSaturationFilter(int id, double value);

  void setTemperatureFilter(int id, double value);

  void setLutFilter(int id, String lutFilePath);

  void removeLutFilter(int id);

  void applyFilter(int id);
}
