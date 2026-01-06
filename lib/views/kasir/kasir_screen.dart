import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kimpos/views/produk/usb_printer.dart';
import 'package:shimmer/shimmer.dart';
import 'package:collection/collection.dart';

import '../../viewmodels/kelola_produk_viewmodel.dart';
import '../../viewmodels/transaksi_viewmodel.dart';
import 'card_produk.dart';
import '../produk/search_produk.dart';
import 'cart_produk.dart';
import 'sukses.dart';
import '../../config/theme.dart';
import 'produk_scan.dart';

final selectedCategoryProvider = StateProvider<String>((ref) => 'ALL');

class KasirScreen extends ConsumerStatefulWidget {
  const KasirScreen({super.key});

  @override
  ConsumerState<KasirScreen> createState() => _KasirScreenState();
}

class _KasirScreenState extends ConsumerState<KasirScreen> {
  /// ===============================
  /// USB SCANNER STATE
  /// ===============================
  final FocusNode _scannerFocusNode = FocusNode();
  String _scannedBarcode = "";
  bool _usbDetected = false;
  bool _isCheckingUsb = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(kelolaProdukViewModelProvider.notifier).getProduk();
      _checkUsbScanner();
    });
  }

  Future<void> _checkUsbScanner() async {
    if (_isCheckingUsb) return;

    setState(() => _isCheckingUsb = true);

    try {
      final devices = await UsbPrinter.getUsbDevices();
      _usbDetected = devices.isNotEmpty;
    } catch (_) {
      _usbDetected = false;
    }

    if (mounted) {
      setState(() => _isCheckingUsb = false);
    }
  }

  /// ===============================
  /// HANDLE USB SCAN
  /// ===============================
  void _onUsbScan(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_scannedBarcode.isNotEmpty) {
          _handleBarcode(_scannedBarcode);
          _scannedBarcode = "";
        }
        return;
      }

      final char = event.character;
      if (char != null && RegExp(r'[0-9]').hasMatch(char)) {
        _scannedBarcode += char;
      }
    }
  }

  /// ===============================
  /// BARCODE → CART
  /// ===============================
  void _handleBarcode(String barcode) {
    final state = ref.read(kelolaProdukViewModelProvider);
    final produk = state.products.firstWhereOrNull((p) => p.barcode == barcode);

    if (produk == null) {
      _snack("❌ Produk tidak ditemukan", Colors.red);
      return;
    }

    if (produk.stock == 0) {
      _snack("Stok '${produk.name}' habis", Colors.redAccent);
      return;
    }

    if (produk.qty > 0) {
      _snack("Produk '${produk.name}' sudah ada di keranjang", Colors.orange);
      return;
    }

    ref.read(kelolaProdukViewModelProvider.notifier).addToCart(produk);
    _snack("✅ '${produk.name}' ditambahkan ke keranjang", Colors.green);
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kelolaProdukViewModelProvider);
    final keyword = ref.watch(searchKeywordProvider).toLowerCase();
    final selectedCategory = ref.watch(selectedCategoryProvider);

    final categories =
        state.products
            .map((p) => p.category)
            .where((c) => c != null && c!.isNotEmpty)
            .toSet()
            .cast<String>()
            .toList()
          ..sort();

    ref.listen<TransaksiState>(transaksiViewModelProvider, (p, n) {
      if (n.isSuccess && n.result != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SuksesScreen(transaksi: n.result!)),
        );
        Future.delayed(
          const Duration(milliseconds: 500),
          () => ref.read(transaksiViewModelProvider.notifier).reset(),
        );
      }
    });

    final filteredProduk = state.products.where((p) {
      final name = p.name.toLowerCase();
      final cat = p.category?.toLowerCase() ?? "";
      return (name.contains(keyword) || cat.contains(keyword)) &&
          (selectedCategory == 'ALL' || p.category == selectedCategory);
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RawKeyboardListener(
        focusNode: _scannerFocusNode,
        autofocus: true,
        onKey: _onUsbScan,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 900;

            /// ================= MOBILE =================
            if (!isTablet) {
              return _buildMobileLayout(state, filteredProduk, categories);
            }

            /// ================= TABLET =================
            return Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildMobileLayout(state, filteredProduk, categories),
                ),
                Container(
                  width: 380,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    border: Border(
                      left: BorderSide(
                        color: AppColors.primary.withOpacity(0.4),
                        width: 2,
                      ),
                    ),
                  ),
                  child: const CartProdukScreen(
                    embedded: true, // nanti kita aktifkan
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: MediaQuery.of(context).size.width < 900
          ? _cartButton(ref, context)
          : null,
    );
  }

  Widget _buildMobileLayout(
    KelolaProdukState state,
    List filteredProduk,
    List<String> categories,
  ) {
    if (state.isLoading) return _buildSkeleton();

    return Column(
      children: [
        const SizedBox(height: 16),

        /// ================= HEADER =================
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SearchProduk(),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final code = await Navigator.push<String>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProdukScanScreen(),
                            ),
                          );

                          if (code != null && code.isNotEmpty) {
                            _handleBarcode(code); // 🔥 TAMBAH KE KERANJANG
                          }
                        },

                        icon: const Icon(
                          Icons.qr_code_scanner,
                          color: Colors.white,
                        ),
                        label: const Text(
                          "Scan Produk",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _usbStatus(),
                ],
              ),

              const SizedBox(height: 16),
              _categoryDropdown(categories),

              const SizedBox(height: 12),

              /// ===== LABEL + REFRESH (FIXED) =====
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: const Text(
                      "Daftar Produk",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const Spacer(),

                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: IconButton(
                      tooltip: "Refresh",
                      icon: const Icon(Icons.refresh, color: AppColors.primary),
                      onPressed: () {
                        ref.read(searchKeywordProvider.notifier).state = "";
                        ref
                            .read(kelolaProdukViewModelProvider.notifier)
                            .getProduk();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        /// ================= LIST PRODUK (SCROLL) =================
        Expanded(
          child: filteredProduk.isEmpty
              ? const Center(child: Text("Belum ada produk"))
              : ListView.builder(
                  padding: EdgeInsets.zero, // 🔥 PENTING
                  itemCount: filteredProduk.length,
                  itemBuilder: (_, i) => CardProduk(produk: filteredProduk[i]),
                ),
        ),
      ],
    );
  }

  Widget _usbStatus() {
    return GestureDetector(
      onTap: _checkUsbScanner,
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: _isCheckingUsb
            ? const Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.usb, color: _usbDetected ? Colors.green : Colors.red),
      ),
    );
  }

  Widget _categoryDropdown(List<String> categories) {
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardSoft, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCategory,
          isExpanded: true,
          dropdownColor: AppColors.card,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.textPrimary,
          ),
          items: [
            const DropdownMenuItem(value: 'ALL', child: Text("Semua Kategori")),
            ...categories.map(
              (c) => DropdownMenuItem(value: c, child: Text(c)),
            ),
          ],
          onChanged: (v) {
            if (v == null) return;
            ref.read(selectedCategoryProvider.notifier).state = v;
          },
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Shimmer.fromColors(
      baseColor: AppColors.card,
      highlightColor: Colors.white24,
      child: ListView.builder(
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.all(12),
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _cartButton(WidgetRef ref, BuildContext context) {
    final count = ref
        .watch(kelolaProdukViewModelProvider)
        .products
        .where((p) => p.qty > 0)
        .length;

    return FloatingActionButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CartProdukScreen()),
      ),
      child: Stack(
        children: [
          const Icon(Icons.shopping_cart),
          if (count > 0)
            Positioned(
              right: 0,
              top: 0,
              child: CircleAvatar(
                radius: 9,
                backgroundColor: AppColors.danger,
                child: Text(
                  count.toString(),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
