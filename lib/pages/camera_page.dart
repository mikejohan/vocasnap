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
import 'package:cac/main.dart';
import 'package:cac/pages/info_page.dart';

Timer? _timer;

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

  @override
  void initState() {
    super.initState();
    _initCamera();
    Future.delayed(const Duration(seconds: 3), () {
      _analyzeImage();
    });
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

  Future<void> _analyzeImage() async {
    if (_isAnalyzing || _controller == null) return;
    if (!_controller!.value.isInitialized) return;

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
                      'この画像に写っているものを日本語と英語で説明してください。以下のJSON形式のみで返してください。説明文は各言語で2〜3文程度。各文は改行(\\n)で区切ってください。\n{"japanese": "日本語の文1。\\n日本語の文2。", "english": "English sentence 1.\\nEnglish sentence 2."}',
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

  void _showResultSheet(Uint8List? imageBytes, String japanese, String english) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
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
                    child: Text('🇯🇵 日本語',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                  const SizedBox(height: 4),
                  Text(japanese,
                      style: const TextStyle(fontSize: 15, color: Colors.black87)),
                  const SizedBox(height: 12),
                  const Icon(Icons.swap_horiz, color: Colors.grey),
                  const SizedBox(height: 12),
                  // 英語
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('🇺🇸 English',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                  const SizedBox(height: 4),
                  Text(english,
                      style: const TextStyle(fontSize: 15, color: Colors.black87)),
                  const SizedBox(height: 20),
                  // ボタン行
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
                                  final success = result['isSuccess'] == true;
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
                                          onPressed: () => Navigator.pop(ctx),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const InfoPage()),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // カメラプレビュー（全画面）
          SizedBox.expand(child: CameraPreview(_controller!)),

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
