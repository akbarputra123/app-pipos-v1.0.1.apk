import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaksi_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DetailTransaksiPage extends ConsumerWidget {
  final TransaksiModel transaksi;

  const DetailTransaksiPage({super.key, required this.transaksi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    double totalDiskon = 0;

    for (final item in transaksi.items) {
      if (item.discountType == 'percentage' && item.discountValue != null) {
        totalDiskon +=
            (item.price * item.quantity) * (item.discountValue! / 100);
      }

      if (item.discountType == 'buyxgety' &&
          item.notes != null &&
          item.notes!.contains('|')) {
        final parts = item.notes!.split('|');
        if (parts.length == 2) {
          totalDiskon += double.tryParse(parts[1]) ?? 0;
        }
      }
    }

    double _calculateItemTotal(item) {
      if (item.notes != null && item.notes!.contains('|')) {
        final parts = item.notes!.split('|');
        final lineTotal = double.tryParse(parts[0]);
        if (lineTotal != null) return lineTotal;
      }
      return item.price * item.quantity;
    }

    String _itemSubtitle(item) {
      if (item.discountType == 'buyxgety') {
        return "${item.quantity} x ${currency.format(item.price)}";
      }

      if (item.discountType == 'percentage' && item.discountValue != null) {
        return "${item.quantity} x ${currency.format(item.price)} "
            "(Diskon ${item.discountValue!.toInt()}%)";
      }

      return "${item.quantity} x ${currency.format(item.price)}";
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: const Text("Detail Transaksi"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Divider(
            height: 2,
            thickness: 2,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _infoCard(theme, "No. Transaksi", transaksi.transactionId ?? "-"),
          _infoCard(theme, "Tanggal & Waktu", transaksi.createdAt ?? "-"),
          _infoCard(
            theme,
            "Metode Pembayaran",
            transaksi.paymentMethod.toLowerCase(),
          ),

          const SizedBox(height: 14),

          _card(
            theme,
            title: "Item Pembelian",
            child: Column(
              children: transaksi.items.map((item) {
                final itemTotal = _calculateItemTotal(item);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _itemSubtitle(item),
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        currency.format(itemTotal),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 14),

          _card(
            theme,
            child: Column(
              children: [
                _row(theme, "Sub Total",
                    currency.format(transaksi.subtotal ?? 0)),
                _row(theme, "Total Diskon",
                    currency.format(totalDiskon)),
                _row(
                  theme,
                  "PPN (${transaksi.taxPercent ?? 0}%)",
                  currency.format(transaksi.taxAmount ?? 0),
                ),
                Divider(color: theme.dividerColor),
                _row(
                  theme,
                  "GRAND TOTAL",
                  currency.format(transaksi.total ?? 0),
                  bold: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.error),
            ),
            child: Column(
              children: [
                _row(
                  theme,
                  "Tunai Diterima",
                  currency.format(transaksi.receivedAmount),
                ),
                _row(
                  theme,
                  "Kembalian",
                  currency.format(transaksi.change ?? 0),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _infoCard(ThemeData theme, String title, String value) {
    return _card(
      theme,
      title: title,
      child: Text(
        value,
        style: theme.textTheme.bodyMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _card(
    ThemeData theme, {
    String? title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
          ],
          child,
        ],
      ),
    );
  }

  Widget _row(
    ThemeData theme,
    String label,
    String value, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
