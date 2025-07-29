import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:media_filters/media_filters.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'filters_panel.dart';

class ImageEditorView2 extends StatefulWidget {
  const ImageEditorView2({super.key});

  @override
  State<ImageEditorView2> createState() => _ImageEditorViewState();
}

class _ImageEditorViewState extends State<ImageEditorView2>
    with SingleTickerProviderStateMixin {
  final imageEditor = ImageEditor();

  var exposure = 0.0;
  var contrast = 1.0;
  var saturation = 1.0;
  var temperature = 6500.0;
  var tint = 0.0;
  var lutFile = null;
  var lutFileToggle = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        12,
        12,
        12,
        MediaQuery.paddingOf(context).bottom + 20,
      ),
      child: Column(
        children: [
          const SizedBox(height: 100),

          SizedBox(child: ImageEditorView(editor: imageEditor), height: 400,),

          // StreamBuilder(
          //   stream: imageEditor.image,
          //   builder: (context, snapshot) {
          //     if (snapshot.hasData) {
          //       return Image.memory(snapshot.data!);
          //     }
          //
          //     return SizedBox();
          //   },
          // ),
          const SizedBox(height: 20),

          Row(
            spacing: 4,
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () {},
                  label: Text('Export Video'),
                  icon: Icon(Symbols.file_export),
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.fromHeight(45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(30),
                        right: Radius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),

              // Expanded(
              //   child: StreamBuilder(
              //     stream: videoPlayerController.duration,
              //     builder: (context, asyncSnapshot) {
              //       return FilledButton.tonalIcon(
              //         onPressed: asyncSnapshot.hasData ? resetFilters : null,
              //         icon: Icon(Symbols.filter),
              //         label: Text('Reset Filter'),
              //         style: FilledButton.styleFrom(
              //           padding: EdgeInsets.zero,
              //           minimumSize: Size.fromHeight(45),
              //           shape: RoundedRectangleBorder(
              //             borderRadius: BorderRadius.circular(10),
              //           ),
              //         ),
              //       );
              //     },
              //   ),
              // ),
              Expanded(
                child: FilledButton.icon(
                  onPressed: loadImageFile,
                  label: Text('Pick Image'),
                  icon: Icon(Symbols.upload_file_rounded),
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.fromHeight(45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(12),
                        right: Radius.circular(30),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          StreamBuilder(
            stream: imageEditor.image,
            builder: (context, asyncSnapshot) {
                return FiltersPanel(
                  tint: tint,
                  lutFile: lutFile,
                  exposure: exposure,
                  contrast: contrast,
                  saturation: saturation,
                  temperature: temperature,
                  lutFileToggle: lutFileToggle,

                  onTintChanged: onTintChanged,
                  onExposureChanged: onExposureChanged,
                  onContrastChanged: onContrastChanged,
                  onSaturationChanged: onSaturationChanged,
                  onTemperatureChanged: onTemperatureChanged,

                  onFilterChangeStart: onFilterChangeStart,
                  onFilterChangeEnd: onFilterChangeEnd,
                  onLutFileSelected: onLutFileSelected,
                  onLutFileToggle: onLutFileToggle,
                );

              return FiltersPanel(
                tint: tint,
                exposure: exposure,
                contrast: contrast,
                lutFileToggle: false,
                saturation: saturation,
                temperature: temperature,
              );
            },
          ),
        ],
      ),
    );
  }

  var wasPlayingBeforeFilter = false;

  void onFilterChangeEnd(double _) {
    if (wasPlayingBeforeFilter) {
      // videoPlayerController.play();
    }
  }

  void onFilterChangeStart(double _) async {
    // wasPlayingBeforeFilter =
    //     (await videoPlayerController.state.last) == VideoPlayerState.playing;
    // if (wasPlayingBeforeFilter) {
    // videoPlayerController.pause();
    // }
  }

  void onExposureChanged(double exposure) {
    imageEditor.setExposure(this.exposure = exposure);
    setState(() {});
  }

  void onContrastChanged(double contrast) {
    imageEditor.setContrast(this.contrast = contrast);
    setState(() {});
  }

  void onSaturationChanged(double saturation) {
    imageEditor.setSaturation(this.saturation = saturation);
    setState(() {});
  }

  void onTemperatureChanged(double temperature) {
    imageEditor.setTemperature(this.temperature = temperature);
    setState(() {});
  }

  void onTintChanged(double tint) {
    imageEditor.setTint(this.tint = tint);
    setState(() {});
  }

  void onLutFileSelected(String path) {
    lutFile = path;
    if (lutFileToggle) {
      imageEditor.loadFilterFile(path);
    }

    setState(() {});
  }

  void onLutFileToggle(bool? toggle) {
    toggle = toggle == true;
    if (toggle && lutFile != null) {
      lutFileToggle = toggle;
      imageEditor.loadFilterFile(lutFile);
    } else {
      imageEditor.removeFilterFile();
      lutFileToggle = toggle;
    }

    setState(() {});
  }

  void resetFilters() {
    imageEditor.setTint(tint = 0.8);
    imageEditor.setExposure(exposure = 0.0);
    imageEditor.setContrast(contrast = 1.0);
    imageEditor.setSaturation(saturation = 1.0);
    imageEditor.setTemperature(temperature = 6500.0);

    setState(() {});
  }

  void loadImageFile() async {
    final file = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (file != null) {
      imageEditor.loadFileImage(file.paths[0]!);
    }
  }
}

class VideoPlaybackControls extends StatefulWidget {
  const VideoPlaybackControls({
    super.key,
    required this.controller,
    this.duration,
  });

  final Duration? duration;
  final VideoPlayerController controller;

  @override
  State<VideoPlaybackControls> createState() => _VideoPlaybackControlsState();
}

class _VideoPlaybackControlsState extends State<VideoPlaybackControls>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController;
  late StreamSubscription<VideoPlayerState> playerStateSubscription;

  var progress = Duration.zero;
  var videoPlayerState = VideoPlayerState.stopped;

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    playerStateSubscription = widget.controller.stateStream.listen((data) {
      switch (data) {
        case VideoPlayerState.idle:
        case VideoPlayerState.ready:
        case VideoPlayerState.stopped:
          animationController.reverse();
          break;
        case VideoPlayerState.playing:
          animationController.forward();
          break;
        case VideoPlayerState.paused:
          animationController.reverse();
          break;
        case VideoPlayerState.completed:
          animationController.reverse();
          break;
        case VideoPlayerState.error:
          animationController.reverse();
          break;
        case VideoPlayerState.loading:
          throw UnimplementedError();
      }

      videoPlayerState = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StreamBuilder(
          stream: widget.controller.progressStream,
          builder: (context, asyncSnapshot) {
            progress = asyncSnapshot.data ?? Duration.zero;

            return Column(
              children: [
                Slider(
                  min: 0,
                  max:
                      widget.duration?.inMilliseconds.toDouble() ??
                      double.maxFinite,
                  value: asyncSnapshot.data?.inMilliseconds.toDouble() ?? 0.0,
                  onChanged: widget.duration != null ? seekTo : null,
                  padding: EdgeInsets.symmetric(horizontal: 10),
                ),

                Row(
                  spacing: 10,
                  children: [
                    if (asyncSnapshot.hasData)
                      Text(_formatDuration(asyncSnapshot.data!)),
                    Spacer(),
                    if (widget.duration != null)
                      Text(_formatDuration(widget.duration!))
                    else ...[
                      SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      Text('--:--'),
                    ],
                  ],
                ),
              ],
            );
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filledTonal(
              onPressed: widget.duration != null ? replay10s : null,
              icon: Icon(Symbols.replay_10_rounded),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: widget.duration != null ? replay30s : null,
              icon: Icon(Symbols.replay_30_rounded),
              style: IconButton.styleFrom(minimumSize: Size(55, 45)),
            ),
            const SizedBox(width: 12),
            IconButton.filled(
              onPressed: widget.duration != null ? playPause : null,
              icon: AnimatedIcon(
                icon: AnimatedIcons.play_pause,
                progress: animationController,
              ),
              style: IconButton.styleFrom(
                iconSize: 42,
                minimumSize: Size(66, 66),
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filledTonal(
              icon: Icon(Symbols.forward_30_rounded),
              style: IconButton.styleFrom(minimumSize: Size(55, 45)),
              onPressed: widget.duration != null ? forward30s : null,
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              icon: Icon(Symbols.forward_10_rounded),
              onPressed: widget.duration != null ? forward10s : null,
            ),
          ],
        ),
      ],
    );
  }

  void playPause() {
    if (videoPlayerState == VideoPlayerState.playing) {
      widget.controller.pause();
    } else {
      widget.controller.play();
    }
  }

  void replay(int seconds) async {
    widget.controller.seekTo(
      Duration(seconds: max(0, progress.inSeconds - seconds)).inMilliseconds,
    );
  }

  void replay10s() async {
    replay(10);
  }

  void replay30s() {
    replay(30);
  }

  void forward(int seconds) async {
    widget.controller.seekTo(
      Duration(
        seconds: min(widget.duration!.inSeconds, progress.inSeconds + seconds),
      ).inMilliseconds,
    );
  }

  void forward10s() {
    forward(10);
  }

  void forward30s() {
    forward(30);
  }

  void seekTo(double value) {
    widget.controller.seekTo(value.round());
  }

  @override
  void dispose() {
    playerStateSubscription.cancel();

    super.dispose();
  }
}

String _formatDuration(Duration d) {
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
