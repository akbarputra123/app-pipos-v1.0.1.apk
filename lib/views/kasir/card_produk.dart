import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/produk_model.dart';
import '../../config/theme.dart';
import '../../config/base_url.dart';
import '../../viewmodels/kelola_produk_viewmodel.dart';
import 'package:intl/intl.dart';

class CardProduk extends ConsumerWidget {
  final ProdukModel produk;
  final VoidCallback? onEdit;
  const CardProduk({super.key, required this.produk, this.onEdit});

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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Card(
          color: AppColors.card.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.cardSoft, width: 1.5),
          ),
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Gambar produk
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
                        image:
                            produk.imageUrl != null &&
                                produk.imageUrl!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(
                                  "${BaseUrl.api}/${produk.imageUrl}",
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: produk.imageUrl == null || produk.imageUrl!.isEmpty
                          ? const Icon(
                              Icons.image_not_supported,
                              color: Colors.white54,
                              size: 30,
                            )
                          : null,
                    ),
                    // Stock indicator di pojok kanan atas gambar
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: getStockColor(produk.stock),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
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

                // Info produk
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        produk.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        produk.category ?? "-",
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            formatRupiah(produk.sellPrice),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Promo
                          if (produk.promoType != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
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
                      const SizedBox(height: 8),
                      // Tombol Tambah
                      InkWell(
                        onTap: () {
                          if (produk.stock == 0) {
                            // Kalau stok habis
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("${produk.name} stok habis"),
                                backgroundColor: Colors.redAccent,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                            return; // keluar dari fungsi
                          }

                          if (produk.qty > 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "${produk.name} sudah ditambahkan",
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          } else {
                            ref
                                .read(kelolaProdukViewModelProvider.notifier)
                                .addToCart(produk);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "${produk.name} ditambahkan ke keranjang",
                                ),
                                backgroundColor:
                                    Colors.green, // <-- ini untuk warna hijau
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        },

                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: produk.qty > 0
                                ? Colors.grey
                                : AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.5),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            produk.qty > 0 ? "Sudah Ditambahkan" : "Tambah",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Stock indicator
      ],
    );
  }
}
