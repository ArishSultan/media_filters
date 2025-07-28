import 'dart:async';
import 'dart:typed_data';

import 'package:jni/jni.dart';

import 'jni.dart';
import '../../image_editor/image_editor_api.dart';

final class ImageEditorAndroidApi extends ImageEditorApi {
  @override
  Stream<Uint8List> get image => _imageStreamController.stream;

  final _imageStreamController = StreamController<Uint8List>.broadcast();

  @override
  void create(int imageId) {
    ApiImageEditor.create(imageId);
  }

  @override
  void loadAssetImage(int imageId, String locator) {
    // ApiImageEditor.destroy(imageId);
  }

  @override
  void loadFileImage(int imageId, String path) {
    ApiImageEditor.loadImageFile(imageId, path.toJString());
  }

  @override
  void loadFilterFile(int imageId, String filePath) {
    ApiImageEditor.loadFilterFile(imageId, filePath.toJString());
  }

  @override
  void loadNetworkImage(int imageId, String url) {
    // TODO: implement loadNetworkImage
  }

  @override
  void removeFilterFile(int imageId) {
    ApiImageEditor.removeLutFilter(imageId);
  }

  @override
  void removeImageCallback(int imageId) {
    _imageStreamControllerRegister.remove(imageId);
    ApiImageEditor.removeImageCallback(imageId);
  }

  @override
  void setContrast(int imageId, double contrast) {
    ApiImageEditor.setContrast(imageId, contrast);
  }

  @override
  void setExposure(int imageId, double exposure) {
    ApiImageEditor.setExposure(imageId, exposure);
  }

  @override
  void setImageCallback(int imageId) {
    _imageStreamControllerRegister[imageId] = _imageStreamController;

    ApiImageEditor.setImageCallback(
      imageId,
      ByteArrayCallback.implement(_ByteArrayCallback.instance),
    );
  }

  @override
  void setSaturation(int imageId, double saturation) {
    ApiImageEditor.setSaturation(imageId, saturation);
  }

  @override
  void setTemperature(int imageId, double temperature) {
    ApiImageEditor.setTemperature(imageId, temperature);
  }

  @override
  void setTint(int imageId, double tint) {
    ApiImageEditor.setTint(imageId, tint);
  }

  @override
  void dispose(int imageId) {
    ApiImageEditor.destroy(imageId);
  }
}

final _imageStreamControllerRegister = <int, StreamController<Uint8List>>{};

final class _ByteArrayCallback with $ByteArrayCallback {
  static final instance = _ByteArrayCallback();

  @override
  void invoke(int i, JByteArray bs) {
    _imageStreamControllerRegister[i]
        ?.sink
        .add(Uint8List.fromList(bs.toList()));
  }
}
