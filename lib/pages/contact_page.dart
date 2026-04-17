import 'package:flutter/material.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('コンタクト')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Text('コンタクト情報をここに記載します。', style: TextStyle(height: 1.6)),
      ),
    );
  }
}
