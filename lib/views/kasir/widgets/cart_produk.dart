import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../viewmodels/kelola_produk_viewmodel.dart';
import '../../../config/theme.dart';
import '../../../config/base_url.dart';
import 'transaksi_produk.dart';
import 'package:intl/intl.dart';

class CartProdukScreen extends ConsumerStatefulWidget {
  final bool embedded;

  const CartProdukScreen({super.key, this.embedded = false});

  @override
  ConsumerState<CartProdukScreen> createState() => _CartProdukScreenState();
}

class _CartProdukScreenState extends ConsumerState<CartProdukScreen> {
  final Map<int, bool> selectedItems = {};

  final formatRupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: '',
    decimalDigits: 0,
  );

 double getPriceAfterDiscount(produk) {
  // ===== BUY X GET Y =====
  if (produk.promoType == "buyxgety" || produk.promoType == "buy_get") {
    return produk.qty * produk.sellPrice;
  }

  // ===== PERCENTAGE =====
  if (produk.promoType == "percentage") {
    return produk.qty *
        produk.sellPrice *
        (1 - (produk.promoPercent ?? 0) / 100);
  }

  // ===== 🔥 BUNDLE =====
  if (produk.promoType == "bundle" &&
      produk.bundleQty != null &&
      produk.bundleTotalPrice != null) {
    final bundleQty = produk.bundleQty!;
    final bundlePrice = produk.bundleTotalPrice!;

    final bundleCount = produk.qty ~/ bundleQty;
    final sisa = produk.qty % bundleQty;

    final totalBundlePrice = bundleCount * bundlePrice;
    final sisaPrice = sisa * produk.sellPrice;

    return totalBundlePrice + sisaPrice;
  }

  // ===== NORMAL =====
  return produk.qty * produk.sellPrice;
}


  Map<String, int> getPaidAndBonusQty(produk) {
    int paidQty = produk.qty;
    int bonusQty = 0;

    if (produk.promoType == "buyxgety" || produk.promoType == "buy_get") {
      final x = produk.buyQty ?? 0;
      final y = produk.freeQty ?? 0;
      bonusQty = (produk.qty ~/ x) * y;
    }

    return {'paid': paidQty, 'bonus': bonusQty};
  }

  /// ===============================
/// 🔥 HAPUS ITEM TERPILIH (DARK / LIGHT SAFE)
/// ===============================
void _hapusTerpilih(List cartItems) {
  final selected = cartItems
      .where((p) => selectedItems[p.id] ?? false)
      .toList();

  if (selected.isEmpty) return;

  showDialog(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);

      return AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          "Hapus Item Terpilih",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Yakin ingin menghapus ${selected.length} item yang dipilih?",
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: theme.textTheme.bodyMedium?.color,
            ),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              for (var p in selected) {
                ref
                    .read(kelolaProdukViewModelProvider.notifier)
                    .removeFromCart(p);
                selectedItems.remove(p.id);
              }
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error, // 🔴 merah theme
            ),
            child: const Text("Hapus"),
          ),
        ],
      );
    },
  );
}

/// ===============================
/// 🔥 KOSONGKAN CART (DARK / LIGHT SAFE)
/// ===============================
void _kosongkanCart(List cartItems) {
  if (cartItems.isEmpty) return;

  showDialog(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);

      return AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          "Kosongkan Keranjang",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Semua produk di keranjang akan dihapus. Lanjutkan?",
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: theme.textTheme.bodyMedium?.color,
            ),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              for (var p in cartItems) {
                ref
                    .read(kelolaProdukViewModelProvider.notifier)
                    .removeFromCart(p);
              }
              selectedItems.clear();
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error, // 🔴 merah theme
            ),
            child: const Text("Kosongkan"),
          ),
        ],
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kelolaProdukViewModelProvider);
    final cartItems = state.products.where((p) => p.qty > 0).toList();

    double totalPriceBeforePromo = cartItems.fold(
      0,
      (prev, produk) => prev + (produk.sellPrice * produk.qty),
    );

    double totalPriceAfterPromo = cartItems.fold(
      0,
      (prev, produk) => prev + getPriceAfterDiscount(produk),
    );

    final selectedCount = cartItems
        .where((p) => selectedItems[p.id] ?? false)
        .length;

    /// ===============================
    /// CONTENT ASLI (TIDAK DIUBAH)
    /// ===============================
    Widget content = Column(
      children: [
       Expanded(
  child: cartItems.isEmpty
      ? Center(
          child: Text(
            "Belum ada produk di keranjang",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.6),
                ),
          ),
        )
      : ListView.builder(
          itemCount: cartItems.length,
          padding: const EdgeInsets.only(bottom: 100),
          itemBuilder: (context, index) {
            final produk = cartItems[index];
            final isSelected = selectedItems[produk.id] ?? false;
            final theme = Theme.of(context);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              color: theme.cardColor,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Checkbox(
                      value: isSelected,
                      activeColor: theme.colorScheme.primary,
                      onChanged: (value) {
                        setState(() {
                          selectedItems[produk.id] = value ?? false;
                        });
                      },
                    ),

                    /// IMAGE
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.primary,
                          width: 1.5,
                        ),
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
                              color: theme.iconTheme.color?.withOpacity(0.5),
                            )
                          : null,
                    ),

                    const SizedBox(width: 10),

                    /// INFO
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            produk.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            "Harga: Rp ${formatRupiah.format(produk.sellPrice)}",
                            style: theme.textTheme.bodySmall,
                          ),

                          if (produk.promoType == "percentage")
                            Text(
                              "Diskon: ${produk.promoPercent?.toStringAsFixed(0) ?? 0}%",
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),

                          if (produk.promoType == "buyxgety" ||
                              produk.promoType == "buy_get")
                            Text(
                              "Promo: Buy ${produk.buyQty ?? 0} Get ${produk.freeQty ?? 0}",
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            if (produk.promoType == "bundle")
  Text(
    "Bundle: ${produk.bundleQty} pcs = Rp ${formatRupiah.format(produk.bundleTotalPrice ?? 0)}",
    style: const TextStyle(
      color: Colors.green,
      fontWeight: FontWeight.bold,
      fontSize: 12,
    ),
  ),


                          Text(
                            "Stok: ${produk.stock}",
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),

                    /// ACTION
                    Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove,
                                  color: theme.iconTheme.color),
                              onPressed: () {
                                if (produk.qty > 1) {
                                  ref
                                      .read(
                                          kelolaProdukViewModelProvider
                                              .notifier)
                                      .decreaseQty(produk);
                                }
                              },
                            ),
                            Text(
                              "${produk.qty}",
                              style: theme.textTheme.bodyMedium,
                            ),
                            IconButton(
                              icon: Icon(Icons.add,
                                  color: theme.iconTheme.color),
                              onPressed: () {
                                ref
                                    .read(
                                        kelolaProdukViewModelProvider
                                            .notifier)
                                    .increaseQty(produk);
                              },
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete,
                            color: theme.colorScheme.error,
                          ),
                          onPressed: () {
                            ref
                                .read(kelolaProdukViewModelProvider.notifier)
                                .removeFromCart(produk);
                            selectedItems.remove(produk.id);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
),


 /// ================= TOTAL & BAYAR =================
Transform.translate(
  offset: const Offset(0, -40), // ⬅️ posisi tetap
  child: Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor.withOpacity(0.95), // ✅ ikut theme
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(20),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(
            Theme.of(context).brightness == Brightness.dark ? 0.6 : 0.15,
          ),
          blurRadius: 8,
          offset: const Offset(0, -2),
        ),
      ],
    ),
    child: Column(
      children: [
        _row(
          context,
          "Total Item",
          cartItems.length.toString(),
        ),
        _row(
          context,
          "Total Harga",
          "Rp ${formatRupiah.format(totalPriceBeforePromo)}",
        ),
        _row(
          context,
          "Total Setelah Promo",
          "Rp ${formatRupiah.format(totalPriceAfterPromo)}",
          highlight: true, // 🔥 HIJAU TETAP
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, // 🔴 brand tetap
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const TransaksiProdukBottomSheet(),
              );
            },
            child: const Text(
              "Bayar",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    ),
  ),
),


      ],
    );

    /// ===============================
    /// MODE TABLET (PANEL)
    /// ===============================
    if (widget.embedded) {
      return SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Keranjang Produk",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (selectedCount > 0)
                    IconButton(
                      icon: const Icon(
                        Icons.delete_forever,
                        color: Colors.redAccent,
                      ),
                      onPressed: () => _hapusTerpilih(cartItems),
                    ),
                  IconButton(
                    icon: const Icon(
                      Icons.clear_all,
                      color: Colors.orangeAccent,
                    ),
                    onPressed: () => _kosongkanCart(cartItems),
                  ),
                ],
              ),
            ),
            Expanded(child: content),
          ],
        ),
      );
    }

    /// ===============================
    /// MODE HP (FULLSCREEN)
    /// ===============================
    return Scaffold(
     appBar: AppBar(
  elevation: 0,
  backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
      Theme.of(context).scaffoldBackgroundColor,
  foregroundColor: Theme.of(context).appBarTheme.foregroundColor ??
      Theme.of(context).textTheme.titleLarge?.color,
  title: Text(
    "Keranjang Produk",
    style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
  ),

  /// 🔴 GARIS BAWAH MERAH
  bottom: const PreferredSize(
    preferredSize: Size.fromHeight(2),
    child: Divider(
      height: 2,
      thickness: 2,
      color: Colors.red,
    ),
  ),

  actions: [
    if (selectedCount > 0)
      IconButton(
        tooltip: "Hapus Terpilih",
        icon: Icon(
          Icons.delete_forever,
          color: Theme.of(context).colorScheme.error,
        ),
        onPressed: () => _hapusTerpilih(cartItems),
      ),
    IconButton(
      tooltip: "Kosongkan Keranjang",
      icon: Icon(
        Icons.clear_all,
        color: Theme.of(context).iconTheme.color,
      ),
      onPressed: () => _kosongkanCart(cartItems),
    ),
  ],
),

      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: content,
    );
  }

 Widget _row(
  BuildContext context,
  String label,
  String value, {
  bool highlight = false,
}) {
  final theme = Theme.of(context);

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: highlight
                ? Colors.greenAccent // 🔥 TIDAK DIUBAH
                : theme.textTheme.bodyMedium?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

}
