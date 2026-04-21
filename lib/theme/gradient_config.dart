import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GradientPreset {
  final String name;
  final List<Color> colors;
  const GradientPreset(this.name, this.colors);
}

const List<GradientPreset> gradientPresets = [
  GradientPreset('デフォルト', [Colors.amber, Colors.tealAccent]),
  // GradientPreset('スカイ', [Color(0xFFE3F2FD), Color(0xFFE8EAF6)]),
  GradientPreset('サンセット', [Color(0xFFFFF3E0), Color(0xFFFCE4EC)]),
  GradientPreset('フォレスト', [Color(0xFFE8F5E9), Color(0xFFE0F2F1)]),
  GradientPreset('ラベンダー', [Color(0xFFF3E5F5), Color(0xFFE3F2FD)]),
  GradientPreset('ピーチ', [Color(0xFFFFFDE7), Color(0xFFFFF3E0)]),
];

final gradientIndexNotifier = ValueNotifier<int>(0);

Future<void> loadGradientConfig() async {
  final prefs = await SharedPreferences.getInstance();
  final index = prefs.getInt('gradient_index') ?? 0;
  gradientIndexNotifier.value = index.clamp(0, gradientPresets.length - 1);
}

Future<void> saveGradientIndex(int index) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('gradient_index', index);
  gradientIndexNotifier.value = index;
}
