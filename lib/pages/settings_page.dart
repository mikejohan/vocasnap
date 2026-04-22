import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cac/constants.dart';
import 'package:cac/theme/gradient_config.dart';
import 'package:cac/widgets/gradient_background.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double _speechRate = kTtsSpeechRateDefault;

  @override
  void initState() {
    super.initState();
    _loadSpeechRate();
  }

  Future<void> _loadSpeechRate() async {
    final prefs = await SharedPreferences.getInstance();
    final rate = prefs.getDouble(kTtsSpeechRateKey) ?? kTtsSpeechRateDefault;
    if (mounted) setState(() => _speechRate = rate);
  }

  Future<void> _saveSpeechRate(double rate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(kTtsSpeechRateKey, rate);
  }

  String _rateLabel(double rate) {
    if (rate < 0.3) return '遅い';
    if (rate < 0.5) return '普通';
    if (rate < 0.65) return '速い';
    return 'とても速い';
  }

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
              '読み上げ速度',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.volume_up, color: Colors.black54, size: 20),
                Expanded(
                  child: Slider(
                    value: _speechRate,
                    min: 0.2,
                    max: 0.8,
                    divisions: 12,
                    activeColor: Colors.orangeAccent,
                    onChanged: (value) {
                      setState(() => _speechRate = value);
                    },
                    onChangeEnd: _saveSpeechRate,
                  ),
                ),
                SizedBox(
                  width: 64,
                  child: Text(
                    _rateLabel(_speechRate),
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
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
