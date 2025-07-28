import 'package:flutter/foundation.dart';

///
abstract class ImageEditorApi {
  ///
  Stream<Uint8List> get image;

  ///
  void create(int imageId);

  ///
  void loadAssetImage(int imageId, String locator);

  ///
  void loadFileImage(int imageId, String path);

  ///
  void loadNetworkImage(int imageId, String url);

  ///
  void loadFilterFile(int imageId, String filePath);

  ///
  void removeFilterFile(int imageId);

  ///
  void setImageCallback(int imageId);

  ///
  void removeImageCallback(int imageId);

  ///
  void setExposure(int imageId, double exposure);

  ///
  void setContrast(int imageId, double contrast);

  ///
  void setSaturation(int imageId, double saturation);

  ///
  void setTemperature(int imageId, double temperature);

  ///
  void setTint(int imageId, double tint);

  void dispose(int imageId);
}
