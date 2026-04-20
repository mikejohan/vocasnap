import 'package:flutter/material.dart';
import 'package:cac/constants.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('利用規約')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section(context, '第1条（適用）',
                '本規約は、$kDeveloperName（以下「当方」）が提供するアプリ「$kAppName」（以下「本アプリ」）の利用に関する条件を定めるものです。ユーザーは本規約に同意した上で本アプリをご利用ください。'),
            _section(context, '第2条（利用条件）',
                '本アプリは、スマートフォンのカメラで撮影した画像をAIに送信し、日本語・英語による説明文を生成する機能を提供します。1日あたりの利用回数に上限を設けています。'),
            _section(context, '第3条（禁止事項）',
                '以下の行為を禁止します。\n・法令または公序良俗に反する行為\n・未成年者や第三者を無断で撮影・送信する行為\n・個人が特定できる情報を含む画像の送信\n・本アプリの運営を妨害する行為\n・リバースエンジニアリング・改ざん等の行為\n・その他、当方が不適切と判断する行為'),
            _section(context, '第4条（免責事項）',
                '本アプリが提供するAIの生成内容は自動生成によるものであり、正確性・完全性を保証するものではありません。\n生成コンテンツのSNSへの投稿・第三者への公開・利用はユーザー自身の責任において行うものとし、当方は一切の責任を負いません。\nまた、通信環境・端末環境による不具合、第三者サービス（AI APIを含む）の障害・仕様変更による影響についても、当方は責任を負いません。'),
            _section(context, '第5条（サービスの変更・停止）',
                '当方は、ユーザーへの事前通知なく、本アプリの内容を変更または提供を停止する場合があります。'),
            _section(context, '第6条（規約の変更）',
                '当方は必要に応じて本規約を変更することがあります。変更後の規約はアプリ内に掲示した時点で効力を持つものとします。'),
            _section(context, '第7条（お問い合わせ）',
                '本規約に関するお問い合わせは下記までご連絡ください。\n$kContactEmail'),
          ],
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.7),
          ),
        ],
      ),
    );
  }
}