import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../viewmodels/kelola_produk_viewmodel.dart';
import '../../config/theme.dart';
import 'widgets/card_produk.dart';
import 'widgets/search_produk.dart';
import 'widgets/total_produk_card.dart';
import 'widgets/dropdown_kategori.dart';
import 'widgets/tambah_produk.dart';
import 'widgets/usb_printer.dart';
import 'widgets/produk_scan.dart';

class ProdukScreen extends ConsumerStatefulWidget {
  const ProdukScreen({super.key});

  @override
  ConsumerState<ProdukScreen> createState() => _ProdukScreenState();
}

class _ProdukScreenState extends ConsumerState<ProdukScreen> {
  String selectedCategory = "Semua";
  bool isExporting = false;

  String _role = '';
  bool _roleLoaded = false;

  final FocusNode _scannerFocusNode = FocusNode();
  String _scannedBarcode = "";
  bool _usbDetected = false;
  bool _isCheckingUsb = false;

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      ref.read(searchKeywordProvider.notifier).state = "";
      ref.read(kelolaProdukViewModelProvider.notifier).getProduk();
      _checkUsbScanner();

      final prefs = await SharedPreferences.getInstance();
      _role = prefs.getString('role') ?? '';
      _roleLoaded = true;
      if (mounted) setState(() {});
    });
  }

  Future<void> _checkUsbScanner() async {
    if (_isCheckingUsb) return;

    setState(() => _isCheckingUsb = true);
    bool detected = false;

    try {
      final devices = await UsbPrinter.getUsbDevices();
      detected = devices.isNotEmpty;
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      _usbDetected = detected;
      _isCheckingUsb = false;
    });
  }

  void _onKeyScan(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_scannedBarcode.isNotEmpty) {
          ref.read(searchKeywordProvider.notifier).state = _scannedBarcode;
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kelolaProdukViewModelProvider);
    final keyword = ref.watch(searchKeywordProvider).toLowerCase().trim();
    final isCashier = _role.toLowerCase() == 'cashier';

    final categories = state.products
        .map((p) => p.category ?? "Tidak Ada")
        .toSet()
        .toList();

    final filteredProducts = state.products.where((produk) {
      final name = produk.name.toLowerCase();
      final barcode = (produk.barcode ?? '').toLowerCase();
      final sku = (produk.sku ?? '').toLowerCase();

      final matchKeyword =
          keyword.isEmpty ||
          name.contains(keyword) ||
          barcode.contains(keyword) ||
          sku.contains(keyword);

      final matchCategory =
          selectedCategory == "Semua" ||
          (produk.category ?? "Tidak Ada") == selectedCategory;

      return matchKeyword && matchCategory;
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RawKeyboardListener(
        focusNode: _scannerFocusNode,
        autofocus: true,
        onKey: _onKeyScan,
        child: state.isLoading || !_roleLoaded
            ? _buildSkeleton(context)
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    /// SEARCH + TAMBAH
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Expanded(child: SearchProduk()),
                          const SizedBox(width: 8),
                          if (!isCashier)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const TambahProdukScreen(),
                                  ),
                                );
                              },
                              child: const Icon(
                                Icons.add_shopping_cart,
                                size: 25,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),

                    /// TOTAL
                    SizedBox(
                      height: 100,
                      child: TotalProdukCard(produkList: state.products),
                    ),

                    const SizedBox(height: 10),

                    /// SCAN + USB
                    _scanAndUsbRow(),

                    const SizedBox(height: 10),

                    /// DROPDOWN
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 5,
                      ),
                      child: DropdownKategori(
                        categories: categories,
                        selectedCategory: selectedCategory,
                        onChanged: (v) {
                          if (v != null) setState(() => selectedCategory = v);
                        },
                      ),
                    ),

                    _labelWithRefresh(),

                    /// ================= LIST PRODUK (SCROLL SENDIRI) =================
                    SizedBox(
                      height:
                          MediaQuery.of(context).size.height * 0.6, // 🔥 tetap
                      child: filteredProducts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 48,
                                    color: Theme.of(
                                      context,
                                    ).iconTheme.color?.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Tidak ada produk",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontSize: 14,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.color
                                              ?.withOpacity(0.7),
                                        ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                              ),
                              physics: const BouncingScrollPhysics(),
                              itemCount: filteredProducts.length,
                              itemBuilder: (_, i) => CardProduk(
                                produk: filteredProducts[i],
                                isCashier: isCashier,
                              ),
                            ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _scanAndUsbRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final code = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(builder: (_) => const ProdukScanScreen()),
                  );
                  if (code != null && code.isNotEmpty) {
                    ref.read(searchKeywordProvider.notifier).state = code;
                  }
                },
                icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
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
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _checkUsbScanner,
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor, // ✅ ikut theme
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _usbDetected
                      ? AppColors
                            .success // hijau tetap hijau
                      : AppColors.danger, // merah tetap merah
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.usb,
                size: 22,
                color: _usbDetected ? AppColors.success : AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _labelWithRefresh() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor, // ✅ ikut theme
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.35), // brand tetap
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              "Daftar Produk",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          ElevatedButton.icon(
            onPressed: isExporting
                ? null
                : () async {
                    setState(() => isExporting = true);
                    final filePath = await ref
                        .read(kelolaProdukViewModelProvider.notifier)
                        .exportProdukToExcel();
                    setState(() => isExporting = false);
                    if (filePath != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("✅ Excel berhasil diunduh"),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("❌ Gagal membuat Excel")),
                      );
                    }
                  },
            icon: isExporting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.download, size: 18),
            label: Text(
              isExporting ? "Exporting..." : "Export",
              style: const TextStyle(fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.25), // 🔴 tipis
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              tooltip: "Refresh",
              icon: const Icon(Icons.refresh, color: AppColors.primary),
              onPressed: () {
                ref.read(searchKeywordProvider.notifier).state = "";
                ref.read(kelolaProdukViewModelProvider.notifier).getProduk();
              },
            ),
          ),
        ],
      ),
    );
  }

  /// ================= SKELETON (DARK / LIGHT AWARE) =================
  Widget _buildSkeleton(BuildContext context) {
    final theme = Theme.of(context);

    return Shimmer.fromColors(
      baseColor: theme.cardColor,
      highlightColor: theme.dividerColor.withOpacity(0.4),
      child: ListView.builder(
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.all(12),
          height: 100, // ⬅️ TETAP
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
