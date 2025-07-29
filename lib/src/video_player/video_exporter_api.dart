import 'package:media_filters/src/platform/ui_kit/video_export_api.dart';

///
abstract class VideoExporterApi {
  factory VideoExporterApi() {
    return VideoExporterDarwinApi();
  }

  ///
  Stream<double> get progressStream;

  ///
  double? get progress;

  ///
  void export({
    required int id,
    required String input,
    required String output,
    required String? filter,
    required double contrast,
    required double saturation,
    required double exposure,
    required double temperature,
    required double tint,
  });
}
