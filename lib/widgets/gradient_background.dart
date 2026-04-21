import 'package:flutter/material.dart';
import 'package:cac/theme/gradient_config.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: gradientIndexNotifier,
      builder: (context, index, _) {
        final preset = gradientPresets[index];
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: preset.colors,
            ),
          ),
          child: child,
        );
      },
    );
  }
}