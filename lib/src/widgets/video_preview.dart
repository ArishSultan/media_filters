import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:media_filters/src/platform/ui_kit/ffi.dart';

const _kViewType = 'media_filters.preview';

enum VideoPreviewState { stopped, playing, paused, ended, error }

abstract class VideoPreviewController extends ChangeNotifier {
  VideoPreviewController();

  factory VideoPreviewController.factory() {
    return UiKitVideoPreviewController();
  }

  int get viewId;

  VideoPreviewState get state;

  void loadVideo(String path);

  void loadFilter(String path);

  void setup();

  void play();

  void pause();

  void seekTo(double value);

  void setFilter(String path) {
    // TODO: Call the setFilter function in the native platform.
  }

  @override
  void dispose();
}

class VideoPreview extends StatefulWidget {
  const VideoPreview({super.key, required this.controller});

  final VideoPreviewController controller;

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(rebuild);
  }

  @override
  void didUpdateWidget(covariant VideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(rebuild);
      widget.controller.addListener(rebuild);
    }
  }

  void rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final videoView = switch (defaultTargetPlatform) {
      TargetPlatform.android => AndroidView(viewType: _kViewType),
      TargetPlatform.iOS => UiKitView(viewType: _kViewType),
      _ => throw UnimplementedError(),
    };

    return AspectRatio(
      // TODO: Change this aspect ratio once we have the video loading done.
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          Positioned.fill(child: videoView),
          Center(
            child: IconButton(
              onPressed: () {
                if (widget.controller.state == VideoPreviewState.playing) {
                  widget.controller.pause();
                } else {
                  widget.controller.play();
                }
              },
              icon: Icon(Icons.play_arrow_rounded),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(rebuild);
    super.dispose();
  }
}
