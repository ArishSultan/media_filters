import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:media_filters/media_filters.dart';
import 'package:media_filters_example/src/app.dart';

void main() {
  runApp(App());
}

// class MyApp extends StatefulWidget {
//   const MyApp({super.key});
//
//   @override
//   State<MyApp> createState() => _MyAppState();
// }
//
// class _MyAppState extends State<MyApp> {
//   final controller = VideoPlayerController();
//
//   var shouldShow = false;
//
//   @override
//   void initState() {
//     super.initState();
//     initPlatformState();
//
//     // controller.setup();
//     // print(controller.viewId);
//   }
//
//   // Platform messages are asynchronous, so we initialize in an async method.
//   Future<void> initPlatformState() async {}
//
//   var tint = 0;
//   var exposure = 0.0;
//   var contrast = 1.0;
//   var saturation = 1.0;
//   var temperature = 6500;
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(title: const Text('Plugin example app')),
//         body: Column(
//           children: [
//             TextButton(
//               child: Text('Pick Video'),
//               onPressed: () async {
//                 final file = await FilePicker.platform.pickFiles(
//                   type: FileType.video,
//                   allowMultiple: false,
//                 );
//
//                 if (file != null) {
//                   controller.loadFileVideo(file.paths[0]!);
//
//                   // Future.delayed(Duration(seconds: 2), () {
//                   //   shouldShow = true;
//                   //
//                   //   setState(() {});
//                   // });
//                 }
//               },
//             ),
//
//             TextButton(
//               child: Text('Pick Filter'),
//               onPressed: () async {
//                 final file = await FilePicker.platform.pickFiles(
//                   type: FileType.any,
//                   allowMultiple: false,
//                 );
//
//                 if (file != null) {
//                   controller.loadFilterFile(file.paths[0]!);
//                 }
//               },
//             ),
//
//             Row(
//               children: [
//                 TextButton(
//                   child: Text('Play'),
//                   onPressed: () async {
//                     controller.play();
//                   },
//                 ),
//                 TextButton(
//                   child: Text('Pause'),
//                   onPressed: () async {
//                     controller.pause();
//                   },
//                 ),
//               ],
//             ),
//             AspectRatio(
//               aspectRatio: 16 / 9,
//               child: VideoPlayer(controller: controller),
//             ),
//
//             StreamBuilder(
//               stream: controller.duration,
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) {
//                   return CircularProgressIndicator();
//                 }
//                 //
//                 final duration = snapshot.data!;
//
//                 return StreamBuilder(
//                   stream: controller.progress,
//                   builder: (context, snapshot) {
//                     if (!snapshot.hasData) {
//                       return CircularProgressIndicator();
//                     }
//
//                     final progress = snapshot.data!;
//
//                     return Column(
//                       children: [
//                         Slider(
//                           divisions: 100,
//                           year2023: false,
//                           min: 0,
//                           max: duration.inMilliseconds.toDouble(),
//                           value: progress.inMilliseconds.toDouble(),
//                           onChangeStart: (_) {
//                             controller.pause();
//                           },
//                           onChanged: (val) {
//                             controller.seekTo(val.round());
//                           },
//                           onChangeEnd: (_) {
//                             controller.play();
//                           },
//                         ),
//
//                         Row(
//                           children: [
//                             Text(progress.toString()),
//                             Spacer(),
//                             Text(duration.toString()),
//                           ],
//                         ),
//                       ],
//                     );
//                   },
//                 );
//               },
//             ),
//
//             // Exposure
//             Slider(
//               min: -10.0,
//               max: 10.0,
//               value: exposure,
//               year2023: false,
//               onChanged: (val) {
//                 exposure = val;
//                 setState(() {});
//               },
//               onChangeEnd: (val) {
//                 controller.setExposure(val);
//               },
//             ),
//
//             // Contrast
//             Slider(
//               min: 0.0,
//               max: 4.0,
//               value: contrast,
//               year2023: false,
//               onChanged: (val) {
//                 contrast = val;
//                 setState(() {});
//               },
//               onChangeEnd: (val) {
//                 controller.setContrast(val);
//               },
//             ),
//
//             // Saturation
//             Slider(
//               min: 0.0,
//               max: 2.0,
//               value: saturation,
//               year2023: false,
//               onChanged: (val) {
//                 saturation = val;
//                 setState(() {});
//               },
//               onChangeEnd: (val) {
//                 controller.setSaturation(val);
//               },
//             ),
//
//             // Temperature
//             Slider(
//               min: 2000,
//               max: 10000,
//               value: temperature.toDouble(),
//               year2023: false,
//               onChanged: (val) {
//                 temperature = val.round();
//                 setState(() {});
//               },
//               onChangeEnd: (val) {
//                 controller.setTemperature(val);
//               },
//             ),
//
//             // Tint
//             Slider(
//               min: -200.0,
//               max: 200.0,
//               value: tint.toDouble(),
//               year2023: false,
//               onChanged: (val) {
//                 tint = val.round();
//                 setState(() {});
//               },
//               onChangeEnd: (val) {
//                 controller.setTint(val);
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   //
//   @override
//   void dispose() {
//     super.dispose();
//
//     controller.dispose();
//   }
// }
