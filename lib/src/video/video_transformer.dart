import 'dart:ui';

import '../const.dart';

///
abstract interface class VideoTransformer {
  ///
  Stream<double> export({
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
