import 'package:flutter/material.dart';
import 'package:cac/pages/camera_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const Center(
            child: Text(
              'Camera AI',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ),
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('カメラを起動'),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const CameraPage()),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}