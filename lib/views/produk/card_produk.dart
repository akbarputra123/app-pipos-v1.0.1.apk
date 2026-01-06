import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/produk_model.dart';
import '../../config/theme.dart';
import '../../config/base_url.dart';
import '../../viewmodels/kelola_produk_viewmodel.dart';
import 'package:intl/intl.dart';
import 'edit_produk.dart';
import 'cetak_barcode.dart';
import 'hapus_produk.dart';

class CardProduk extends ConsumerWidget {
  final ProdukModel produk;
  final bool isCashier;

  const CardProduk({
    super.key,
    required this.produk,
    required this.isCashier,
  });

  Color getStockColor(int stock) {
    if (stock == 0) return Colors.red;
    if (stock < 5) return Colors.yellow;
    if (stock < 50) return Colors.orange;
    return Colors.green;
  }

  String formatRupiah(double price) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatCurrency.format(price);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: AppColors.card.withOpacity(0.95),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.cardSoft, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /// ===== IMAGE + STOCK =====
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary, width: 2),
                    color: AppColors.card.withOpacity(0.5),
                    image: produk.imageUrl != null &&
                            produk.imageUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(
                              "${BaseUrl.api}/${produk.imageUrl}",
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: produk.imageUrl == null ||
                          produk.imageUrl!.isEmpty
                      ? const Icon(
                          Icons.image_not_supported,
                          color: Colors.white54,
                          size: 30,
                        )
                      : null,
                ),
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: getStockColor(produk.stock),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      produk.stock.toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 12),

            /// ===== INFO PRODUK =====
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    produk.name,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    produk.category ?? "-",
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        formatRupiah(produk.sellPrice),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (produk.promoType != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child:  Text(
                                produk.promoType == "percentage" ||
                                        produk.promoType == "percent"
                                    ? "${produk.promoPercent?.toStringAsFixed(0)}% OFF"
                                    : produk.promoType == "buyxgety" ||
                                          produk.promoType == "buy_get"
                                    ? "Beli ${produk.buyQty ?? 0} Gratis ${produk.freeQty ?? 0}"
                                    : "PROMO",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            /// ===== ACTION ICONS (RAPAT & NEMPEL KANAN) =====
            if (!isCashier)
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _icon(
                      icon: Icons.edit,
                      color: AppColors.primary,
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EditProdukScreen(produk: produk),
                          ),
                        );
                        if (result == true) {
                          ref
                              .read(kelolaProdukViewModelProvider.notifier)
                              .getProduk();
                        }
                      },
                    ),
                    _icon(
                      icon: Icons.delete,
                      color: Colors.redAccent,
                      onTap: () {
                        showHapusProdukDialog(
                          context: Scaffold.of(context).context,
                          ref: ref,
                          produk: produk,
                        );
                      },
                    ),
                    _icon(
                      icon: Icons.qr_code,
                      color: Colors.blueAccent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CetakBarcodePage(produk: produk),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// ===== ICON HELPER (PALING RAPAT & RINGAN) =====
  Widget _icon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Icon(
          icon,
          size: 20,
          color: color,
        ),
      ),
    );
  }
}
