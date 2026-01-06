import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../viewmodels/laporan_viewmodel.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/filter_waktu.dart';
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
  /// STATE FILTER
  /// ===============================
  FilterWaktuType _filter = FilterWaktuType.today;

  /// ===============================
  /// INIT (AUTO FETCH SAAT HALAMAN DIBUKA)
  /// ===============================
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

 Future<void> _fetchData() async {
  final prefs = await SharedPreferences.getInstance();

  final storeId = prefs.getInt('store_id');
  final token = prefs.getString('token');

  if (storeId == null || token == null || token.isEmpty) {
    log('❌ LaporanKaryawan: storeId / token null dari session');
    return;
  }

  final range = _getRange(_filter);

  log('🚀 FETCH CASHIER REPORT');
  log('🏬 storeId=$storeId');
  log('🔐 token=${token.substring(0, 10)}...');
  log('🗓 start=${range.start}');
  log('🗓 end=${range.end}');

  ref.read(laporanViewModelProvider.notifier).fetchCashierReport(
        storeId: storeId,
        token: token,
        start: range.start,
        end: range.end,
      );
}

  /// ===============================
  /// RANGE TANGGAL (FIXED)
  /// ===============================
DateTimeRange _getRange(FilterWaktuType type) {
  // 🔥 PAKAI UTC
  final nowUtc = DateTime.now().toUtc();

  late DateTime start;
  late DateTime end;

  switch (type) {
    case FilterWaktuType.today:
      start = DateTime.utc(
        nowUtc.year,
        nowUtc.month,
        nowUtc.day,
        0,
        0,
        0,
      );
      end = DateTime.utc(
        nowUtc.year,
        nowUtc.month,
        nowUtc.day,
        23,
        59,
        59,
      );
      break;

    case FilterWaktuType.last7Days:
      start = DateTime.utc(
        nowUtc.year,
        nowUtc.month,
        nowUtc.day,
      ).subtract(const Duration(days: 6));
      end = nowUtc;
      break;

    case FilterWaktuType.last30Days:
      start = DateTime.utc(
        nowUtc.year,
        nowUtc.month,
        nowUtc.day,
      ).subtract(const Duration(days: 29));
      end = nowUtc;
      break;

    case FilterWaktuType.lastYear:
      start = DateTime.utc(
        nowUtc.year - 1,
        nowUtc.month,
        nowUtc.day,
      );
      end = nowUtc;
      break;

    case FilterWaktuType.all:
      start = DateTime.utc(2000, 1, 1);
      end = nowUtc;
      break;
  }

  return DateTimeRange(start: start, end: end);
}


  /// ===============================
  /// FILTER CLICK
  /// ===============================
  void _onFilterChanged(FilterWaktuType type) {
    setState(() {
      _filter = type;
    });
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(laporanViewModelProvider);
    final cashier = state.cashierReport;

    log('📊 cashierReport null? ${cashier == null}');

    final rupiah = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ================= FILTER =================
            Transform.translate(
              offset: const Offset(0, -4),
              child: FilterWaktu(
                active: _filter,
                onChanged: _onFilterChanged,
              ),
            ),

            const SizedBox(height: 16),

            /// ================= EXPORT =================
            const ExportKaryawanBar(),

            const SizedBox(height: 12),

            /// ================= LOADING =================
            if (state.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                ),
              )

            /// ================= ERROR =================
            else if (state.error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  state.error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              )

            /// ================= DATA =================
            else if (cashier != null) ...[
              /// ===== STAT GRID =====
              Transform.translate(
                offset: const Offset(0, -8),
                child: GridView(
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
                      iconBgColor: const Color(0xFFE53935),
                      value: cashier.totalKaryawan.toString(),
                      label: 'Total Karyawan',
                    ),
                    StatCard(
                      icon: Icons.star_rate_rounded,
                      iconBgColor: const Color(0xFF1F6E43),
                      value:
                          '${cashier.avgPerformance.toStringAsFixed(1)}%',
                      label: 'Rata-rata Performa',
                    ),
                    StatCard(
                      icon: Icons.payments,
                      iconBgColor: const Color(0xFFF9A825),
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
                      iconBgColor: const Color(0xFF0288D1),
                      value:
                          '${cashier.avgAttendance.toStringAsFixed(1)}%',
                      label: 'Kehadiran',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              /// ===== DETAIL PENJUALAN KASIR =====
              CardPenjualanSection(cashiers: cashier.cashiers),
            ]

            /// ================= EMPTY =================
            else
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Tidak ada data laporan',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
