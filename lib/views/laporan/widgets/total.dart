import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../viewmodels/laporan_viewmodel.dart';

class TotalSummary extends ConsumerWidget {
  const TotalSummary({super.key});

  @override
Widget build(BuildContext context, WidgetRef ref) {
  final summary = ref.watch(
    laporanViewModelProvider.select((s) => s.summary),
  );

  debugPrint(
    '🧩 [TotalSummary] build | summary = ${summary == null ? "NULL" : "ADA"}',
  );

  if (summary != null) {
    debugPrint(
      '📊 [TotalSummary] '
      'pendapatan=${summary.totalPendapatan}, '
      'transaksi=${summary.totalTransaksi}, '
      'margin=${summary.margin}',
    );
  }

  if (summary == null) {
    return const SizedBox(
      height: 72,
      child: Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  return Row(
    children: [
      Expanded(
        child: _TotalCard(
          title: "Total Pembayaran",
          value: _rupiah(summary.totalPendapatan),
          icon: Icons.payments_outlined,
          valueColor: Colors.white,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _TotalCard(
          title: "Transaksi",
          value: summary.totalTransaksi.toString(),
          icon: Icons.receipt_long,
          valueColor: Colors.white,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _TotalCard(
          title: "Margin",
          value: summary.margin,
          icon: Icons.trending_up,
          valueColor: const Color(0xFF3BCF9A),
        ),
      ),
    ],
  );
}


  /// ================= FORMAT RUPIAH =================
  String _rupiah(int value) {
    if (value >= 1000000) {
      return "Rp ${(value / 1000000).toStringAsFixed(1)} Jt";
    }
    if (value >= 1000) {
      return "Rp ${(value / 1000).toStringAsFixed(0)} Rb";
    }
    return "Rp $value";
  }
}

class _TotalCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color valueColor;

  const _TotalCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: Colors.redAccent),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
