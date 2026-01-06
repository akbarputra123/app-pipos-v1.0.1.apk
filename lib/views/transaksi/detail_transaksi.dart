import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaksi_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DetailTransaksiPage extends ConsumerWidget {
  final TransaksiModel transaksi;

  const DetailTransaksiPage({super.key, required this.transaksi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    double totalDiskon = 0;

    for (final item in transaksi.items) {
      // ===== DISKON PERSENTASE =====
      if (item.discountType == 'percentage' && item.discountValue != null) {
        totalDiskon +=
            (item.price * item.quantity) * (item.discountValue! / 100);
      }

      // ===== DISKON BUY X GET Y (PAKAI BACKEND) =====
      if (item.discountType == 'buyxgety' &&
          item.notes != null &&
          item.notes!.contains('|')) {
        final parts = item.notes!.split('|');

        // notes = "lineTotal|discountAmount"
        if (parts.length == 2) {
          final discountAmount = double.tryParse(parts[1]) ?? 0;
          totalDiskon += discountAmount;
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

    String _itemSubtitle(item, NumberFormat currency) {
      if (item.discountType == 'buyxgety') {
        return "${item.quantity} x ${currency.format(item.price)} ";
      }

      if (item.discountType == 'percentage' && item.discountValue != null) {
        return "${item.quantity} x ${currency.format(item.price)} "
            "(Diskon ${item.discountValue!.toInt()}%)";
      }

      return "${item.quantity} x ${currency.format(item.price)}";
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        centerTitle: true,
        title: const Text("Detail Transaksi"),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: Divider(height: 2, thickness: 2, color: Colors.redAccent),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _infoCard("No. Transaksi", transaksi.transactionId ?? "-"),
                _infoCard("Tanggal & Waktu", transaksi.createdAt ?? "-"),
                _infoCard(
                  "Metode Pembayaran",
                  transaksi.paymentMethod.toLowerCase(),
                ),
                const SizedBox(height: 14),
                _card(
                  title: "Item Pembelian",
                  child: Column(
                    children: transaksi.items.map((item) {
                      final itemTotal = _calculateItemTotal(item);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// ================= NAMA PRODUK =================
                            Text(
                              item.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),

                            const SizedBox(height: 4),

                            /// ================= QTY x PRICE + PROMO =================
                            Text(
                              _itemSubtitle(item, currency),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),

                            const SizedBox(height: 6),

                            /// ================= TOTAL ITEM =================
                            Text(
                              currency.format(itemTotal),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),

                            const SizedBox(height: 10),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 14),

                /// ================= RINGKASAN =================
                _card(
                  child: Column(
                    children: [
                      _row(
                        "Sub Total",
                        currency.format(transaksi.subtotal ?? 0),
                      ),
                      _row(
                        "Total Diskon (Promo)",
                        currency.format(totalDiskon),
                      ),

                      _row(
                        "PPN (${transaksi.taxPercent ?? 0}%)",
                        currency.format(transaksi.taxAmount ?? 0),
                      ),
                      const Divider(color: Colors.redAccent),
                      _row(
                        "GRAND TOTAL",
                        currency.format(transaksi.total ?? 0),
                        bold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                /// ================= TUNAI & KEMBALIAN =================
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A1414),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: Column(
                    children: [
                      _row(
                        "Tunai Diterima",
                        currency.format(transaksi.receivedAmount),
                        light: true,
                      ),
                      _row(
                        "Kembalian",
                        currency.format(transaksi.change ?? 0),
                        light: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),

        ],
      ),
    );
  }

  /// ================= ITEM SUBTITLE =================
  String _itemSubtitle(item, NumberFormat currency) {
    if (item.discountType == 'buyxgety' && item.notes != null) {
      final parts = item.notes!.split('+');
      if (parts.length == 2) {
        return "${item.quantity} x ${currency.format(item.price)} (Buy${parts[0]}-Get${parts[1]})";
      }
    }
    if (item.discountType == 'percentage' && item.discountValue != null) {
      return "${item.quantity} x ${currency.format(item.price)} (${item.discountValue!.toInt()}%)";
    }
    return "${item.quantity} x ${currency.format(item.price)}";
  }

  /// ================= UI HELPERS =================
  Widget _infoCard(String title, String value) {
    return _card(
      title: title,
      child: Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _card({String? title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1C1C1C), Color(0xFF101010)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 8),
          ],
          child,
        ],
      ),
    );
  }

  Widget _row(
    String label,
    String value, {
    bool bold = false,
    bool light = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: light ? Colors.white : Colors.white70,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required Color color,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }
}
