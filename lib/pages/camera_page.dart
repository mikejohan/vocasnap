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
                  //デフォルト
                  'text': 'この画像に写っているものを見て、簡潔に日本語で面白いコメントしてください。30文字以内で。',
                  //案A-1：毒舌ツッコミ型
                  // 'text':
                  //     'あなたはお笑い芸人です。この画像に対して、毒舌だけど愛のあるツッコミを一言だけしてください。説明は不要。ツッコミだけ。30文字以内。',
                  //案A-2：毒舌ボケ型
                  // 'text':
                  //     'あなたはお笑い芸人です。この画像に対して、毒舌だけど愛のあるボケを一言だけしてください。説明は不要。ボケだけ。30文字以内。',
                  //案B：大喜利型
                  // 'text':
                  //     'この画像を大喜利のお題として「写真で一言」を答えてください。説明や前置きは一切不要。回答だけを30文字以内で。',
                  //案C：陽キャ応援型
                  // 'text':
                  //     'あなたは何を見てもポジティブに解釈する陽キャです。この画像を見て、明るく一言コメントしてください。説明不要。30文字以内。',
                },
              ],
            },
          ],
        }),
      );

      String comment;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        comment = data['content'][0]['text'] as String;
      } else {
        comment = 'エラー: ${response.statusCode}';
      }

      if (mounted) {
        _showResultSheet(imageBytes, comment);
      }
    } catch (e) {
      if (mounted) {
        _showResultSheet(null, '通信エラー: $e');
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _showResultSheet(Uint8List? imageBytes, String comment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: SafeArea(
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
                // AIコメント
                Text(
                  comment,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // ボタン行
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
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
                              final result = await ImageGallerySaver.saveImage(imageBytes);
                              if (context.mounted) {
                                final success = result['isSuccess'] == true;
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    content: Text(
                                      success ? '保存しました' : '保存に失敗しました',
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
                            },
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.share),
                      label: const Text('シェア'),
                      onPressed: imageBytes == null
                          ? null
                          : () async {
                              final dir = await getTemporaryDirectory();
                              final file = File('${dir.path}/share_image.jpg');
                              await file.writeAsBytes(imageBytes);
                              await SharePlus.instance.share(
                                ShareParams(
                                  text: comment,
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
