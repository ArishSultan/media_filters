import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:media_filters/media_filters.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final controller = VideoPreviewController();

  var shouldShow = false;

  @override
  void initState() {
    super.initState();
    initPlatformState();

    // controller.setup();
    // print(controller.viewId);
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {}

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: Column(
          children: [
            TextButton(
              child: Text('Pick Video'),
              onPressed: () async {
                final file = await FilePicker.platform.pickFiles(
                  type: FileType.video,
                  allowMultiple: false,
                );

                if (file != null) {
                  controller.loadVideoFile(file.paths[0]!);

                  // Future.delayed(Duration(seconds: 2), () {
                  //   shouldShow = true;
                  //
                  //   setState(() {});
                  // });
                }
              },
            ),

            TextButton(
              child: Text('Pick Filter'),
              onPressed: () async {
                final file = await FilePicker.platform.pickFiles(
                  type: FileType.any,
                  allowMultiple: false,
                );

                if (file != null) {
                  controller.loadFilterFile(file.paths[0]!);
                }
              },
            ),

            Row(
              children: [
                TextButton(
                  child: Text('Play'),
                  onPressed: () async {
                    controller.play();
                  },
                ),
                TextButton(
                  child: Text('Pause'),
                  onPressed: () async {
                    controller.pause();
                  },
                ),
              ],
            ),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: VideoPreview(controller: controller),
            ),

            StreamBuilder(
              stream: controller.duration,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return CircularProgressIndicator();
                }

                final duration = snapshot.data!;

                return StreamBuilder(
                  stream: controller.progress,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return CircularProgressIndicator();
                    }

                    final progress = snapshot.data!;

                    return Slider(
                      divisions: 100,
                      year2023:false,
                      min: 0,
                      max: duration.inMicroseconds.toDouble(),
                      value: progress.inMicroseconds.toDouble(),
                      onChanged: (val) {
                        controller.seekTo(val.round());
                      },
                    );
                  },
                );
              },
            ),
            // Row(
            //   children: [
            //     Expanded(
            //       child: StreamBuilder(
            //         stream: controller.state,
            //         builder: (context, snapshot) {
            //           if (snapshot.hasData) {
            //             return Text(snapshot.data!.toString());
            //           }
            //
            //           return CircularProgressIndicator();
            //         },
            //       ),
            //     ),
            //
            //     Expanded(
            //       child: StreamBuilder(
            //         stream: controller.progress,
            //         builder: (context, snapshot) {
            //           if (snapshot.hasData) {
            //             return Text(snapshot.data!.toString());
            //           }
            //
            //           return CircularProgressIndicator();
            //         },
            //       ),
            //     ),
            //
            //     Expanded(
            //       child: StreamBuilder(
            //         stream: controller.duration,
            //         builder: (context, snapshot) {
            //           if (snapshot.hasData) {
            //             return Text(snapshot.data!.toString());
            //           }
            //
            //           return CircularProgressIndicator();
            //         },
            //       ),
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }

  //
  @override
  void dispose() {
    super.dispose();

    controller.dispose();
  }
}
