import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '../../../models/laporan_model.dart';
import '../../../../viewmodels/laporan_viewmodel.dart';
import '../widgets/filter_waktu.dart';
import 'widgets/export.dart';
import 'widgets/card.dart';
import 'widgets/card_penjualan.dart';

class LaporanKaryawanScreen extends ConsumerStatefulWidget {
  const LaporanKaryawanScreen({super.key});

  @override
  ConsumerState<LaporanKaryawanScreen> createState() =>
      _LaporanKaryawanScreenState();
}

class _LaporanKaryawanScreenState
    extends ConsumerState<LaporanKaryawanScreen> {
  /// ===============================
  /// FILTER STATE
  /// ===============================
  FilterRange _filter = FilterRange.today;

  /// ===============================
  /// CACHE (ANTI KEDIP)
  /// ===============================
 ReportCashier? _cachedCashier;

  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  /// ===============================
  /// FETCH DATA (TANPA RESET UI)
  /// ===============================
  Future<void> _fetchData() async {
    if (_isFetching) return;
    _isFetching = true;

    final prefs = await SharedPreferences.getInstance();
    final storeId = prefs.getInt('store_id');
    final token = prefs.getString('token');

    if (storeId == null || token == null || token.isEmpty) {
      log('❌ storeId / token null');
      _isFetching = false;
      return;
    }

    final range = _getRange(_filter);

    await ref.read(laporanViewModelProvider.notifier).fetchCashierReport(
          storeId: storeId,
          token: token,
          start: range.start,
          end: range.end,
        );

    /// 🔥 AMBIL DATA TERBARU TANPA MENGOSONGKAN UI
    final state = ref.read(laporanViewModelProvider);
    if (state.cashierReport != null) {
      setState(() {
        _cachedCashier = state.cashierReport;
      });
    }

    _isFetching = false;
  }

  /// ===============================
  /// RANGE TANGGAL
  /// ===============================
  DateTimeRange _getRange(FilterRange type) {
    final nowUtc = DateTime.now().toUtc();

    switch (type) {
      case FilterRange.today:
        return DateTimeRange(
          start: DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day),
          end: DateTime.utc(
            nowUtc.year,
            nowUtc.month,
            nowUtc.day,
            23,
            59,
            59,
          ),
        );

      case FilterRange.last7Days:
        return DateTimeRange(
          start: DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day)
              .subtract(const Duration(days: 6)),
          end: nowUtc,
        );

      case FilterRange.last30Days:
        return DateTimeRange(
          start: DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day)
              .subtract(const Duration(days: 29)),
          end: nowUtc,
        );

      case FilterRange.oneYear:
        return DateTimeRange(
          start: DateTime.utc(nowUtc.year - 1, nowUtc.month, nowUtc.day),
          end: nowUtc,
        );

      case FilterRange.all:
        return DateTimeRange(
          start: DateTime.utc(2000, 1, 1),
          end: nowUtc,
        );
    }
  }

  void _onFilterChanged(FilterRange type) {
    setState(() => _filter = type);
    _fetchData(); // 🔥 UI TIDAK DIRESET
  }

  /// ===============================
  /// SHIMMER (HANYA FIRST LOAD)
  /// ===============================
  Widget _shimmerBox(BuildContext context,
      {double height = 80, BorderRadius? radius}) {
    final theme = Theme.of(context);

    return Shimmer.fromColors(
      baseColor: theme.cardColor,
      highlightColor: theme.cardColor.withOpacity(
        theme.brightness == Brightness.dark ? 0.6 : 0.4,
      ),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: radius ?? BorderRadius.circular(14),
        ),
      ),
    );
  }

  /// ===============================
  /// BUILD
  /// ===============================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(laporanViewModelProvider);

    /// 🔥 PAKAI CACHE JIKA ADA
    final cashier = state.cashierReport ?? _cachedCashier;

    final rupiah = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
     
       
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ================= FILTER =================
            FilterWaktu(
              active: _filter,
              onChanged: _onFilterChanged,
            ),

            const SizedBox(height: 16),

            /// ================= EXPORT =================
            cashier == null
                ? _shimmerBox(context, height: 44)
                : const ExportKaryawanBar(),

      const SizedBox(height: 16),

            /// ================= FIRST LOAD SHIMMER =================
            if (cashier == null) ...[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.2,
                ),
                itemCount: 4,
                itemBuilder: (_, __) =>
                    _shimmerBox(context, height: 72),
              ),
              const SizedBox(height: 16),
              _shimmerBox(context, height: 160),
            ]

            /// ================= DATA =================
            else ...[
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.2,
                ),
                children: [
                  StatCard(
                    icon: Icons.people,
                    iconBgColor: theme.colorScheme.error,
                    value: cashier.totalKaryawan.toString(),
                    label: 'Total Karyawan',
                  ),
                  StatCard(
                    icon: Icons.star_rate_rounded,
                    iconBgColor: Colors.green,
                    value:
                        '${cashier.avgPerformance.toStringAsFixed(1)}%',
                    label: 'Rata-rata Performa',
                  ),
                  StatCard(
                    icon: Icons.payments,
                    iconBgColor: Colors.orange,
                    value: rupiah.format(
                      cashier.cashiers.fold<double>(
                        0,
                        (sum, e) => sum + e.totalPenjualan,
                      ),
                    ),
                    label: 'Total Penjualan',
                  ),
                  StatCard(
                    icon: Icons.access_time,
                    iconBgColor: Colors.blue,
                    value:
                        '${cashier.avgAttendance.toStringAsFixed(1)}%',
                    label: 'Kehadiran',
                  ),
                ],
              ),

              const SizedBox(height: 12),

              CardPenjualanSection(cashiers: cashier.cashiers),
            ],
          ],
        ),
      );
    
  }
}
