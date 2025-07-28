import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:media_filters_example/src/image_editor.dart';
import 'package:media_filters_example/src/video_editor.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  var _index = 0;

  onDestinationSelected(int? value) {
    _index = value!;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Media Filters'),
          bottom: TabBar(
            tabs: [
              Tab(
                icon: Icon(Symbols.movie_edit_rounded, fill: 1),
                text: 'Video',
              ),
              Tab(icon: Icon(Symbols.image_rounded, fill: 1), text: 'Image'),
            ],
          ),
        ),
        body: TabBarView(children: [VideoEditor(), ImageEditorView2()]),
      ),
    );
  }
}
