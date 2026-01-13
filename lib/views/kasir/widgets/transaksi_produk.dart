import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../../viewmodels/kelola_produk_viewmodel.dart';
import '../../../viewmodels/transaksi_viewmodel.dart';
import '../../../config/theme.dart';
import '../../../models/produk_model.dart';
import '../../../viewmodels/profile_viewmodel.dart';

class TransaksiProdukBottomSheet extends ConsumerStatefulWidget {
  const TransaksiProdukBottomSheet({super.key});

  @override
  ConsumerState<TransaksiProdukBottomSheet> createState() =>
      _TransaksiProdukBottomSheetState();
}

class _TransaksiProdukBottomSheetState
    extends ConsumerState<TransaksiProdukBottomSheet> {
  final TextEditingController uangController = TextEditingController();
  double kembalian = 0.0;
  bool isUangKurang = false;
  double taxPercentage = 0.0;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _uangFocus = FocusNode();

  final formatRupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: '',
    decimalDigits: 0,
  );

  @override
  void dispose() {
    uangController.dispose();
    super.dispose();
    _uangFocus.dispose(); // 🔥 WAJIB
    _scrollController.dispose(); //
  }

  @override
  void initState() {
    super.initState();

    /// 🔥 AUTO SCROLL SAAT TEXTFIELD FOCUS
    _uangFocus.addListener(() {
      if (_uangFocus.hasFocus) {
        // trigger 2x untuk amankan keyboard Android & iOS
        Future.delayed(const Duration(milliseconds: 200), _scrollToBottom);
        Future.delayed(const Duration(milliseconds: 450), _scrollToBottom);
      }
    });

    /// Ambil PPN dari profile
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final profileVM = ref.read(profileViewModelProvider.notifier);
      final tax = await profileVM.fetchTaxPercentage();
      if (mounted) {
        setState(() {
          taxPercentage = tax;
        });
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      final position = _scrollController.position;
      _scrollController.animateTo(
        position.maxScrollExtent + 120, // 🔥 ekstra biar benar-benar mentok
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  double getPriceAfterDiscount(ProdukModel produk) {
    // ===== PERCENTAGE =====
    if (produk.promoType == "percentage" || produk.promoType == "percent") {
      final priceAfter =
          produk.sellPrice * (1 - (produk.promoPercent ?? 0) / 100);
      return priceAfter * produk.qty;
    }

    // ===== BUY X GET Y =====
    if (produk.promoType == "buyxgety" || produk.promoType == "buy_get") {
      final x = produk.buyQty ?? 0;
      final y = produk.freeQty ?? 0;
      if (x <= 0) return produk.qty * produk.sellPrice;

      final group = x + y;
      final paidQty = (produk.qty ~/ group) * x + (produk.qty % group);
      return paidQty * produk.sellPrice;
    }

    // ===== 🔥 BUNDLE =====
    if (produk.promoType == "bundle" &&
        produk.bundleQty != null &&
        produk.bundleTotalPrice != null) {
      final bundleQty = produk.bundleQty!;
      final bundlePrice = produk.bundleTotalPrice!;

      final bundleCount = produk.qty ~/ bundleQty;
      final sisaQty = produk.qty % bundleQty;

      final bundleTotal = bundleCount * bundlePrice;
      final sisaTotal = sisaQty * produk.sellPrice;

      return bundleTotal + sisaTotal;
    }

    // ===== NORMAL =====
    return produk.qty * produk.sellPrice;
  }

  // Hitung total harga termasuk promo & PPN
  double getTotalPriceWithTax(List<ProdukModel> cartItems) {
    double subtotal = cartItems.fold(
      0,
      (prev, produk) => prev + getPriceAfterDiscount(produk),
    );
    double taxAmount = subtotal * (taxPercentage / 100);
    return subtotal + taxAmount;
  }

  // Hitung total produk
  int getTotalProduk(List<ProdukModel> cartItems) {
    return cartItems.fold<int>(0, (prev, produk) => prev + produk.qty);
  }

  Map<String, dynamic> _mapProdukToPayload(ProdukModel produk) {
    final Map<String, dynamic> item = {
      "product_id": produk.id,
      "quantity": produk.qty,
    };

    if (produk.promoType != null) {
      // NORMALISASI NAMA DISKON
      if (produk.promoType == "percentage" || produk.promoType == "percent") {
        item["discount_type"] = "percentage";
        item["discount_value"] = (produk.promoPercent ?? 0).toDouble();
      }

      if (produk.promoType == "buyxgety" || produk.promoType == "buy_get") {
        item["discount_type"] = "buyxgety";
        item["buy_qty"] = produk.buyQty ?? 0;
        item["free_qty"] = produk.freeQty ?? 0;
      }
    }

    print("🧾 PAYLOAD ITEM => $item");
    return item;
  }

  Map<String, int> getQtyDisplay(ProdukModel produk) {
    int paid = produk.qty;
    int bonus = 0;

    if (produk.promoType == "buyxgety" || produk.promoType == "buy_get") {
      final x = produk.buyQty ?? 0;
      final y = produk.freeQty ?? 0;

      if (x > 0 && y > 0) {
        final group = x + y;
        final totalGroup = produk.qty ~/ group;

        paid = totalGroup * x + (produk.qty % group);
        bonus = totalGroup * y;
      }
    }

    return {"paid": paid, "bonus": bonus};
  }

  void calculateKembalian(double total) {
    final uangStr = uangController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final uang = double.tryParse(uangStr) ?? 0.0;

    setState(() {
      kembalian = uang - total;
      isUangKurang = uang < total;
    });
  }

  void pilihNominal(double nominal, double total) {
    final formatted = formatRupiah.format(nominal);

    uangController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );

    calculateKembalian(total);
  }

  void onUangChanged(String value, double total) {
    String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) digits = '0';

    double amount = double.parse(digits);
    uangController.value = TextEditingValue(
      text: formatRupiah.format(amount),
      selection: TextSelection.collapsed(
        offset: formatRupiah.format(amount).length,
      ),
    );

    calculateKembalian(total);
  }

  Future<void> bayar(List<ProdukModel> cartItems) async {
    final uangStr = uangController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final received = double.tryParse(uangStr) ?? 0.0;

    if (received <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Masukkan jumlah uang pelanggan")),
      );
      return;
    }

    // ================= HITUNG FINAL DI SINI =================
    final subtotal = cartItems.fold<double>(
      0,
      (sum, p) => sum + getPriceAfterDiscount(p),
    );

    final taxAmount = subtotal * (taxPercentage / 100);
    final total = subtotal + taxAmount;
    final change = received - total;

    if (change < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Uang pelanggan kurang")));
      return;
    }

    // ================= TUTUP BOTTOM SHEET =================
    Navigator.of(context).pop();

    // ================= SUBMIT SNAPSHOT =================
    await ref
        .read(transaksiViewModelProvider.notifier)
        .submitTransaction(
          cartItems: cartItems,
          receivedAmount: received,
          subtotal: subtotal,
          taxPercent: taxPercentage,
          taxAmount: taxAmount,
          total: total,
          change: change,
        );

    ref.read(kelolaProdukViewModelProvider.notifier).clearCart();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kelolaProdukViewModelProvider);
    final cartItems = state.products.where((p) => p.qty > 0).toList();

    // Hitung total
    final totalPrice = getTotalPriceWithTax(cartItems);
    final subtotal = cartItems.fold(
      0.0,
      (prev, produk) => prev + getPriceAfterDiscount(produk),
    );

    final totalProduk = getTotalProduk(cartItems);

    final transaksiState = ref.watch(transaksiViewModelProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // ✅ ikut light/dark
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.6 : 0.15,
            ),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.75,
      child: SingleChildScrollView(
        controller: _scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ================= HEADER =================
            Center(
              child: Container(
                width: 60,
                height: 6,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).dividerColor.withOpacity(0.6), // ✅ theme aware
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Center(
              child: Text(
                "Detail Transaksi",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),

            /// ================= RINGKASAN =================
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total Item: ${cartItems.length}",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    "Total Produk: $totalProduk",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                  Divider(color: Theme.of(context).dividerColor),
                  Text(
                    "Subtotal: Rp ${formatRupiah.format(subtotal)}",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    "PPN (${taxPercentage.toStringAsFixed(0)}%): Rp ${formatRupiah.format(totalPrice - subtotal)}",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Divider(color: Theme.of(context).dividerColor),
                ],
              ),
            ),

            const SizedBox(height: 12),

            /// ================= DAFTAR ITEM =================
            if (cartItems.isEmpty)
              Center(
                child: Text(
                  "Belum ada produk yang dibeli",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else
              ...cartItems.map((produk) {
                final qtyInfo = getQtyDisplay(produk);
                final subtotalItem = getPriceAfterDiscount(produk);

                return Card(
                  color: Theme.of(context).cardColor.withOpacity(0.9),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          produk.name,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (produk.promoType == "buyxgety" ||
                                produk.promoType == "buy_get")
                              Text(
                                "Jumlah: ${qtyInfo['paid']} dibayar + ${qtyInfo['bonus']} gratis",
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color
                                          ?.withOpacity(0.7),
                                    ),
                              ),
                            Text(
                              "Harga: Rp ${formatRupiah.format(produk.sellPrice)}",
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color
                                        ?.withOpacity(0.7),
                                  ),
                            ),
                          ],
                        ),
                        if (produk.promoType != null)
                          Text(
                            produk.promoType == "percentage" ||
                                    produk.promoType == "percent"
                                ? "Diskon: ${produk.promoPercent?.toStringAsFixed(0) ?? 0}%"
                                : produk.promoType == "buyxgety" ||
                                      produk.promoType == "buy_get"
                                ? "Promo: Buy ${produk.buyQty} Get ${produk.freeQty}"
                                : produk.promoType == "bundle"
                                ? "Bundle: ${produk.bundleQty} pcs = Rp ${formatRupiah.format(produk.bundleTotalPrice ?? 0)}"
                                : "",
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),

                        const SizedBox(height: 4),
                        Text(
                          "Subtotal: Rp ${formatRupiah.format(subtotalItem)}",
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),

            const SizedBox(height: 8),

            Text(
              "Total Harga: Rp ${formatRupiah.format(totalPrice)}",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            /// ================= NOMINAL CEPAT =================
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).cardColor,
                labelText: "Pilih Nominal Cepat",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              dropdownColor: Theme.of(context).cardColor,
              items: const [
                DropdownMenuItem(value: '20000', child: Text('Rp 20.000')),
                DropdownMenuItem(value: '50000', child: Text('Rp 50.000')),
                DropdownMenuItem(value: '100000', child: Text('Rp 100.000')),
                DropdownMenuItem(value: 'PAS', child: Text('💵 Uang Pas')),
              ],
              onChanged: (value) {
                if (value == null) return;
                if (value == 'PAS') {
                  uangController.text = totalPrice.toInt().toString();
                  onUangChanged(uangController.text, totalPrice);
                } else {
                  pilihNominal(double.parse(value), totalPrice);
                }
              },
            ),

            const SizedBox(height: 8),

            /// ================= INPUT UANG =================
            TextField(
              controller: uangController,
              focusNode: _uangFocus, // 🔥 INI KUNCINYA
              keyboardType: TextInputType.number,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).cardColor,
                labelText: "Uang Pelanggan",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.greenAccent, // ❗ TETAP HIJAU
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: (value) => onUangChanged(value, totalPrice),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),

            const SizedBox(height: 6),

            if (kembalian < 0)
              const Text(
                "Uang kurang!",
                style: TextStyle(color: Colors.redAccent, fontSize: 12),
              ),

            const SizedBox(height: 6),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Kembalian:",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  kembalian > 0
                      ? "Rp ${formatRupiah.format(kembalian)}"
                      : "Rp 0",
                  style: const TextStyle(
                    color: Colors.greenAccent, // 🔥 TETAP HIJAU
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// ================= BAYAR =================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: (kembalian < 0 || transaksiState.isLoading)
                    ? null
                    : () => bayar(cartItems),
                child: transaksiState.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Selesaikan Pembayaran",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
