import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cac/main.dart';
import 'package:cac/pages/info_page.dart';
import 'package:cac/pages/terms_page.dart';
import 'package:cac/pages/privacy_page.dart';
import 'package:cac/pages/contact_page.dart';
import 'package:cac/pages/licenses_page.dart';
import 'package:cac/pages/settings_page.dart';
import 'package:flutter_tts/flutter_tts.dart';

Timer? _timer;

const int kDailyApiLimit = 13;

enum DescriptionMode {
  descriptive('説明文', 'この画像に写っているものを客観的に日本語と英語で説明してください。'),
  casual('会話調', 'この画像について、友達に話しかけるような楽しい会話調で日本語と英語で説明してください。'),
  poem('ポエム', 'この画像からインスピレーションを受けて、詩的・幻想的な表現で日本語と英語で短いポエムを書いてください。');

  final String label;
  final String prompt;
  const DescriptionMode(this.label, this.prompt);
}

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  bool _isInitialized = false;
  String? _errorMessage;
  bool _isAnalyzing = false;
  DescriptionMode _mode = DescriptionMode.descriptive;
  final FlutterTts _tts = FlutterTts();
  int _remainingCount = kDailyApiLimit;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _initTts();
    _loadRemainingCount();
    Future.delayed(const Duration(seconds: 3), () {
      _analyzeImage();
    });
  }

  Future<void> _loadRemainingCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = prefs.getString('api_call_date') ?? '';
    final count = savedDate == today
        ? (prefs.getInt('api_call_count') ?? 0)
        : 0;
    if (mounted) setState(() => _remainingCount = kDailyApiLimit - count);
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    // premium音声が利用可能であれば優先して使用
    final voices = await _tts.getVoices as List?;
    if (voices != null) {
      final premium = voices.cast<Map>().where((v) {
        final name = (v['name'] as String? ?? '').toLowerCase();
        return v['locale'] == 'en-US' && name.contains('premium');
      }).toList();
      if (premium.isNotEmpty) {
        await _tts.setVoice({'name': premium.first['name'], 'locale': 'en-US'});
      }
    }
  }

  Future<void> _initCamera() async {
    if (cameras.isEmpty) {
      setState(() => _errorMessage = 'カメラが見つかりません');
      return;
    }

    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      setState(() => _errorMessage = 'カメラの起動に失敗しました: $e');
    }
  }

  Future<bool> _checkDailyLimit() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = prefs.getString('api_call_date') ?? '';
    int count = prefs.getInt('api_call_count') ?? 0;

    if (savedDate != today) {
      count = 0;
      await prefs.setString('api_call_date', today);
    }

    if (count >= kDailyApiLimit) return false;

    await prefs.setInt('api_call_count', count + 1);
    return true;
  }

  Future<void> _analyzeImage() async {
    if (_isAnalyzing || _controller == null) return;
    if (!_controller!.value.isInitialized) return;

    final allowed = await _checkDailyLimit();
    if (mounted)
      setState(() => _remainingCount = allowed ? _remainingCount - 1 : 0);
    if (!allowed) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            content: const Text(
              '本日の利用上限（$kDailyApiLimit回）に達しました。\n翌日またご利用ください。',
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      final XFile imageFile = await _controller!.takePicture();
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      final response = await http.post(
        Uri.parse('https://rapid-band-c3f6.johanmike549.workers.dev'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'claude-haiku-4-5',
          'max_tokens': 300,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image',
                  'source': {
                    'type': 'base64',
                    'media_type': 'image/jpeg',
                    'data': base64Image,
                  },
                },
                {
                  'type': 'text',
                  'text':
                      '${_mode.prompt}以下のJSON形式のみで返してください。各文は改行(\\n)で区切ってください。\n{"japanese": "日本語の文1。\\n日本語の文2。", "english": "English sentence 1.\\nEnglish sentence 2."}',
                },
              ],
            },
          ],
        }),
      );

      String japanese;
      String english;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final raw = data['content'][0]['text'] as String;
        final text = raw.replaceAll(RegExp(r'```json|```'), '').trim();
        final parsed = jsonDecode(text);
        japanese = parsed['japanese'] as String;
        english = parsed['english'] as String;
      } else {
        japanese = 'エラー: ${response.statusCode}';
        english = '';
      }

      if (mounted) {
        _showResultSheet(imageBytes, japanese, english);
      }
    } catch (e) {
      if (mounted) {
        _showResultSheet(null, '通信エラー: $e', '');
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _showResultSheet(
    Uint8List? imageBytes,
    String japanese,
    String english,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool isSpeaking = false;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            _tts.setCompletionHandler(
              () => setSheetState(() => isSpeaking = false),
            );
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.all(16),
                child: SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ドラッグハンドル
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        // 撮影画像
                        if (imageBytes != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              imageBytes,
                              height: 260,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        const SizedBox(height: 12),
                        // 日本語
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '🇯🇵 日本語',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          japanese,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Icon(Icons.swap_horiz, color: Colors.grey),
                        const SizedBox(height: 12),
                        // 英語
                        Row(
                          children: [
                            const Text(
                              '🇺🇸 English',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                isSpeaking
                                    ? Icons.stop_circle_outlined
                                    : Icons.volume_up,
                                size: 32,
                                color: isSpeaking
                                    ? Colors.orangeAccent
                                    : Colors.grey,
                              ),
                              onPressed: english.isEmpty
                                  ? null
                                  : () async {
                                      if (isSpeaking) {
                                        await _tts.stop();
                                        setSheetState(() => isSpeaking = false);
                                      } else {
                                        setSheetState(() => isSpeaking = true);
                                        await _tts.speak(english);
                                      }
                                    },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          english,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // ボタン行
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.copy, size: 16),
                              label: const Text('テキストをコピー'),
                              onPressed: () async {
                                try {
                                  await Clipboard.setData(
                                    ClipboardData(
                                      text: '$japanese\n\n$english',
                                    ),
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('コピーしました'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('コピーに失敗しました'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton.icon(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              label: const Text(
                                '破棄',
                                style: TextStyle(color: Colors.red),
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.save_alt),
                              label: const Text('保存'),
                              onPressed: imageBytes == null
                                  ? null
                                  : () async {
                                      final result =
                                          await ImageGallerySaver.saveImage(
                                            imageBytes,
                                          );
                                      if (context.mounted) {
                                        final success =
                                            result['isSuccess'] == true;
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            content: Text(
                                              success ? '保存しました' : '保存に失敗しました',
                                              textAlign: TextAlign.center,
                                            ),
                                            actionsAlignment:
                                                MainAxisAlignment.center,
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx),
                                                child: const Text('OK'),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                    },
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.share),
                              label: const Text('シェア'),
                              onPressed: imageBytes == null
                                  ? null
                                  : () async {
                                      final dir = await getTemporaryDirectory();
                                      final file = File(
                                        '${dir.path}/share_image.jpg',
                                      );
                                      await file.writeAsBytes(imageBytes);
                                      await SharePlus.instance.share(
                                        ShareParams(
                                          text: '$japanese\n\n$english',
                                          files: [XFile(file.path)],
                                        ),
                                      );
                                    },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text(
          '本日${kDailyApiLimit - _remainingCount}回利用、残り $_remainingCount 回です。',
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const InfoPage()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.orangeAccent),
              child: Text(
                'Camera AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('設定'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.article_outlined),
              title: const Text('利用規約'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TermsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('プライバシーポリシー'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacyPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text('コンタクト'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ContactPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.library_books_outlined),
              title: const Text('ライブラリ一覧'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LicensesPage()),
                );
              },
            ),
          ],
        ),
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // カメラプレビュー（全画面）
          SizedBox.expand(child: CameraPreview(_controller!)),

          // モード選択チップ
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: DescriptionMode.values.map((mode) {
                  final selected = _mode == mode;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(mode.label),
                      selected: selected,
                      onSelected: (_) => setState(() => _mode = mode),
                      selectedColor: Colors.orangeAccent,
                      backgroundColor: Colors.black54,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // 撮影ボタン
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _analyzeImage,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isAnalyzing ? Colors.grey : Colors.orangeAccent,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: _isAnalyzing
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.camera_alt, color: Colors.black),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
