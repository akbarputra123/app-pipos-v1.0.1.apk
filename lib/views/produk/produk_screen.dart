import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../viewmodels/kelola_produk_viewmodel.dart';
import '../../config/theme.dart';
import 'card_produk.dart';
import 'search_produk.dart';
import 'total_produk_card.dart';
import 'dropdown_kategori.dart';
import 'tambah_produk.dart';
import 'usb_printer.dart';
import 'produk_scan.dart';

class ProdukScreen extends ConsumerStatefulWidget {
  const ProdukScreen({super.key});

  @override
  ConsumerState<ProdukScreen> createState() => _ProdukScreenState();
}

class _ProdukScreenState extends ConsumerState<ProdukScreen> {
  String selectedCategory = "Semua";
  bool isExporting = false;

  /// 🔥 ROLE DISIMPAN SEKALI
  String _role = '';
  bool _roleLoaded = false;

  /// ===============================
  /// USB + KEYBOARD SCANNER STATE
  /// ===============================
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

      /// 🔥 AMBIL ROLE SEKALI
      final prefs = await SharedPreferences.getInstance();
      _role = prefs.getString('role') ?? '';
      _roleLoaded = true;
      if (mounted) setState(() {});
    });
  }

  /// ===============================
  /// CEK USB
  /// ===============================
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

  /// ===============================
  /// USB HID SCAN
  /// ===============================
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
            ? _buildSkeleton()
            : Column(
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

                  /// LIST PRODUK (🔥 RINGAN)
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      itemCount: filteredProducts.length,
                      itemBuilder: (_, i) => CardProduk(
                        produk: filteredProducts[i],
                        isCashier: isCashier,
                      ),
                    ),
                  ),
                ],
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
                label: const Text("Scan Produk", style: TextStyle(color: Colors.white),),
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
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.usb,
                color: _usbDetected ? Colors.green : Colors.red,
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
          /// ===== LABEL "DAFTAR PRODUK" =====
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: const Text(
              "Daftar Produk",
              style: TextStyle(
                color: AppColors.textPrimary,
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
                                          .read(
                                            kelolaProdukViewModelProvider
                                                .notifier,
                                          )
                                          .exportProdukToExcel();
                                      setState(() => isExporting = false);
                                      if (filePath != null) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "✅ Excel berhasil diunduh",
                                            ),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "❌ Gagal membuat Excel",
                                            ),
                                          ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),

          /// ===== BUTTON REFRESH =====
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
                // 🔥 RESET SEARCH
                ref.read(searchKeywordProvider.notifier).state = "";

                // 🔄 FETCH ULANG PRODUK
                ref.read(kelolaProdukViewModelProvider.notifier).getProduk();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Shimmer.fromColors(
      baseColor: AppColors.card,
      highlightColor: Colors.white.withOpacity(0.6),
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
}
