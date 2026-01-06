import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../viewmodels/kelola_produk_viewmodel.dart';
import '../../viewmodels/transaksi_viewmodel.dart';
import '../../config/theme.dart';
import '../../models/produk_model.dart';
import '../../viewmodels/profile_viewmodel.dart';

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

  final formatRupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: '',
    decimalDigits: 0,
  );

  @override
  void dispose() {
    uangController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Ambil PPN dari profile
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final profileVM = ref.read(profileViewModelProvider.notifier);
      final tax = await profileVM.fetchTaxPercentage();
      setState(() {
        taxPercentage = tax;
      });
    });
  }

  // Hitung harga produk per item dengan promo
  double getPriceAfterDiscount(ProdukModel produk) {
    double price = produk.sellPrice;

    if (produk.promoType != null) {
      if (produk.promoType == "percentage" || produk.promoType == "percent") {
        price = price * (1 - (produk.promoPercent ?? 0) / 100);
        price *= produk.qty;
      } else if (produk.promoType == "buyxgety" ||
          produk.promoType == "buy_get") {
        final x = produk.buyQty ?? 0;
        final y = produk.freeQty ?? 0;
        final totalQty = produk.qty;
        final paidQty = (totalQty ~/ (x + y)) * x + (totalQty % (x + y));
        price = paidQty * produk.sellPrice;
      }
    } else {
      price = price * produk.qty;
    }

    return price;
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Uang pelanggan kurang")),
    );
    return;
  }

  // ================= TUTUP BOTTOM SHEET =================
  Navigator.of(context).pop();

  // ================= SUBMIT SNAPSHOT =================
  await ref.read(transaksiViewModelProvider.notifier).submitTransaction(
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
      decoration: const BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.75,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Container(
                width: 60,
                height: 6,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const Center(
              child: Text(
                "Detail Transaksi",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card.withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total Item: ${cartItems.length}",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    "Total Produk: $totalProduk",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const Divider(color: Colors.white30),
                  Text(
                    "Subtotal: Rp ${formatRupiah.format(subtotal)}",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    "PPN (${taxPercentage.toStringAsFixed(0)}%): Rp ${formatRupiah.format(totalPrice - subtotal)}",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const Divider(color: Colors.white30),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Daftar item
            if (cartItems.isEmpty)
              const Center(
                child: Text(
                  "Belum ada produk yang dibeli",
                  style: TextStyle(color: Colors.white),
                ),
              )
            else
              ...cartItems.map((produk) {
                final qtyInfo = getQtyDisplay(produk);

                final subtotalItem = getPriceAfterDiscount(produk);

                return Card(
                  color: AppColors.card.withOpacity(0.9),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Jumlah: ${qtyInfo['paid']} dibayar + ${qtyInfo['bonus']} gratis",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),

                            Text(
                              "Harga: Rp ${formatRupiah.format(produk.sellPrice)}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        if (produk.promoType != null)
                          Text(
                            produk.promoType == "percentage" ||
                                    produk.promoType == "percent"
                                ? "Diskon: ${produk.promoPercent?.toStringAsFixed(0) ?? 0}%"
                                : "Promo: Buy ${produk.buyQty} Get ${produk.freeQty}",
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          "Subtotal: Rp ${formatRupiah.format(subtotalItem)}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),

            Text(
              "Total Harga: Rp ${formatRupiah.format(totalPrice)}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: null,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.card, // ⬅️ pakai AppColors
                labelText: "Pilih Nominal Cepat",
                labelStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              dropdownColor: AppColors.card,
              icon: const Icon(Icons.keyboard_arrow_down),
              items: const [
                DropdownMenuItem(
                  value: '20000',
                  child: Text(
                    'Rp 20.000',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                DropdownMenuItem(
                  value: '50000',
                  child: Text(
                    'Rp 50.000',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                DropdownMenuItem(
                  value: '100000',
                  child: Text(
                    'Rp 100.000',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                DropdownMenuItem(
                  value: 'PAS',
                  child: Text(
                    '💵 Uang Pas',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;

                if (value == 'PAS') {
                  uangController.text = totalPrice.toInt().toString();
                  onUangChanged(uangController.text, totalPrice);
                } else {
                  final nominal = double.parse(value);
                  pilihNominal(nominal, totalPrice);
                }
              },
            ),

            const SizedBox(height: 8),

            // Input uang pelanggan & kembalian
            TextField(
              controller: uangController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black, // ⬅️ background hitam
                labelText: "Uang Pelanggan",
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white38),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.greenAccent, width: 1.5),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
              onChanged: (value) => onUangChanged(value, totalPrice),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),

            const SizedBox(height: 4),
            if (kembalian < 0)
              const Text(
                "Uang kurang!",
                style: TextStyle(color: Colors.redAccent, fontSize: 12),
              ),

            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Kembalian:",
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  kembalian > 0
                      ? "Rp ${formatRupiah.format(kembalian)}"
                      : "Rp 0",
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

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
                        "Bayar",
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
