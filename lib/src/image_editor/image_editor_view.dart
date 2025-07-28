import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:media_filters/media_filters.dart';

class ImageEditorView extends StatelessWidget {
  const ImageEditorView({super.key, required this.editor});

  final ImageEditor editor;

  @override
  Widget build(BuildContext context) {
    const kViewType = 'media_filters.preview';
    final creationParams = {'viewId': editor.imageId, 'type': 1};

    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => UiKitView(
          viewType: kViewType,
          creationParams: creationParams,
          creationParamsCodec: StandardMessageCodec(),
        ),
      TargetPlatform.android => AndroidView(
          viewType: kViewType,
          creationParams: creationParams,
          creationParamsCodec: StandardMessageCodec()),
      _ => throw UnimplementedError(),
    };
  }
}
