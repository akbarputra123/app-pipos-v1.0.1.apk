import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kimpos/views/laporan/dashboard/dashboard.dart';
import 'package:kimpos/views/laporan/laporan_karyawan/laporan_karyawan.dart';
import 'package:kimpos/views/laporan/laporan_produk/laporan_produk.dart';

import 'widgets/header.dart';
import 'widgets/generate.dart';
import 'widgets/export.dart';
import 'widgets/total.dart';
import 'widgets/filter_waktu.dart';
import 'widgets/semua_laporan.dart';
import 'widgets/kas_terbaru.dart';

import '../../viewmodels/laporan_viewmodel.dart';

class LaporanScreen extends ConsumerStatefulWidget {
  const LaporanScreen({super.key});

  @override
  ConsumerState<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends ConsumerState<LaporanScreen> {
  int selectedHeaderIndex = 0;
  bool _fetched = false;

  /// 🔥 FILTER AKTIF
  FilterRange _activeFilter = FilterRange.today; // 🔥 DEFAULT HARI INI


  @override
  void initState() {
    super.initState();
    _fetchByFilter(_activeFilter);
  }

  (DateTime start, DateTime end) _resolveRange(FilterRange filter) {
  final now = DateTime.now();

  switch (filter) {
    case FilterRange.today:
      return (
        DateTime(now.year, now.month, now.day, 0, 0, 0),
        DateTime(now.year, now.month, now.day, 23, 59, 59),
      );

    case FilterRange.last7Days:
      return (
        DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 6)),
        DateTime(now.year, now.month, now.day, 23, 59, 59),
      );

    case FilterRange.last30Days:
      return (
        DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 29)),
        DateTime(now.year, now.month, now.day, 23, 59, 59),
      );

    case FilterRange.oneYear:
      return (
        DateTime(now.year, 1, 1, 0, 0, 0),
        DateTime(now.year, 12, 31, 23, 59, 59),
      );

    case FilterRange.all:
      return (
        DateTime(2000, 1, 1, 0, 0, 0),
        DateTime(now.year, now.month, now.day, 23, 59, 59),
      );
  }
}


  /// ===============================
  /// FETCH DATA (SUMMARY + CASHIER)
  /// ===============================
  Future<void> _fetchByFilter(FilterRange filter) async {
    if (_fetched) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final storeId = prefs.getInt('store_id');

    if (token == null || storeId == null) {
      log('❌ token / storeId null');
      return;
    }

    final vm = ref.read(laporanViewModelProvider.notifier);
    final (start, end) = _resolveRange(filter);

    log('📆 FETCH FILTER=$filter | start=$start | end=$end');

    await vm.fetchSummary(
      storeId: storeId,
      token: token,
      start: start,
      end: end,
    );

    await vm.fetchCashierReport(
      storeId: storeId,
      token: token,
      start: start,
      end: end,
    );
    await vm.fetchDailyList(
      storeId: storeId,
      token: token,
      start: start,
      end: end,
    );

    setState(() {
      _fetched = true;
    });
  }

  /// ===============================
  /// SHIMMER
  /// ===============================
  Widget shimmerBox({double height = 60}) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1E1E1E),
      highlightColor: const Color(0xFF2A2A2A),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(laporanViewModelProvider);

    /// ===============================
    /// BODY PER HEADER INDEX
    /// ===============================
    final headerBodies = [
      /// ===== 0. LAPORAN KEUANGAN =====
      SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GenerateReportBar(),
            const SizedBox(height: 8),

            const ExportReportBar(),
            const SizedBox(height: 16),

            const TotalSummary(),
            const SizedBox(height: 12),

            /// FILTER WAKTU
            FilterWaktu(
              active: _activeFilter,
              onChanged: (filter) async {
                setState(() {
                  _activeFilter = filter;
                  _fetched = false;
                });
                await _fetchByFilter(filter);
              },
            ),
            const SizedBox(height: 12),

            state.summary == null
                ? shimmerBox(height: 240)
                : const SemuaLaporan(),

            const SizedBox(height: 16),

            state.summary == null
                ? shimmerBox(height: 160)
                : const KasTerbaru(),

            const SizedBox(height: 24),
          ],
        ),
      ),

      /// ===== 1. DASHBOARD =====
      const DashboardScreen(),

      /// ===== 2. LAPORAN PRODUK =====
      const LaporanProdukScreen(),

      /// ===== 3. LAPORAN KARYAWAN =====
      const LaporanKaryawanScreen(),
    ];

    return Scaffold(
     backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HeaderLaporan(
              activeIndex: selectedHeaderIndex,
              onMenuTap: (index) {
                setState(() {
                  selectedHeaderIndex = index;
                });
              },
            ),
            const SizedBox(height: 16),

            /// 🔥 PINDAH HALAMAN BERDASARKAN INDEX
            Expanded(child: headerBodies[selectedHeaderIndex]),
          ],
        ),
      ),
    );
  }
}
