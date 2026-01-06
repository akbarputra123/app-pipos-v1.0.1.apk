import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/kelola_produk_viewmodel.dart';
import '../../config/theme.dart';
import '../../config/base_url.dart';
import 'transaksi_produk.dart';
import 'package:intl/intl.dart';

class CartProdukScreen extends ConsumerStatefulWidget {
  final bool embedded;

  const CartProdukScreen({
    super.key,
    this.embedded = false,
  });

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
    if (produk.promoType == "buyxgety" || produk.promoType == "buy_get") {
      return produk.qty * produk.sellPrice;
    }

    if (produk.promoType == "percentage") {
      return produk.qty *
          produk.sellPrice *
          (1 - (produk.promoPercent ?? 0) / 100);
    }

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
  /// 🔥 HAPUS ITEM TERPILIH
  /// ===============================
  void _hapusTerpilih(List cartItems) {
    final selected = cartItems
        .where((p) => selectedItems[p.id] ?? false)
        .toList();

    if (selected.isEmpty) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus Item Terpilih"),
        content: Text(
          "Yakin ingin menghapus ${selected.length} item yang dipilih?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
              Navigator.pop(context);
            },
            child: const Text(
              "Hapus",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// ===============================
  /// 🔥 KOSONGKAN CART
  /// ===============================
  void _kosongkanCart(List cartItems) {
    if (cartItems.isEmpty) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Kosongkan Keranjang"),
        content: const Text(
          "Semua produk di keranjang akan dihapus. Lanjutkan?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
              Navigator.pop(context);
            },
            child: const Text(
              "Kosongkan",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
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

    final selectedCount =
        cartItems.where((p) => selectedItems[p.id] ?? false).length;

    /// ===============================
    /// CONTENT ASLI (TIDAK DIUBAH)
    /// ===============================
    Widget content = Column(
      children: [
        Expanded(
          child: cartItems.isEmpty
              ? const Center(
                  child: Text(
                    "Belum ada produk di keranjang",
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final produk = cartItems[index];
                    final isSelected = selectedItems[produk.id] ?? false;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      color: AppColors.card.withOpacity(0.9),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            Checkbox(
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  selectedItems[produk.id] = value ?? false;
                                });
                              },
                            ),
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.primary,
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
                                  ? const Icon(
                                      Icons.image_not_supported,
                                      color: Colors.white54,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    produk.name,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    "Harga: Rp ${formatRupiah.format(produk.sellPrice)}",
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (produk.promoType == "percentage")
                                    Text(
                                      "Diskon: ${produk.promoPercent?.toStringAsFixed(0) ?? 0}%",
                                      style: const TextStyle(
                                        color: Colors.greenAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  if (produk.promoType == "buyxgety" ||
                                      produk.promoType == "buy_get")
                                    Text(
                                      "Promo: Buy ${produk.buyQty ?? 0} Get ${produk.freeQty ?? 0}",
                                      style: const TextStyle(
                                        color: Colors.greenAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  Text(
                                    "Stok: ${produk.stock}",
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        if (produk.qty > 1) {
                                          ref
                                              .read(
                                                kelolaProdukViewModelProvider
                                                    .notifier,
                                              )
                                              .decreaseQty(produk);
                                        }
                                      },
                                      icon: const Icon(Icons.remove),
                                    ),
                                    Text("${produk.qty}"),
                                    IconButton(
                                      onPressed: () {
                                        ref
                                            .read(
                                              kelolaProdukViewModelProvider
                                                  .notifier,
                                            )
                                            .increaseQty(produk);
                                      },
                                      icon: const Icon(Icons.add),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  onPressed: () {
                                    ref
                                        .read(
                                          kelolaProdukViewModelProvider
                                              .notifier,
                                        )
                                        .removeFromCart(produk);
                                    selectedItems.remove(produk.id);
                                  },
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                  ),
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

        /// ================= TOTAL & BAYAR (ASLI)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card.withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              _row("Total Item", cartItems.length.toString()),
              _row(
                "Total Harga",
                "Rp ${formatRupiah.format(totalPriceBeforePromo)}",
              ),
              _row(
                "Total Setelah Promo",
                "Rp ${formatRupiah.format(totalPriceAfterPromo)}",
                highlight: true,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) =>
                          const TransaksiProdukBottomSheet(),
                    );
                  },
                  child: const Text(
                    "Bayar",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
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
                      icon: const Icon(Icons.delete_forever,
                          color: Colors.redAccent),
                      onPressed: () => _hapusTerpilih(cartItems),
                    ),
                  IconButton(
                    icon: const Icon(Icons.clear_all,
                        color: Colors.orangeAccent),
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
        backgroundColor: AppColors.primary,
        title: const Text("Keranjang Produk"),
        actions: [
          if (selectedCount > 0)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: () => _hapusTerpilih(cartItems),
            ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () => _kosongkanCart(cartItems),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: content,
    );
  }

  Widget _row(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(
            value,
            style: TextStyle(
              color: highlight ? Colors.greenAccent : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
