import 'package:flutter/foundation.dart';

import 'image_editor_api.dart';
import '../platform/android/image_editor_api.dart';

///
class ImageEditor {
  const ImageEditor._(this.api, this.imageId);

  factory ImageEditor() {
    final editor = ImageEditor._(
      switch (defaultTargetPlatform) {
        // TargetPlatform.iOS => VideoPlayerDarwinApi(),
        TargetPlatform.android => ImageEditorAndroidApi(),
        _ => throw UnimplementedError(),
      },
      ++_nextImageId,
    );

    editor.api.create(editor.imageId);
    editor.api.setImageCallback(editor.imageId);

    return editor;
  }

  final ImageEditorApi api;

  final int imageId;

  Stream<Uint8List> get image => api.image;

  void loadAssetImage(String locator) {
    api.loadAssetImage(imageId, locator);
  }

  void loadFileImage(String path) {
    api.loadFileImage(imageId, path);
  }

  void loadNetworkImage(String url) {
    api.loadNetworkImage(imageId, url);
  }

  void loadFilterFile(String filePath) {
    api.loadFilterFile(imageId, filePath);
  }

  void removeFilterFile() {
    api.removeFilterFile(imageId);
  }

  void setImageCallback() {
    // api.setImageCallback(imageId, locator);
  }

  void removeImageCallback() {
    // api.loadAssetImage(imageId, locator);
  }

  void setExposure(double exposure) {
    api.setExposure(imageId, exposure);
  }

  void setContrast(double contrast) {
    api.setContrast(imageId, contrast);
  }

  void setSaturation(double saturation) {
    api.setSaturation(imageId, saturation);
  }

  void setTemperature(double temperature) {
    api.setTemperature(imageId, temperature);
  }

  void setTint(double tint) {
    api.setTint(imageId, tint);
  }

  void dispose() {
    api.removeImageCallback(imageId);
    api.dispose(imageId);
  }

  static int _nextImageId = -1;
}
