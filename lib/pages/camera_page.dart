import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
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
  String _aiComment = '';
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
    // カメラ初期化後に5秒ごとに自動解析
    //やはり「ボタン押下→API呼び出し」とするのでとりあえずコメントアウト
    //最終的に、「最初のみ3秒経過後に呼び出し、その後はボタン押下毎に呼び出し、
    // ブラウザリロードで3秒経過後に呼び出し」とした。
    Future.delayed(const Duration(seconds: 3), () {
      _analyzeImage();
      // _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      //   _analyzeImage();
      // });
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
      ResolutionPreset.medium, // 画像サイズ抑えてコスト節約
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
    // これを追加
    if (!_controller!.value.isInitialized) return;

    setState(() {
      _isAnalyzing = true;
      _aiComment = '解析中...';
    });

    try {
      // 画像キャプチャ
      final XFile imageFile = await _controller!.takePicture();
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      // Claude Haiku 4.5 API呼び出し
      final response = await http.post(
        // Uri.parse('https://api.anthropic.com/v1/messages'),
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
                  //案A-2：毒舌ボケ型(ボケでもツッコミでも変わらない。)
                  // 'text':
                  //     'あなたはお笑い芸人です。この画像に対して、毒舌だけど愛のあるボケを一言だけしてください。説明は不要。ボケだけ。30文字以内。',
                  //案B：大喜利型（写真で一言）
                  // 'text':
                  //     'この画像を大喜利のお題として「写真で一言」を答えてください。説明や前置きは一切不要。回答だけを30文字以内で。',
                  //案C：陽キャ応援型(明るいコメントが出るが、面白いかは別、別に面白くはない。)
                  // 'text':
                  //     'あなたは何を見てもポジティブに解釈する陽キャです。この画像を見て、明るく一言コメントしてください。説明不要。30文字以内。',
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        print("🐈${response.statusCode}");
        final data = jsonDecode(response.body);
        print("🐈${data}");
        final comment = data['content'][0]['text'] as String;
        print("🐈${data}");
        setState(() => _aiComment = comment);
      } else {
        setState(() => _aiComment = 'エラー: ${response.statusCode}');
        print('エラー: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _aiComment = '通信エラー: $e');
      print('通信エラー: $e');
    } finally {
      setState(() => _isAnalyzing = false);
    }
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
            icon: Icon(Icons.info),
            onPressed: () {
              // ここで画面遷移
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

          // AIコメント表示エリア（下部）
          if (_aiComment.isNotEmpty)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _aiComment,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
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