import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import 'video_player_platform.dart';

///
final class VideoPlayerController {
  ///
  static final Finalizer<(VideoPlayerPlatform, int)> _finalizer =
      Finalizer((value) => value.$1.release(value.$2));

  ///
  const VideoPlayerController._(this._playerId, this._api);

  ///
  factory VideoPlayerController() {
    final playerId = VideoPlayerPlatform.nextPlayerId;

    final object = VideoPlayerController._(
      playerId,
      VideoPlayerPlatform.instance..prepare(playerId),
    );

    _finalizer.attach(object, (object._api, playerId), detach: object);

    return object;
  }

  ///
  final int _playerId;

  ///
  final VideoPlayerPlatform _api;

  ///
  Stream<Duration> get progressStream => _api.getProgressStream(_playerId);

  ///
  Stream<VideoPlayerState> get stateStream => _api.getStateStream(_playerId);

  ///
  Size get size => _api.readSize(_playerId);

  ///
  VideoPlayerState get state => _api.readState(_playerId);

  ///
  Duration get progress => _api.readProgress(_playerId);

  ///
  Duration get duration => _api.readDuration(_playerId);

  ///
  Future<void> loadFile(File file) {
    return _api.load(_playerId, VideoResourceType.file, file.path);
  }

  ///
  void seek(int position) => _api.seek(_playerId, position);

  ///
  void play() => _api.play(_playerId);

  ///
  void pause() => _api.pause(_playerId);

  ///
  void setFilters({
    double? tint,
    double? contrast,
    double? exposure,
    double? saturation,
    double? temperature,
  }) {
    if (tint != null) {
      _api.setTintFilter(_playerId, tint);
    }

    if (contrast != null) {
      _api.setContrastFilter(_playerId, contrast);
    }

    if (exposure != null) {
      _api.setExposureFilter(_playerId, exposure);
    }

    if (saturation != null) {
      _api.setSaturationFilter(_playerId, saturation);
    }

    if (temperature != null) {
      _api.setTemperatureFilter(_playerId, temperature);
    }
  }

  ///
  void applyFilters() => _api.applyFilter(_playerId);

  ///
  void setAndApplyFilters({
    double? tint,
    double? contrast,
    double? exposure,
    double? saturation,
    double? temperature,
  }) {
    setFilters(
      tint: tint,
      contrast: contrast,
      exposure: exposure,
      saturation: saturation,
      temperature: temperature,
    );

    applyFilters();
  }

  ///
  void setLutFilter(String lutFilePath) =>
      _api.setLutFilter(_playerId, lutFilePath);

  ///
  void removeLutFilter() => _api.removeLutFilter(_playerId);

  ///
  void dispose() => _api.release(_playerId);
}

///
class VideoPlayer extends StatelessWidget {
  ///
  const VideoPlayer({super.key, required this.controller});

  ///
  final VideoPlayerController controller;

  ///
  @override
  Widget build(BuildContext context) {
    const kViewType = 'media_filters.preview';

    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => UiKitView(
          viewType: kViewType,
          creationParams: controller._playerId,
          creationParamsCodec: const StandardMessageCodec(),
        ),
      TargetPlatform.android => AndroidView(
          viewType: kViewType,
          creationParams: controller._playerId,
          creationParamsCodec: const StandardMessageCodec(),
        ),
      _ => throw UnimplementedError(),
    };
  }
}
