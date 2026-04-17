import 'package:flutter/material.dart';
import 'package:cac/pages/camera_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.camera_alt),
          label: const Text('カメラを起動'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CameraPage()),
            );
          },
        ),
      ),
    );
  }
}