import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/laporan_model.dart';

/// =======================================================
/// SECTION: PERFORMA & PENJUALAN
/// =======================================================
class CardPenjualanSection extends StatelessWidget {
  final List<CashierPerformance> cashiers;

  const CardPenjualanSection({super.key, required this.cashiers});

  @override
  Widget build(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85, // 🔒 TETAP
      ),
      children: [
        _PerformaKaryawanCard(cashiers: cashiers),
        _PenjualanTerbanyakCard(cashiers: cashiers),
      ],
    );
  }
}

class _PerformaKaryawanCard extends StatelessWidget {
  final List<CashierPerformance> cashiers;

  const _PerformaKaryawanCard({required this.cashiers});

  @override
  Widget build(BuildContext context) {
    final sorted = [...cashiers]
      ..sort((a, b) => b.totalTransaksi.compareTo(a.totalTransaksi));

    return _BaseCard(
      icon: Icons.emoji_events_outlined,
      title: 'Performa Karyawan',
      children: sorted.asMap().entries.map((entry) {
        final index = entry.key;
        final c = entry.value;

        return _ItemTile(
          avatarText: '${index + 1}', // 🏅 ranking
          avatarColor: index == 0
              ? const Color(0xFFF9A825)
              : index == 1
              ? Colors.grey
              : Colors.redAccent,
          name: c.name,
          role: c.role,
          value: c.totalTransaksi.toString(),
          valueLabel: 'Transaksi',
        );
      }).toList(),
    );
  }
}

class _PenjualanTerbanyakCard extends StatelessWidget {
  final List<CashierPerformance> cashiers;

  const _PenjualanTerbanyakCard({required this.cashiers});

  @override
  Widget build(BuildContext context) {
    final rupiah = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final sorted = [...cashiers]
      ..sort((a, b) => b.totalPenjualan.compareTo(a.totalPenjualan));

    return _BaseCard(
      icon: Icons.emoji_events,
      title: 'Penjualan Terbanyak',
      children: sorted.asMap().entries.map((entry) {
        final index = entry.key;
        final c = entry.value;

        return _ItemTile(
          avatarText: '${index + 1}', // 🏅 ranking
          avatarColor: index == 0
              ? const Color(0xFFF9A825)
              : index == 1
              ? Colors.grey
              : Colors.blueGrey,
          name: c.name,
          role: c.role,
          value: rupiah.format(c.totalPenjualan),
          valueLabel: '${c.totalTransaksi} transaksi',
          valueColor: Colors.redAccent,
        );
      }).toList(),
    );
  }
}

/// =======================================================
/// BASE CARD
/// =======================================================
class _BaseCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _BaseCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Icon(icon, size: 14, color: Colors.redAccent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.white.withOpacity(0.06)),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(children: children),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// =======================================================
/// ITEM TILE (COMPACT & AMAN)
/// =======================================================
class _ItemTile extends StatelessWidget {
  final String avatarText;
  final Color avatarColor;
  final String name;
  final String role;
  final String value;
  final String valueLabel;
  final Color valueColor;

  const _ItemTile({
    required this.avatarText,
    required this.avatarColor,
    required this.name,
    required this.role,
    required this.value,
    required this.valueLabel,
    this.valueColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: avatarColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                avatarText,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    role,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: Colors.white.withOpacity(0.55),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  ),
                ),
                Text(
                  valueLabel,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white.withOpacity(0.45),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
