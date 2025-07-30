import 'package:flutter/material.dart';

import 'video_editor.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(), body: VideoEditor());

    // return Scaffold(
    //   body: Center(
    //     child: TextButton(
    //       onPressed: () {
    //         Navigator.of(context).push(
    //           MaterialPageRoute(
    //             builder: (context) => Scaffold(
    //               appBar: AppBar(title: Text('Media Filters')),
    //               body: VideoEditor(),
    //             ),
    //           ),
    //         );
    //       },
    //       child: Text('Open'),
    //     ),
    //   ),
    // );
  }
}
