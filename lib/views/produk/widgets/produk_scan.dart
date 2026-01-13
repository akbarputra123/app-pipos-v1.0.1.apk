import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';

class ProdukScanScreen extends StatefulWidget {
  const ProdukScanScreen({super.key});

  @override
  State<ProdukScanScreen> createState() => _ProdukScanScreenState();
}

class _ProdukScanScreenState extends State<ProdukScanScreen>
    with SingleTickerProviderStateMixin {
  bool _isDetecting = false;

  late final MobileScannerController _scannerController;
  late final AudioPlayer _audioPlayer;
  late final AnimationController _scanAnim;

  @override
  void initState() {
    super.initState();

    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );

    _audioPlayer = AudioPlayer()
      ..setPlayerMode(PlayerMode.lowLatency)
      ..setVolume(1.0);

    _scanAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _audioPlayer.dispose();
    _scanAnim.dispose();
    super.dispose();
  }

  Future<void> _playBeep() async {
    try {
      await _audioPlayer.play(AssetSource('beep.mp3'));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    final scanBoxSize = size.width * 0.7;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
        title: Text(
          "Scan Produk",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.cardColor, // ✅ ikut dark / light
        foregroundColor:
            theme.textTheme.titleMedium?.color, // teks & icon otomatis kontras
        elevation: 0,
        iconTheme: IconThemeData(color: theme.iconTheme.color, size: 26),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Divider(
            height: 2,
            thickness: 2,
            color: theme.colorScheme.primary, // aksen brand tetap
          ),
        ),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          /// ================= CAMERA =================
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) async {
              if (_isDetecting) return;
              if (capture.barcodes.isEmpty) return;

              final code = capture.barcodes.first.rawValue ?? '';
              if (code.isEmpty) return;

              _isDetecting = true;

              await _playBeep();

              if (!mounted) return;
              Navigator.pop(context, code);
            },
          ),

          /// ================= DARK MASK =================
          _ScannerOverlay(
            scanBoxSize: scanBoxSize,
            borderColor: theme.colorScheme.primary,
          ),

          /// ================= SCAN LINE =================
          Positioned(
            top: (size.height - scanBoxSize) / 2,
            child: AnimatedBuilder(
              animation: _scanAnim,
              builder: (_, __) {
                return Transform.translate(
                  offset: Offset(
                    0,
                    scanBoxSize * _scanAnim.value,
                  ),
                  child: Container(
                    width: scanBoxSize,
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          theme.colorScheme.primary,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          /// ================= TEXT =================
          Positioned(
            bottom: 32,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: theme.cardColor.withOpacity(0.85),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "Arahkan kamera ke barcode produk",
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// =======================================================
/// SCAN OVERLAY (MASK + BORDER)
/// =======================================================
class _ScannerOverlay extends StatelessWidget {
  final double scanBoxSize;
  final Color borderColor;

  const _ScannerOverlay({
    required this.scanBoxSize,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        /// MASK
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.55),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(color: Colors.black),
              Center(
                child: Container(
                  width: scanBoxSize,
                  height: scanBoxSize,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),

        /// BORDER
        Center(
          child: Container(
            width: scanBoxSize,
            height: scanBoxSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
