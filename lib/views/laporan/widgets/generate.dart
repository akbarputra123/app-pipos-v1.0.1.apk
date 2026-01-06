import 'package:flutter/material.dart';

class GenerateReportBar extends StatelessWidget {
  const GenerateReportBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ElevatedButton.icon(
        onPressed: () {
          // nanti isi logic generate
        },
        icon: const Icon(Icons.refresh, size: 12),
        label: const Text(
          "Generate Laporan Harian",
          style: TextStyle(fontSize: 10),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE53935), // MERAH FIX
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE53935),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
