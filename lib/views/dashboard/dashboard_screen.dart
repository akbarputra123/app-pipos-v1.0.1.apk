import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/laporan_model.dart';
import '../../viewmodels/laporan_viewmodel.dart';
import '../../viewmodels/plan_viewmodel.dart';
import '../../viewmodels/kelola_produk_viewmodel.dart';
import '../../services/auth_service.dart';
import '../dashboard/widgets/shimer.dart';

/// ================= STORE ID PROVIDER =================
final storeIdProvider = FutureProvider<int?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt('store_id');
});

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  String? role;
  int? userId;
  bool _hasListener = false;

  @override
  void initState() {
    super.initState();
    _loadDashboard();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(kelolaProdukViewModelProvider.notifier).getProduk();
    });
  }

  CashierPerformance? _getActiveCashier(
    ReportCashier? report,
    int? userId,
  ) {
    if (report == null || userId == null) return null;

    return report.cashiers.firstWhere(
      (c) => c.id == userId,
      orElse: () => CashierPerformance(
        id: userId,
        name: '',
        role: 'cashier',
        totalTransaksi: 0,
        totalPenjualan: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasListener) {
      _hasListener = true;
      ref.listen<AsyncValue<int?>>(storeIdProvider, (_, __) {
        log('🔁 Store berubah → reload dashboard');
        _loadDashboard();
      });
    }

    final theme = Theme.of(context);
    final laporan = ref.watch(laporanViewModelProvider);
    final planAsync = ref.watch(planNotifierProvider);

    final produkState = ref.watch(kelolaProdukViewModelProvider);
    final produkList = produkState.products;

    final totalProduk = produkList.length;
    final stokMenipis =
        produkList.where((p) => p.stock > 0 && p.stock < 10).length;

    if (role == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final summary = laporan.summary;
    final cashierReport = laporan.cashierReport;

    final cashierData =
        role == 'cashier' ? _getActiveCashier(cashierReport, userId) : null;

    final totalPenjualanHariIni = role == 'cashier'
        ? cashierData?.totalPenjualan ?? 0
        : summary?.totalPendapatan ?? 0;

    final totalTransaksiHariIni = role == 'cashier'
        ? cashierData?.totalTransaksi ?? 0
        : summary?.totalTransaksi ?? 0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// ================= LANGGANAN =================
            planAsync.when(
              loading: () => _skeleton(120),
              error: (e, _) => _errorCard(e.toString()),
              data: (plan) {
                final data = plan?.data;
                final sisaHari = data != null
                    ? data.endDate.difference(DateTime.now()).inDays
                    : 0;

                return _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.credit_card,
                              color: Colors.redAccent, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Langganan',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          _badge(
                            text: data?.status.toUpperCase() ?? '-',
                            color: const Color(0xFF4ADE80),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(color: theme.dividerColor),
                      _infoRow('Plan', data?.plan ?? '-'),
                      _infoRow(
                        'Berakhir',
                        data != null
                            ? DateFormat(
                                'dd MMMM yyyy',
                                'id_ID',
                              ).format(data.endDate)
                            : '-',
                      ),
                      _infoRow(
                        'Sisa Waktu',
                        '$sisaHari Hari Lagi',
                        valueColor: const Color(0xFF4ADE80),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            _statCard(
              icon: Icons.attach_money,
              title: 'Total Penjualan Hari Ini',
              value: rupiah.format(totalPenjualanHariIni),
            ),
            const SizedBox(height: 12),

            _statCard(
              icon: Icons.receipt_long,
              title: 'Transaksi Hari Ini',
              value: totalTransaksiHariIni.toString(),
            ),
            const SizedBox(height: 12),

            _statCard(
              icon: Icons.warning_amber_rounded,
              title: 'Stok Menipis',
              value: stokMenipis.toString(),
            ),
            const SizedBox(height: 12),

            _statCard(
              icon: Icons.inventory_2_outlined,
              title: 'Total Produk',
              value: totalProduk.toString(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadDashboard() async {
    final prefs = await SharedPreferences.getInstance();
    final storeId = prefs.getInt('store_id');
    final token = prefs.getString('token');
    final uid = prefs.getInt('user_id');
    final userRole = await AuthService.getUserRole();

    if (!mounted || storeId == null || token == null || token.isEmpty) return;

    setState(() {
      role = userRole;
      userId = uid;
    });

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final vm = ref.read(laporanViewModelProvider.notifier);
    vm.state = LaporanState();

    final futures = <Future>[
      vm.fetchSummary(storeId: storeId, token: token, start: start, end: end),
    ];

    if (userRole == 'cashier') {
      futures.add(
        vm.fetchCashierReport(
          storeId: storeId,
          token: token,
          start: start,
          end: end,
        ),
      );
    }

    await Future.wait(futures);
  }

  /// ================= UI HELPERS =================
  Widget _card({required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: child,
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              borderRadius:
                  BorderRadius.horizontal(left: Radius.circular(16)),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.redAccent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color:
                        theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color:
                    theme.textTheme.bodySmall?.color?.withOpacity(0.6),
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor ?? theme.textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _skeleton(double height) {
    return ShimmerCard(
      height: height,
      borderRadius: BorderRadius.circular(16),
    );
  }

  Widget _errorCard(String msg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(msg, style: const TextStyle(color: Colors.redAccent)),
    );
  }
}
