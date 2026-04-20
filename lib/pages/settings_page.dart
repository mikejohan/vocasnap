import 'package:flutter/material.dart';
import 'package:cac/theme/gradient_config.dart';
import 'package:cac/widgets/gradient_background.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('設定')),
      body: GradientBackground(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              '背景グラデーション',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<int>(
              valueListenable: gradientIndexNotifier,
              builder: (context, selectedIndex, _) {
                return Column(
                  children: List.generate(gradientPresets.length, (index) {
                    final preset = gradientPresets[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => saveGradientIndex(index),
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: preset.colors,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedIndex == index
                                  ? Colors.orangeAccent
                                  : Colors.grey.shade300,
                              width: selectedIndex == index ? 2.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 16),
                              Text(
                                preset.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              const Spacer(),
                              if (selectedIndex == index)
                                const Padding(
                                  padding: EdgeInsets.only(right: 16),
                                  child: Icon(Icons.check_circle, color: Colors.orangeAccent),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}