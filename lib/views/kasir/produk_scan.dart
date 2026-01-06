import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../config/theme.dart';

class ProdukScanScreen extends StatefulWidget {
  const ProdukScanScreen({super.key});

  @override
  State<ProdukScanScreen> createState() => _ProdukScanScreenState();
}

class _ProdukScanScreenState extends State<ProdukScanScreen> {
  bool _isDetecting = false;
  final MobileScannerController _controller = MobileScannerController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playBeep() async {
    try {
      debugPrint("🔊 Mencoba memutar beep...");

      await _audioPlayer.setVolume(1.0);
      _audioPlayer.play(AssetSource('beep.mp3'));

      debugPrint("✅ Audio dimainkan");
    } catch (e, st) {
      debugPrint("❌ Error saat memutar beep: $e");
      debugPrint("StackTrace: $st");
    }
  }

  @override
  Widget build(BuildContext context) {
    final AudioPlayer _audioPlayer = AudioPlayer()..setPlayerMode(PlayerMode.lowLatency);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: AppColors.primary,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) async {
              if (_isDetecting) return;
              final barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;

              final code = barcodes.first.rawValue ?? '';
              if (code.isNotEmpty) {
                _isDetecting = true;

                // mainkan beep dengan low latency
                _audioPlayer.play(AssetSource('beep.mp3'));

                // tunggu sebentar sebelum pop
                Future.delayed(const Duration(milliseconds: 200), () {
                  if (mounted) Navigator.pop(context, code);
                });
              }
            },
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.card.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Arahkan kamera ke barcode produk",
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
