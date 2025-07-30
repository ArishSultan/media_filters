import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:media_filters/media_filters.dart';
import 'package:path_provider/path_provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoEditor extends StatefulWidget {
  const VideoEditor({super.key});

  @override
  State<VideoEditor> createState() => _VideoEditorState();
}

class _VideoEditorState extends State<VideoEditor>
    with SingleTickerProviderStateMixin {
  final videoPlayerController = VideoPlayerController();
  final videoExporter = VideoExporterApi();

  var tint = kDefaultTint;
  var exposure = kDefaultExposure;
  var contrast = kDefaultContrast;
  var saturation = kDefaultSaturation;
  var temperature = kDefaultTemperature;

  String? lutFile;
  var lutFileToggle = false;

  String? pickedFile;

  @override
  Widget build(BuildContext context) {
    var aspectRatio = videoPlayerController.size.aspectRatio;
    if (aspectRatio == 0.0) {
      aspectRatio = 16 / 9;
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        12,
        12,
        12,
        MediaQuery.paddingOf(context).bottom + 20,
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: aspectRatio,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: VideoPlayer(controller: videoPlayerController),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: VideoPlaybackControls(
              controller: videoPlayerController,
              duration: videoPlayerController.duration,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            spacing: 4,
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () async {
                    videoExporter.export(
                      id: 1,
                      input: pickedFile!,
                      output:
                          '${(await getApplicationDocumentsDirectory()).path}/output.mp4',
                      filter: lutFile,
                      contrast: contrast,
                      saturation: saturation,
                      exposure: exposure,
                      temperature: temperature,
                      tint: tint,
                    );

                    videoExporter.progressStream.listen((progress) async {
                      if (progress < 1) {
                        return;
                      }
                      pickedFile =
                          '${(await getApplicationDocumentsDirectory()).path}/output.mp4';

                      final stats = File(pickedFile!).statSync();
                      if (stats.size > 0) {
                        print('saving to gallery');

                        if ((await Permission.storage.request()) ==
                            PermissionStatus.granted) {
                          GallerySaver.saveVideo(pickedFile!);
                        }

                        print('saving to gallery done');
                      }
                    });
                  },
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

              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: resetFilters,
                  icon: Icon(Symbols.filter),
                  label: Text('Reset Filter'),
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.fromHeight(45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: FilledButton.icon(
                  onPressed: loadVideoFile,
                  label: Text('Pick Video'),
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

          // StreamBuilder(
          //   stream: videoPlayerController.durationStream,
          //   builder: (context, asyncSnapshot) {
          //     if (asyncSnapshot.hasData) {
          //         tint: tint,
          //         lutFile: lutFile,
          //         exposure: exposure,
          //         contrast: contrast,
          //         saturation: saturation,
          //         temperature: temperature,
          //         lutFileToggle: lutFileToggle,
          //
          //         onTintChanged: onTintChanged,
          //         onExposureChanged: onExposureChanged,
          //         onContrastChanged: onContrastChanged,
          //         onSaturationChanged: onSaturationChanged,
          //         onTemperatureChanged: onTemperatureChanged,
          //
          //         onFilterChangeStart: onFilterChangeStart,
          //         onFilterChangeEnd: onFilterChangeEnd,
          //         onLutFileSelected: onLutFileSelected,
          //         onLutFileToggle: onLutFileToggle,
          //       );
          //   },
          // ),
        ],
      ),
    );
  }

  var wasPlayingBeforeFilter = false;

  void onFilterChangeEnd(double _) {
    if (wasPlayingBeforeFilter) {
      videoPlayerController.play();
    }
  }

  void onFilterChangeStart(double _) async {
    wasPlayingBeforeFilter =
        videoPlayerController.state == VideoPlayerState.playing;
    if (wasPlayingBeforeFilter) {
      videoPlayerController.pause();
    }
  }

  void onExposureChanged(double exposure) {
    // videoPlayerController.setExposure(this.exposure = exposure);
    setState(() {});
  }

  void onContrastChanged(double contrast) {
    // videoPlayerController.setContrast(this.contrast = contrast);
    setState(() {});
  }

  void onSaturationChanged(double saturation) {
    // videoPlayerController.setSaturation(this.saturation = saturation);
    // setState(() {});
  }

  void onTemperatureChanged(double temperature) {
    // videoPlayerController.setTemperature(this.temperature = temperature);
    // setState(() {});
  }

  void onTintChanged(double tint) {
    // videoPlayerController.setTint(this.tint = tint);
    // setState(() {});
  }

  void onLutFileSelected(String path) {
    lutFile = path;
    if (lutFileToggle) {
      // videoPlayerController.loadFilterFile(path);
    }

    setState(() {});
  }

  void onLutFileToggle(bool? toggle) {
    toggle = toggle == true;
    if (toggle && lutFile != null) {
      // lutFileToggle = toggle//;
      // videoPlayerController.loadFilterFile(lutFile!);
    } else {
      // videoPlayerController.removeFilterFile();
      lutFileToggle = toggle;
    }

    setState(() {});
  }

  void resetFilters() {
    videoPlayerController.setAndApplyFilters(tint: -150);
    // videoPlayerController.setTint(tint = 0.8);
    // videoPlayerController.setExposure(exposure = 0.0);
    // videoPlayerController.setContrast(contrast = 1.0);
    // videoPlayerController.setSaturation(saturation = 1.0);
    // videoPlayerController.setTemperature(temperature = 6500.0);

    setState(() {});
  }

  void loadVideoFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );

    if (result != null) {
      await videoPlayerController.loadFile(File(result.files[0]!.path!));
      setState(() {});
    }

    Future.delayed(Duration(seconds: 5), () {
      setState(() {});
    });
  }

  @override
  void dispose() {
    videoPlayerController.dispose();
    super.dispose();
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
          animationController.reverse();
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
    widget.controller.seek(
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
    widget.controller.seek(
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
    widget.controller.seek(value.round());
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
