import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../viewmodels/laporan_viewmodel.dart';
import '../../viewmodels/plan_viewmodel.dart';
import '../../services/auth_service.dart';
import '../../models/laporan_model.dart';

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

  String role = 'admin'; // DEFAULT
  int? _userId; // 🔥 USER ID LOGIN

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();

      final storeId = prefs.getInt('store_id');
      final token = prefs.getString('token');

      final userRole = await AuthService.getUserRole();
      final userId = prefs.getInt('user_id');

      if (!mounted) return;

      setState(() {
        role = userRole;
        _userId = userId;
      });

      if (storeId == null || token == null || token.isEmpty) {
        log('❌ Dashboard: storeId / token null');
        return;
      }

      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final vm = ref.read(laporanViewModelProvider.notifier);

      if (role == 'cashier') {
        log('👤 DASHBOARD MODE: CASHIER | userId=$_userId');

        vm.fetchCashierReport(
          storeId: storeId,
          token: token,
          start: start,
          end: end,
        );
      } else {
        log('👑 DASHBOARD MODE: OWNER / ADMIN');

        vm.fetchSummary(storeId: storeId, token: token, start: start, end: end);

        vm.fetchProductReport(
          storeId: storeId,
          token: token,
          start: start,
          end: end,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final laporan = ref.watch(laporanViewModelProvider);
    final planAsync = ref.watch(planNotifierProvider);

    final summary = laporan.summary;
    final product = laporan.productReport;
    final cashier = laporan.cashierReport;

    /// 🔥 AMBIL DATA KASIR SESUAI ID LOGIN
    CashierPerformance? cashierData;
    if (role == 'cashier' &&
        cashier != null &&
        cashier.cashiers.isNotEmpty &&
        _userId != null) {
      cashierData = cashier.cashiers.firstWhere(
        (c) => c.id == _userId,
        orElse: () => CashierPerformance(
          id: 0,
          name: '',
          role: '',
          totalTransaksi: 0,
          totalPenjualan: 0.0,
        ),
      );
    }

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
                          const Icon(
                            Icons.credit_card,
                            color: Colors.redAccent,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Langganan',
                            style: TextStyle(
                              color: Colors.white,
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
                      const Divider(color: Colors.white12),
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

            /// ================= TOTAL PENJUALAN =================
            _statCard(
              icon: Icons.attach_money,
              title: 'Total Penjualan Hari Ini',
              value: rupiah.format(
                role == 'cashier'
                    ? (cashierData?.totalPenjualan ?? 0)
                    : (summary?.totalPendapatan ?? 0),
              ),
            ),

            const SizedBox(height: 12),

            /// ================= TRANSAKSI =================
            _statCard(
              icon: Icons.receipt_long,
              title: 'Transaksi Hari Ini',
              value: role == 'cashier'
                  ? (cashierData?.totalTransaksi ?? 0).toString()
                  : (summary?.totalTransaksi ?? 0).toString(),
            ),

            /// ================= OWNER / ADMIN ONLY =================
            if (role != 'cashier') ...[
              const SizedBox(height: 12),
              _statCard(
                icon: Icons.warning_amber_rounded,
                title: 'Stok Menipis',
                value: (summary?.stokMenipis.length ?? 0).toString(),
              ),
              const SizedBox(height: 12),
              _statCard(
                icon: Icons.inventory_2_outlined,
                title: 'Total Produk',
                value: (product?.totalProducts ?? 0).toString(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// ================= UI HELPERS =================

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
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
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
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
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
      ),
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
