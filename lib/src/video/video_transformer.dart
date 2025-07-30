import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../const.dart';
import '../darwin/video_transformer.dart';

///
abstract interface class VideoTransformer {
  factory VideoTransformer() {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => throw UnimplementedError(),
      TargetPlatform.iOS ||
      TargetPlatform.macOS =>
        VideoTransformerDarwin.instance,
      _ => throw UnimplementedError(),
    };
  }

  ///
  Stream<double> transform({
    Size? size,
    String? lutFile,
    bool preserveAspectRatio = true,
    double tint = kDefaultTint,
    double exposure = kDefaultExposure,
    double contrast = kDefaultContrast,
    double saturation = kDefaultSaturation,
    double temperature = kDefaultTemperature,
    required String srcPath,
    required String dstPath,
  });
}
