import 'package:flutter/material.dart';
import 'package:cac/constants.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('プライバシーポリシー')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section(context, '基本方針',
                '$kDeveloperName（以下「当方」）は、アプリ「$kAppName」（以下「本アプリ」）におけるユーザーの個人情報・プライバシーの取り扱いについて、以下の通り定めます。'),
            _section(context, '収集する情報',
                '本アプリは、アカウント登録を必要とせず、氏名・メールアドレス等の個人情報を収集しません。\n\n本アプリが収集・利用する情報は以下の通りです。\n\n【撮影画像】\nユーザーが撮影した画像は、AI分析のために外部サービス（後述）に送信されます。画像は分析目的にのみ使用され、当方のサーバーには保存されません。\n\n【利用回数】\n1日あたりの利用回数および最終利用日をお使いの端末内にのみ保存します。この情報が外部に送信されることはありません。'),
            _section(context, '第三者サービスへの情報提供',
                '本アプリは以下の第三者サービスを利用しており、撮影画像がこれらのサービスに送信されます。\n\n・Cloudflare Workers（通信中継）\n　https://www.cloudflare.com/privacypolicy/\n\n・Anthropic Claude API（AI分析）\n　https://www.anthropic.com/privacy\n\n各サービスのプライバシーポリシーについては上記URLをご参照ください。'),
            _section(context, '画像の取り扱いに関するご注意',
                '撮影・送信する画像に個人情報や第三者のプライバシーに関わる情報が含まれないようご注意ください。送信された画像の取り扱いは、各第三者サービスのポリシーに準じます。'),
            _section(context, 'ローカルデータについて',
                '端末内に保存されるデータ（利用回数・日付）は、アプリをアンインストールすることで削除されます。'),
            _section(context, 'プライバシーポリシーの変更',
                '本ポリシーは必要に応じて改定することがあります。改定後のポリシーはアプリ内に掲示した時点で効力を持ちます。'),
            _section(context, 'お問い合わせ',
                '本ポリシーに関するお問い合わせは下記までご連絡ください。\n$kContactEmail'),
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