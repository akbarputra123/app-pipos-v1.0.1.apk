import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../viewmodels/laporan_viewmodel.dart';
import 'widgets/filter_waktu.dart';
import 'widgets/card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _hasFetched = false;
  bool _isFilterLoading = false;
  int _activeFilterIndex = 0; // 🔥 DEFAULT = Semua data

  String rupiah(int value) {
    return 'Rp ${value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => '.',
    )}';
  }

  Widget shimmerBox({double height = 60}) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1E1E1E),
      highlightColor: const Color(0xFF2A2A2A),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  /// ================= RANGE FILTER =================
  DateTimeRange _getRange(int index) {
    final now = DateTime.now();

    switch (index) {
      case 0:
        return DateTimeRange(start: now, end: now);
      case 1:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 6)),
          end: now,
        );
      case 2:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 29)),
          end: now,
        );
      case 3:
        return DateTimeRange(
          start: DateTime(now.year - 1, now.month, now.day),
          end: now,
        );
      default:
        return DateTimeRange(
          start: DateTime(2000),
          end: now,
        );
    }
  }

  /// ================= FETCH SUMMARY =================
  Future<void> _fetchSummaryByFilter(int index) async {
    setState(() {
      _isFilterLoading = true;
      _activeFilterIndex = index; // 🔥 SIMPAN STATE FILTER
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final storeId = prefs.getInt('store_id');

    if (token == null || storeId == null) {
      setState(() => _isFilterLoading = false);
      return;
    }

    final range = _getRange(index);

    await ref.read(laporanViewModelProvider.notifier).fetchSummary(
          storeId: storeId,
          token: token,
          start: range.start,
          end: range.end,
        );

    if (mounted) {
      setState(() => _isFilterLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      if (_hasFetched) return;
      _hasFetched = true;

      await _fetchSummaryByFilter(_activeFilterIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(laporanViewModelProvider);
    final summary = state.summary;

    final bool isLoading =
        state.isLoading || _isFilterLoading || summary == null;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ===== FILTER =====
          isLoading
              ? shimmerBox(height: 36)
              : FilterWaktu(
                  activeIndex: _activeFilterIndex,
                  onChanged: _fetchSummaryByFilter,
                ),

          const SizedBox(height: 12),

          /// ===== GRID DASHBOARD =====
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
            ),
            children: isLoading
                ? List.generate(4, (_) => shimmerBox(height: 140))
                : [
                    DashboardCard(
                      title: 'Kas Masuk',
                      value: rupiah(summary!.totalPendapatan),
                      icon: Icons.trending_up,
                      valueColor: Colors.greenAccent,
                    ),
                    DashboardCard(
                      title: 'Penjualan Tertinggi',
                      value: rupiah(summary.bestSalesDay),
                      icon: Icons.show_chart,
                      valueColor: Colors.greenAccent,
                    ),
                    DashboardCard(
                      title: 'Penjualan Terendah',
                      value: rupiah(summary.lowestSalesDay),
                      icon: Icons.trending_down,
                      valueColor: Colors.redAccent,
                      borderColor: Colors.redAccent,
                    ),
                    DashboardCard(
                      title: 'Rata-rata Harian',
                      value: rupiah(summary.avgDaily),
                      icon: Icons.calendar_today,
                      valueColor: Colors.white,
                    ),
                  ],
          ),

          const SizedBox(height: 16),

          /// ===== TOTAL TRANSAKSI =====
          isLoading
              ? shimmerBox(height: 120)
              : _TotalTransaksiCard(
                  total: summary!.totalTransaksi,
                ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _TotalTransaksiCard extends StatelessWidget {
  final int total;

  const _TotalTransaksiCard({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Text(
            'Total Transaksi',
            style: TextStyle(fontSize: 12, color: Colors.white54),
          ),
          const SizedBox(height: 8),
          Text(
            '$total',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'transaksi periode ini',
            style: TextStyle(fontSize: 11, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}
