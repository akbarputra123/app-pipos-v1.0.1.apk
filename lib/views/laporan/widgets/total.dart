import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../viewmodels/laporan_viewmodel.dart';

class TotalSummary extends ConsumerWidget {
  const TotalSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final summary = ref.watch(
      laporanViewModelProvider.select((s) => s.summary),
    );

    debugPrint(
      '🧩 [TotalSummary] build | summary = ${summary == null ? "NULL" : "ADA"}',
    );

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
        accentColor: Colors.red, // 🔴
      ),
    ),
    const SizedBox(width: 8),
    Expanded(
      child: _TotalCard(
        title: "Transaksi",
        value: summary.totalTransaksi.toString(),
        icon: Icons.receipt_long,
        accentColor: Colors.green, // 🟢
      ),
    ),
    const SizedBox(width: 8),
    Expanded(
      child: _TotalCard(
        title: "Margin",
        value: summary.margin,
        icon: Icons.trending_up,
        accentColor: Colors.blue, // 🔵
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
  final Color accentColor;

  const _TotalCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor, // ✅ theme aware
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withOpacity(0.9),
          width: 1.6,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          /// TITLE + ICON
          Row(
            children: [
              Icon(
                icon,
                size: 12,
                color: accentColor,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: accentColor.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          /// VALUE
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
