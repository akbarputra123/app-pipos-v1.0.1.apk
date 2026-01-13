import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../models/produk_model.dart';
import '../../../viewmodels/kelola_produk_viewmodel.dart';
import '../../../config/theme.dart';
import '../../../config/base_url.dart';

class CardProduk extends ConsumerWidget {
  final ProdukModel produk;
  final VoidCallback? onEdit;

  const CardProduk({
    super.key,
    required this.produk,
    this.onEdit,
  });

  Color getStockColor(int stock) {
    if (stock == 0) return Colors.red;
    if (stock < 5) return Colors.orange;
    if (stock < 50) return Colors.amber;
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

  /// =====================
  /// PROMO LABEL (FINAL - SUPPORT BUNDLE)
  /// =====================
  String getPromoLabel(ProdukModel p) {
    if (p.promoType == null) return "";

    // ⚠️ Formatter HARUS di dalam method (aman untuk ConsumerWidget)
    final rupiah = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    switch (p.promoType) {
      case "percentage":
      case "percent":
        return "${p.promoPercent?.toStringAsFixed(0)}% OFF";

      case "buyxgety":
      case "buy_get":
        return "Beli ${p.buyQty ?? 0} Gratis ${p.freeQty ?? 0}";

      case "bundle":
        final qty = p.bundleQty ?? 0;
        final price = p.bundleTotalPrice ?? 0;
        return "$qty pcs ${rupiah.format(price)}"; // 🇮🇩 FIX

      default:
        return "PROMO";
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.white;

    return Card(
      color: theme.cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.dividerColor,
          width: 1.2,
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /// ================= IMAGE =================
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary,
                      width: 2,
                    ),
                    color: theme.cardColor,
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
                  child: (produk.imageUrl == null ||
                          produk.imageUrl!.isEmpty)
                      ? Icon(
                          Icons.image_not_supported,
                          color: textColor.withOpacity(0.5),
                          size: 30,
                        )
                      : null,
                ),

                /// STOCK BADGE
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: getStockColor(produk.stock),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.scaffoldBackgroundColor,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      produk.stock.toString(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 12),

            /// ================= INFO =================
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// NAMA PRODUK
                  Text(
                    produk.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  /// KATEGORI
                  Text(
                    produk.category ?? "-",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),

                  const SizedBox(height: 4),

                  /// PRICE + PROMO
                  Row(
                    children: [
                      Text(
                        formatRupiah(produk.sellPrice),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (produk.promoType != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            getPromoLabel(produk), // 🔥 BUNDLE READY
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  /// ================= ADD BUTTON =================
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      if (produk.stock <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("${produk.name} stok habis"),
                            backgroundColor: Colors.redAccent,
                            duration:
                                const Duration(milliseconds: 800),
                          ),
                        );
                        return;
                      }

                      if (produk.qty + 1 > produk.stock) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Stok ${produk.name} tidak mencukupi",
                            ),
                            backgroundColor: Colors.orange,
                            duration:
                                const Duration(milliseconds: 800),
                          ),
                        );
                        return;
                      }

                      ref
                          .read(
                              kelolaProdukViewModelProvider.notifier)
                          .addToCart(produk);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text("${produk.name} ditambahkan"),
                          backgroundColor: Colors.green,
                          duration:
                              const Duration(milliseconds: 600),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.35),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.add_shopping_cart,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            produk.qty > 0
                                ? "Tambah (${produk.qty})"
                                : "Tambah",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
