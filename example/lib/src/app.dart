import 'package:flutter/material.dart';
import 'package:media_filters_example/src/home_view.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeView(),
      theme: ThemeData(
        progressIndicatorTheme: ProgressIndicatorThemeData(
          strokeCap: StrokeCap.round,
        ),
        sliderTheme: SliderThemeData(year2023: false),
      ),
    );
  }
}
