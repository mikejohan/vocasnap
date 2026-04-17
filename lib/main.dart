//psinfoとほぼ同じ。ただアプリ名の問題。

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:cac/pages/landing_page.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camera AI',
      theme: ThemeData.dark(),
      home: const LandingPage(),
    );
  }
}
