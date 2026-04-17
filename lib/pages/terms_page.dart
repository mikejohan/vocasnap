import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('利用規約')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Text('利用規約の内容をここに記載します。', style: TextStyle(height: 1.6)),
      ),
    );
  }
}