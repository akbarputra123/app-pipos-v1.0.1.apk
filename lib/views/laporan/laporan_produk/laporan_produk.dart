import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../viewmodels/laporan_viewmodel.dart';
import '../../../models/laporan_model.dart';

import 'widgets/filter_waktu.dart';
import 'widgets/export.dart';
import 'widgets/card_total.dart';
import 'widgets/card_produk.dart';

class LaporanProdukScreen extends ConsumerStatefulWidget {
  const LaporanProdukScreen({super.key});

  @override
  ConsumerState<LaporanProdukScreen> createState() =>
      _LaporanProdukScreenState();
}

class _LaporanProdukScreenState extends ConsumerState<LaporanProdukScreen> {
  bool _hasFetched = false;

  /// ================= SHIMMER =================
  Widget shimmerBox({double height = 70}) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1E1E1E),
      highlightColor: const Color(0xFF2A2A2A),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  /// ================= RANGE FILTER =================
  DateTimeRange _getRangeFromFilter(int index) {
    final now = DateTime.now();

    switch (index) {
      case 0: // Hari ini
        return DateTimeRange(start: now, end: now);
      case 1: // 7 hari
        return DateTimeRange(
          start: now.subtract(const Duration(days: 6)),
          end: now,
        );
      case 2: // 30 hari
        return DateTimeRange(
          start: now.subtract(const Duration(days: 29)),
          end: now,
        );
      case 3: // 1 tahun
        return DateTimeRange(
          start: DateTime(now.year - 1, now.month, now.day),
          end: now,
        );
      case 4: // Semua data
      default:
        return DateTimeRange(start: DateTime(2000), end: now);
    }
  }

  /// ================= FETCH BY FILTER =================
  Future<void> _fetchByFilter(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final storeId = prefs.getInt('store_id');

    if (token == null || storeId == null) {
      log('❌ token / storeId null');
      return;
    }

    final range = _getRangeFromFilter(index);

    await ref
        .read(laporanViewModelProvider.notifier)
        .fetchProductReport(
          storeId: storeId,
          token: token,
          start: range.start,
          end: range.end,
        );
  }

  @override
  void initState() {
    super.initState();

    /// 🔥 FETCH AWAL
    Future.microtask(() async {
      if (_hasFetched) return;
      _hasFetched = true;

      await _fetchByFilter(4); // default = Semua data
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(laporanViewModelProvider);
    final product = state.productReport;
    final isLoading = state.isLoading && product == null;

    if (!isLoading && product == null) {
      return const Center(
        child: Text(
          'Data produk belum tersedia',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ================= FILTER =================
          isLoading
              ? shimmerBox(height: 36)
              : FilterWaktu(
                  onChanged: (index) {
                    _fetchByFilter(index); // 🔥 FILTER JALAN
                  },
                ),
          const SizedBox(height: 16),

          /// ================= EXPORT =================
          isLoading ? shimmerBox(height: 44) : const ExportProdukBar(),
          const SizedBox(height: 16),

          /// ================= TOTAL CARD =================
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.3,
            ),
            children: [
              isLoading
                  ? shimmerBox()
                  : CardTotal(
                      icon: Icons.inventory_2,
                      iconBgColor: const Color(0xFFE53935),
                      value: product!.totalProducts.toString(),
                      label: 'Total Produk',
                    ),
              isLoading
                  ? shimmerBox()
                  : CardTotal(
                      icon: Icons.shopping_cart,
                      iconBgColor: const Color(0xFF1F6E43),
                      value: product!.totalSold.toString(),
                      label: 'Produk Terjual',
                    ),
              isLoading
                  ? shimmerBox()
                  : CardTotal(
                      icon: Icons.warning_amber_rounded,
                      iconBgColor: const Color(0xFFF9A825),
                      value: product!.stokMenipis
                          .where((e) => e.remaining > 0)
                          .length
                          .toString(),
                      label: 'Stok Menipis',
                    ),

              isLoading
                  ? shimmerBox()
                  : CardTotal(
                      icon: Icons.cancel,
                      iconBgColor: const Color(0xFFD32F2F),
                      value: product!.stokHabis.toString(),
                      label: 'Stok Habis',
                    ),
            ],
          ),

          const SizedBox(height: 24),

          /// ================= PRODUK CARD =================
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.25,
            ),
            children: [
              isLoading
                  ? shimmerBox(height: 160)
                  : CardProduk(
                      title: '10 Produk Teratas',
                      titleIcon: Icons.star_border,
                      items: mapTopProductsToProdukItem(product!.topProducts),
                    ),
              isLoading
                  ? shimmerBox(height: 160)
                  : CardProduk(
                      title: 'Stok Menipis',
                      titleIcon: Icons.warning_amber_rounded,
                      items: mapLowStockToProdukItem(product!.stokMenipis),
                    ),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// ================= MAPPER =================

List<ProdukItem> mapTopProductsToProdukItem(List<TopProduct> list) {
  return list.map((e) {
    return ProdukItem(
      name: e.name,
      stock: e.sold,
      minStock: 0,
      isCritical: false,
    );
  }).toList();
}

List<ProdukItem> mapLowStockToProdukItem(List<LowStockProduct> list) {
  return list
      .where((e) => e.remaining > 0) // 🔥 BUANG STOK 0
      .map((e) {
        return ProdukItem(
          name: e.name,
          stock: e.remaining,
          minStock: 10,
          isCritical: e.remaining <= 10, // sekarang AMAN
        );
      })
      .toList();
}
