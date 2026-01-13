import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../viewmodels/laporan_viewmodel.dart';
import '../../../models/laporan_model.dart';

import '../widgets/filter_waktu.dart';
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
  /// ===============================
  /// STATE
  /// ===============================
  bool _hasFetched = false;
  FilterRange _activeFilter = FilterRange.today;

  /// cache → supaya UI tidak kedip
  ReportProduct? _cachedProduct;

  /// ===============================
  /// SHIMMER (FIRST LOAD ONLY)
  /// ===============================
Widget shimmerBox(BuildContext context, {double height = 70}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return Shimmer.fromColors(
    baseColor: isDark
        ? theme.cardColor
        : theme.dividerColor.withOpacity(0.35),
    highlightColor: isDark
        ? theme.cardColor.withOpacity(0.6)
        : theme.dividerColor.withOpacity(0.55),
    child: Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}



  /// ===============================
  /// FILTER → RANGE
  /// ===============================
  DateTimeRange _resolveRange(FilterRange filter) {
    final now = DateTime.now();

    switch (filter) {
      case FilterRange.today:
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );

      case FilterRange.last7Days:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 6)),
          end: now,
        );

      case FilterRange.last30Days:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 29)),
          end: now,
        );

      case FilterRange.oneYear:
        return DateTimeRange(
          start: DateTime(now.year - 1, now.month, now.day),
          end: now,
        );

      case FilterRange.all:
        return DateTimeRange(
          start: DateTime(2000),
          end: now,
        );
    }
  }

  /// ===============================
  /// FETCH DATA
  /// ===============================
  Future<void> _fetchByFilter(FilterRange filter) async {
    if (_activeFilter == filter && _hasFetched) return;

    _activeFilter = filter;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final storeId = prefs.getInt('store_id');

    if (token == null || storeId == null) {
      log('❌ token / storeId null');
      return;
    }

    final range = _resolveRange(filter);

    await ref.read(laporanViewModelProvider.notifier).fetchProductReport(
          storeId: storeId,
          token: token,
          start: range.start,
          end: range.end,
        );

    _hasFetched = true;
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _fetchByFilter(_activeFilter));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(laporanViewModelProvider);

    /// update cache kalau ada data baru
    if (state.productReport != null) {
      _cachedProduct = state.productReport;
    }

    final product = _cachedProduct;
    final isFirstLoading = !_hasFetched && product == null;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ================= FILTER =================
          isFirstLoading
              ? shimmerBox(context, height: 36)
              : FilterWaktu(
                  active: _activeFilter,
                  onChanged: (v) => _fetchByFilter(v),
                ),

          const SizedBox(height: 16),

          /// ================= EXPORT =================
          isFirstLoading ? shimmerBox(context, height: 44) : const ExportProdukBar(),

          const SizedBox(height: 16),

          /// ================= TOTAL CARD =================
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.3,
            ),
            children: product == null
                ? List.generate(4, (_) => shimmerBox(context))
                : [
                    CardTotal(
                      icon: Icons.inventory_2,
                      iconBgColor: const Color(0xFFE53935),
                      value: product.totalProducts.toString(),
                      label: 'Total Produk',
                    ),
                    CardTotal(
                      icon: Icons.shopping_cart,
                      iconBgColor: const Color(0xFF1F6E43),
                      value: product.totalSold.toString(),
                      label: 'Produk Terjual',
                    ),
                    CardTotal(
                      icon: Icons.warning_amber_rounded,
                      iconBgColor: const Color(0xFFF9A825),
                      value: product.stokMenipis
                          .where((e) => e.remaining > 0)
                          .length
                          .toString(),
                      label: 'Stok Menipis',
                    ),
                    CardTotal(
                      icon: Icons.cancel,
                      iconBgColor: const Color(0xFFD32F2F),
                      value: product.stokHabis.toString(),
                      label: 'Stok Habis',
                    ),
                  ],
          ),

          const SizedBox(height: 16),

          /// ================= TOP PRODUCTS =================
          product == null
              ? shimmerBox(context, height: 160)
              : CardProduk(
                  title: '10 Produk Teratas',
                  titleIcon: Icons.star_border,
                  items: mapTopProductsToProdukItem(product.topProducts),
                ),

          const SizedBox(height: 16),

          /// ================= LOW STOCK =================
          product == null
              ? shimmerBox(context, height: 160)
              : CardProduk(
                  title: 'Stok Menipis',
                  titleIcon: Icons.warning_amber_rounded,
                  items: mapLowStockToProdukItem(product.stokMenipis),
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
      .where((e) => e.remaining > 0)
      .map((e) {
        return ProdukItem(
          name: e.name,
          stock: e.remaining,
          minStock: 10,
          isCritical: e.remaining <= 10,
        );
      })
      .toList();
}
