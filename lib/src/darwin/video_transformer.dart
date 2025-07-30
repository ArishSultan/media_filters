import 'dart:ui';

import '../const.dart';
import '../video/video_transformer.dart';

final class VideoTransformerDarwin implements VideoTransformer {
  @override
  Stream<double> export({
    required String srcPath,
    required String dstPath,
    Size? size,
    bool preserveAspectRatio = true,
    String? lutFile,
    double tint = kDefaultTint,
    double exposure = kDefaultExposure,
    double contrast = kDefaultContrast,
    double saturation = kDefaultSaturation,
    double temperature = kDefaultTemperature,
  }) {
    // TODO: implement export
    throw UnimplementedError();
  }
}
