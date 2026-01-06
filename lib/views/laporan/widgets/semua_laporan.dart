import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../viewmodels/laporan_viewmodel.dart';

class SemuaLaporan extends ConsumerWidget {
  const SemuaLaporan({super.key});

  String _rupiah(num value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(laporanViewModelProvider).summary;

    if (summary == null) {
      return const SizedBox.shrink();
    }

    final totalTransaksi = summary.totalTransaksi;
    final pendapatan = summary.totalPendapatan;
 
    final bersih = summary.netRevenue;
    final hpp = summary.totalHpp;
    final labaKotor = summary.grossProfit;
    // final labaBersih = summary.netProfit;
    // final margin = summary.margin;

    final avgPerTransaksi =
        totalTransaksi > 0 ? (pendapatan / totalTransaksi) : 0;

    return Column(
      children: [
        /// ================= GRID 2 KOLOM =================
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.0,
          ),
          children: [
            _LaporanCard(
              title: 'Total Pendapatan',
              value: _rupiah(pendapatan),
              subtitle: '$totalTransaksi transaksi',
              icon: Icons.bar_chart,
              iconColor: Colors.teal,
            ),
            
            _LaporanCard(
              title: 'Pendapatan Bersih',
              value: _rupiah(bersih),
              subtitle: 'Setelah diskon',
              icon: Icons.account_balance_wallet,
              iconColor: Colors.greenAccent,
              highlight: true,
            ),
            _LaporanCard(
              title: 'Modal / HPP',
              value: _rupiah(hpp),
              subtitle: 'Total modal',
              icon: Icons.shopping_cart,
              iconColor: Colors.cyan,
            ),
            _LaporanCard(
              title: 'Laba Kotor',
              value: _rupiah(labaKotor),
              subtitle: 'Pendapatan - HPP',
              icon: Icons.trending_up,
              iconColor: Colors.green,
            ),
            // _LaporanCard(
            //   title: 'Laba Bersih',
            //   value: _rupiah(labaBersih),
            //   subtitle: 'Margin $margin',
            //   icon: Icons.savings,
            //   iconColor: Colors.green,
            // ),
          ],
        ),



        const SizedBox(height: 12),
        /// ================= FULL WIDTH CARD =================
        _LaporanCard(
          title: 'Rata-rata Transaksi',
          value: _rupiah(avgPerTransaksi),
          subtitle: 'Per transaksi',
          icon: Icons.receipt_long,
          iconColor: Colors.orange,
          isWide: true,
        ),
      ],
    );
  }
}

/// ================= CARD =================
class _LaporanCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool highlight;
  final bool isWide;

  const _LaporanCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.highlight = false,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: isWide ? EdgeInsets.zero : null,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight ? Colors.redAccent : Colors.transparent,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
