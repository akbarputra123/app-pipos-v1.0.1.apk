import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:shimmer/shimmer.dart';
import 'package:kimpos/views/produk/widgets/usb_printer.dart';

import '../../viewmodels/kelola_produk_viewmodel.dart';
import '../../viewmodels/transaksi_viewmodel.dart';
import '../../config/theme.dart';

import '../produk/widgets/search_produk.dart';
import 'widgets/card_produk.dart';
import 'widgets/cart_produk.dart';
import 'widgets/produk_scan.dart';
import 'widgets/sukses.dart';

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
  String _barcodeBuffer = '';
  DateTime? _lastKeyTime;

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
  /// HANDLE USB KEYBOARD SCAN
  /// ===============================
  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final char = event.character;
    final now = DateTime.now();

    _lastKeyTime ??= now;
    if (now.difference(_lastKeyTime!).inMilliseconds > 80) {
      _barcodeBuffer = '';
    }
    _lastKeyTime = now;

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_barcodeBuffer.length >= 5) {
        _handleBarcode(_barcodeBuffer);
        _barcodeBuffer = '';
        return KeyEventResult.handled;
      }
    }

    if (char != null && RegExp(r'[0-9]').hasMatch(char)) {
      _barcodeBuffer += char;
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// ===============================
  /// BARCODE → CART (SELALU TAMBAH QTY)
  /// ===============================
  void _handleBarcode(String barcode) {
    final state = ref.read(kelolaProdukViewModelProvider);
    final produk = state.products.firstWhereOrNull((p) => p.barcode == barcode);

    if (produk == null) {
      _snack("❌ Produk tidak ditemukan", Colors.red);
      return;
    }

    if (produk.stock <= 0) {
      _snack("Stok '${produk.name}' habis", Colors.redAccent);
      return;
    }

    // 🔥 SETIAP SCAN / KLIK = TAMBAH QTY
    ref.read(kelolaProdukViewModelProvider.notifier).addToCart(produk);

    _snack("➕ ${produk.name}", Colors.green);
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(milliseconds: 700),
      ),
    );
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
      final cat = p.category?.toLowerCase() ?? '';
      return (name.contains(keyword) || cat.contains(keyword)) &&
          (selectedCategory == 'ALL' || p.category == selectedCategory);
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Focus(
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 900;

            /// ================= MOBILE =================
            if (!isTablet) {
              return _buildContent(state, filteredProduk, categories);
            }

            /// ================= TABLET =================
            return Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildContent(state, filteredProduk, categories),
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
                  child: const CartProdukScreen(embedded: true),
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

  /// ===============================
  /// MAIN CONTENT
  /// ===============================
  Widget _buildContent(
    KelolaProdukState state,
    List filteredProduk,
    List<String> categories,
  ) {
    if (state.isLoading) return _buildSkeleton(context);

    return Column(
      children: [
        const SizedBox(height: 16),

        /// HEADER
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
                            _handleBarcode(code);
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
                  _usbStatus(context),
                ],
              ),

              const SizedBox(height: 16),
              _categoryDropdown(categories),
              const SizedBox(height: 12),

              Row(
                children: [
                  /// ===== LABEL DAFTAR PRODUK =====
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor, // 🌗 ikut theme
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(
                            0.35,
                          ), // brand glow
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Text(
                      "Daftar Produk",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const Spacer(),

                  /// ===== REFRESH BUTTON (MATCH STYLE) =====
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      ref.read(searchKeywordProvider.notifier).state = '';
                      ref
                          .read(kelolaProdukViewModelProvider.notifier)
                          .getProduk();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor, // 🌗 ikut theme
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.refresh,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        /// LIST PRODUK
        Expanded(
          child: filteredProduk.isEmpty
              ? const Center(child: Text("Belum ada produk"))
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: filteredProduk.length,
                  itemBuilder: (_, i) => CardProduk(produk: filteredProduk[i]),
                ),
        ),
      ],
    );
  }

  Widget _usbStatus(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: _checkUsbScanner,
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          color: theme.cardColor, // 🌗 ikut light / dark
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.redAccent, // 🔴 border merah
            width: 1.6,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withOpacity(0.25),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: _isCheckingUsb
            ? const Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.redAccent, // 🔴 loading merah
                ),
              )
            : Icon(
                Icons.usb,
                size: 22,
                color: _usbDetected
                    ? Colors
                          .green // ✅ USB terdeteksi
                    : Colors.redAccent, // ❌ tidak terdeteksi
              ),
      ),
    );
  }

  Widget _categoryDropdown(List<String> categories) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.cardColor, // 🌗 ikut light / dark
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor, // 🌗 border adaptif
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withOpacity(0.4)
                : Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCategory,
          isExpanded: true,

          /// 🌗 dropdown ikut theme
          dropdownColor: theme.cardColor,

          /// 🌗 icon warna adaptif
          icon: Icon(Icons.arrow_drop_down, color: theme.iconTheme.color),

          /// 🌗 teks utama
          style: theme.textTheme.bodyMedium,

          items: [
            DropdownMenuItem<String>(
              value: 'ALL',
              child: Text("Semua Kategori", style: theme.textTheme.bodyMedium),
            ),
            ...categories.map(
              (c) => DropdownMenuItem<String>(
                value: c,
                child: Text(c, style: theme.textTheme.bodyMedium),
              ),
            ),
          ],

          onChanged: (v) {
            if (v != null) {
              ref.read(selectedCategoryProvider.notifier).state = v;
            }
          },
        ),
      ),
    );
  }

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
