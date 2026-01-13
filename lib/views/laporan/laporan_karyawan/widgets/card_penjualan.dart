import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/laporan_model.dart';

/// =======================================================
/// SECTION: PERFORMA & PENJUALAN
/// =======================================================
class CardPenjualanSection extends StatelessWidget {
  final List<CashierPerformance> cashiers;

  const CardPenjualanSection({
    super.key,
    required this.cashiers,
  });

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
        childAspectRatio: 0.85,
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
          avatarText: '${index + 1}',
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
          avatarText: '${index + 1}',
          avatarColor: index == 0
              ? const Color(0xFFF9A825)
              : index == 1
                  ? Colors.grey
                  : Colors.blueGrey,
          name: c.name,
          role: c.role,
          value: rupiah.format(c.totalPenjualan),
          valueLabel: '${c.totalTransaksi} transaksi',
          valueColor: Theme.of(context).colorScheme.primary,
        );
      }).toList(),
    );
  }
}

/// =======================================================
/// BASE CARD (THEME AWARE)
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
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withOpacity(0.45)
                : Colors.black.withOpacity(0.08),
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
                Icon(icon, size: 14, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: theme.dividerColor),

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
/// ITEM TILE (THEME SAFE)
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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            /// AVATAR
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
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),

            /// INFO
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    role,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 9.5,
                      color: theme.textTheme.bodySmall?.color
                          ?.withOpacity(0.55),
                    ),
                  ),
                ],
              ),
            ),

            /// VALUE
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  ),
                ),
                Text(
                  valueLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    color: theme.textTheme.bodySmall?.color
                        ?.withOpacity(0.45),
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
