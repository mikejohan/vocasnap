import 'package:flutter/material.dart';

class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('使い方')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'このアプリについて',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '　カメラで撮影した写真をAIが分析し、写っているものを日本語と英語で説明します。日常の風景や物を撮影するだけで、自然な表現を日英両語で学べます。',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
            const SizedBox(height: 32),
            Text(
              '使い方',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _Step(number: '1', text: '画面下部のボタンをタップして写真を撮影します。'),
            const SizedBox(height: 12),
            _Step(number: '2', text: 'AIが画像を解析し、日本語と英語の説明を生成します。'),
            const SizedBox(height: 12),
            _Step(number: '3', text: '結果を確認したら、保存またはシェアできます。'),
            const SizedBox(height: 32),
            Text(
              '利用回数について',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '''　1日あたりの利用回数に上限があります。
　残り回数は画面上部に表示されます。
　上限に達した場合は翌日にリセットされます。
              ''',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
            const SizedBox(height: 32),
            Text(
              '表現のバリエーション',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'カメラ画面上部のチップでAIの説明スタイルを切り替えられます。',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
            const SizedBox(height: 12),
            _ModeItem(label: '説明文', description: '写っているものを客観的に説明します。'),
            const SizedBox(height: 8),
            _ModeItem(label: '会話調', description: '友達に話しかけるような、楽しい口調で説明します。'),
            const SizedBox(height: 8),
            _ModeItem(
              label: 'ポエム',
              description: '画像からインスピレーションを受けた詩的な表現で描写します。',
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeItem extends StatelessWidget {
  final String label;
  final String description;

  const _ModeItem({required this.label, required this.description});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Chip(
          label: Text(label, style: const TextStyle(fontSize: 12)),
          backgroundColor: Colors.orangeAccent.withAlpha(50),
          padding: EdgeInsets.zero,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              description,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final String number;
  final String text;

  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: Colors.orangeAccent,
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ),
      ],
    );
  }
}
