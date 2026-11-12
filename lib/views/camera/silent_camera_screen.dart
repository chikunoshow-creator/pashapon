// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class SilentCameraScreen extends StatefulWidget {
  const SilentCameraScreen({super.key});

  @override
  State<SilentCameraScreen> createState() => _SilentCameraScreenState();
}

class _SilentCameraScreenState extends State<SilentCameraScreen> {
  html.VideoElement? _videoElement;
  html.MediaStream? _mediaStream;
  final String _viewId = 'silent-camera-${DateTime.now().millisecondsSinceEpoch}';
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startCamera();
  }

  Future<void> _startCamera() async {
    try {
      _videoElement = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';

      // iOS Safariでインライン再生させるための必須属性
      _videoElement!.setAttribute('playsinline', 'true');
      _videoElement!.setAttribute('webkit-playsinline', 'true');

      // プラットフォームビューに登録
      ui_web.platformViewRegistry.registerViewFactory(
        _viewId,
        (int id) => _videoElement!,
      );

      // 背面カメラを優先してストリーム取得
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        throw Exception('このブラウザはカメラアクセスをサポートしていません。');
      }

      final stream = await mediaDevices.getUserMedia({
        'video': {
          'facingMode': {'ideal': 'environment'}, // 背面カメラ
          'width': {'ideal': 1920},
          'height': {'ideal': 1080},
        },
        'audio': false, // 音声不要（完全無音）
      });

      _mediaStream = stream;
      _videoElement!.srcObject = stream;

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'カメラの起動に失敗しました: $e';
        });
      }
    }
  }

  void _capturePhoto() {
    if (_videoElement == null || !_isInitialized) return;

    final videoWidth = _videoElement!.videoWidth;
    final videoHeight = _videoElement!.videoHeight;

    if (videoWidth == 0 || videoHeight == 0) return;

    // Canvasを使って無音で現在のフレームを描画・切り出し
    final canvas = html.CanvasElement(width: videoWidth, height: videoHeight);
    canvas.context2D.drawImage(_videoElement!, 0, 0);

    // 軽量JPEGデータURL（シャッター音なし）
    final dataUrl = canvas.toDataUrl('image/jpeg', 0.85);
    final base64String = dataUrl.split(',').last;
    final bytes = base64Decode(base64String);

    _stopCamera();
    Navigator.pop(context, bytes); // 撮影したバイト列を返却
  }

  void _stopCamera() {
    if (_mediaStream != null) {
      for (final track in _mediaStream!.getTracks()) {
        track.stop();
      }
    }
  }

  @override
  void dispose() {
    _stopCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isInitialized)
            HtmlElementView(viewType: _viewId)
          else if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            ),

          // 上部閉じるボタン
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      _stopCamera();
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ),
          ),

          // 下部シャッターボタン
          if (_isInitialized)
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: GestureDetector(
                    onTap: _capturePhoto,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: Colors.white.withOpacity(0.3),
                      ),
                      child: Center(
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}