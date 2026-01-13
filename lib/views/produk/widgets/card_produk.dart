import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/produk_model.dart';
import '../../../config/theme.dart';
import '../../../config/base_url.dart';
import '../../../viewmodels/kelola_produk_viewmodel.dart';
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
    if (stock == 0) return AppColors.danger;
    if (stock < 5) return AppColors.warning;
    if (stock < 50) return Colors.orange;
    return AppColors.success;
  }

  String formatRupiah(double price) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatCurrency.format(price);
  }
 

String getPromoLabel(ProdukModel p) {
  if (p.promoType == null) return "";

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

    return Card(
      color: theme.cardColor,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor, width: 1.5),
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
                  child: produk.imageUrl == null ||
                          produk.imageUrl!.isEmpty
                      ? Icon(
                          Icons.image_not_supported,
                          color: theme.iconTheme.color?.withOpacity(0.6),
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
                      border: Border.all(
                        color: theme.scaffoldBackgroundColor,
                        width: 1.5,
                      ),
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
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    produk.category ?? "-",
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: theme.textTheme.bodySmall?.color
                          ?.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        formatRupiah(produk.sellPrice),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 6),

                      /// ===== PROMO BADGE =====
                      if (produk.promoType != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            getPromoLabel(produk),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 6,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            /// ===== ACTION (ADMIN ONLY) =====
            if (!isCashier)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _icon(
                    icon: Icons.edit,
                    color: AppColors.primary,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProdukScreen(produk: produk),
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
                    color: AppColors.danger,
                    onTap: () {
                      showHapusProdukDialog(
                        context: context,
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
                          builder: (_) => CetakBarcodePage(produk: produk),
                        ),
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

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
          size: 18,
          color: color,
        ),
      ),
    );
  }
}
