// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui' as ui;
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

      _videoElement!.setAttribute('playsinline', 'true');
      _videoElement!.setAttribute('webkit-playsinline', 'true');

      ui_web.platformViewRegistry.registerViewFactory(
        _viewId,
        (int id) => _videoElement!,
      );

      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        throw Exception('このブラウザはカメラアクセスをサポートしていません。');
      }

      final stream = await mediaDevices.getUserMedia({
        'video': {
          'facingMode': {'ideal': 'environment'},
          'width': {'ideal': 1920},
          'height': {'ideal': 1080},
        },
        'audio': false,
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

    // ★重要：枠でトリミングせず、フル解像度の全体をそのままキャプチャ！
    final canvas = html.CanvasElement(width: videoWidth, height: videoHeight);
    canvas.context2D.drawImage(_videoElement!, 0, 0);

    final dataUrl = canvas.toDataUrl('image/jpeg', 0.85);
    final base64String = dataUrl.split(',').last;
    final bytes = base64Decode(base64String);

    _stopCamera();
    Navigator.pop(context, bytes);
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
    final screenSize = MediaQuery.of(context).size;
    final frameWidth = screenSize.width * 0.76;
    final frameHeight = screenSize.height * 0.56;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. カメラプレビュー
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

          // 2. ★縦長点線ガイド枠 ＆ 案内テキスト（オーバーレイ）
          if (_isInitialized)
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 案内テキストバブル
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'レシートを枠内に合わせてください',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '※長いレシートは少し離して撮影してください',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 点線の縦長フレーム
                    CustomPaint(
                      size: Size(frameWidth, frameHeight),
                      painter: _DashedRRectPainter(
                        color: Colors.white.withOpacity(0.75),
                        strokeWidth: 2.0,
                        dashWidth: 8.0,
                        dashSpace: 6.0,
                        radius: 16.0,
                      ),
                    ),
                    const SizedBox(height: 70), // 下部シャッターボタンとの干渉避け
                  ],
                ),
              ),
            ),

          // 3. 左上閉じるボタン
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

          // 4. 下部シャッターボタン
          if (_isInitialized)
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
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

/// 滑らかな角丸の破線を描くカスタムペインター
class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double radius;

  _DashedRRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);

    for (final ui.PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = dashWidth;
        if (distance + length > metric.length) {
          canvas.drawPath(metric.extractPath(distance, metric.length), paint);
          break;
        }
        canvas.drawPath(metric.extractPath(distance, distance + length), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}