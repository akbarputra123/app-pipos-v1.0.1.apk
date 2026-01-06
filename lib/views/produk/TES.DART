import 'package:flutter/material.dart';
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

class ProdukScreen extends ConsumerStatefulWidget {
  const ProdukScreen({super.key});

  @override
  ConsumerState<ProdukScreen> createState() => _ProdukScreenState();
}

class _ProdukScreenState extends ConsumerState<ProdukScreen> {
  String selectedCategory = "Semua";
  bool isExporting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(kelolaProdukViewModelProvider.notifier).getProduk(),
    );
  }

  Future<String?> _getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kelolaProdukViewModelProvider);
    final keyword = ref.watch(searchKeywordProvider).toLowerCase();

    final categories = state.products
        .map((p) => p.category ?? "Tidak Ada")
        .toSet()
        .toList();

    final filteredProducts = state.products.where((produk) {
      final matchKeyword = produk.name.toLowerCase().contains(keyword);
      final matchCategory =
          selectedCategory == "Semua" ||
          (produk.category ?? "Tidak Ada") == selectedCategory;
      return matchKeyword && matchCategory;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SizedBox(
        child: state.isLoading
            ? Shimmer.fromColors(
                baseColor: AppColors.card,
                highlightColor: Colors.white.withOpacity(0.6),
                child: Column(
                  children: [
                    // Search bar + tombol tambah
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // TotalProdukCard
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 0),
                      child: SizedBox(
                        height: 100,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Dropdown kategori
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 5,
                      ),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Label Daftar Produk + export + refresh
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 5,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 120,
                            height: 30,
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 100,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 40,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // List Produk skeleton
                    Expanded(
                      child: ListView.builder(
                        itemCount: 6,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.textPrimary.withOpacity(0.4),
                                width: 1.5,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  // Search bar + tombol tambah
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: FutureBuilder<String?>(
                      future: _getRole(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Row(
                            children: [
                              Expanded(child: const SearchProduk()),
                              const SizedBox(width: 8),
                              const SizedBox(
                                width: 40,
                                height: 40,
                              ), // placeholder
                            ],
                          );
                        }

                        final role = snapshot.data ?? '';
                        final isCashier = role.toLowerCase() == 'cashier';

                        return Row(
                          children: [
                            Expanded(child: const SearchProduk()),
                            const SizedBox(width: 8),

                            /// 🔐 TOMBOL TAMBAH PRODUK (NON-KASIR SAJA)
                            if (!isCashier)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (_, __, ___) =>
                                          const TambahProdukScreen(),
                                      transitionsBuilder:
                                          (_, animation, __, child) {
                                            return FadeTransition(
                                              opacity: animation,
                                              child: child,
                                            );
                                          },
                                      transitionDuration: const Duration(
                                        milliseconds: 300,
                                      ),
                                    ),
                                  );
                                },
                                child: const Icon(
                                  Icons.add_shopping_cart,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),

                  // TotalProdukCard
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 0),
                    child: Center(
                      child: SizedBox(
                        height: 100,
                        child: TotalProdukCard(produkList: state.products),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Dropdown kategori
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 5,
                    ),
                    child: DropdownKategori(
                      categories: categories,
                      selectedCategory: selectedCategory,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedCategory = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Label Daftar Produk + export + refresh
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 5,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
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
                        Row(
                          children: [
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
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: () {
                                  ref
                                      .read(
                                        kelolaProdukViewModelProvider.notifier,
                                      )
                                      .getProduk();
                                },
                                icon: const Icon(
                                  Icons.refresh,
                                  color: AppColors.primary,
                                ),
                                tooltip: "Refresh",
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // List Produk
                  Expanded(
                    child: filteredProducts.isEmpty
                        ? const Center(
                            child: Text(
                              "Belum ada produk",
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 0,
                            ), // padding vertical dihapus
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final produk = filteredProducts[index];
                              return CardProduk(produk: produk);
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
