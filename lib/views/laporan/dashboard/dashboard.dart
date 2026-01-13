import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../viewmodels/laporan_viewmodel.dart';
import '../../../models/laporan_model.dart';
import '../widgets/filter_waktu.dart';
import 'widgets/card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _hasFetched = false;
  bool _isFetching = false;

  FilterRange _activeFilter = FilterRange.today;
  ReportSummary? _cachedSummary;

  /// ================= FORMAT =================
  String rupiah(int value) {
    return 'Rp ${value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => '.',
    )}';
  }

List<double> chartFromDaily(
  List<DailyReport> list,
  int Function(DailyReport r) selector,
) {
  if (list.isEmpty) return List.filled(7, 0);

  final sorted = [...list]
    ..sort((a, b) => a.reportDate.compareTo(b.reportDate));

  final last7 = sorted.length > 7
      ? sorted.sublist(sorted.length - 7)
      : sorted;

  return last7.map((e) => selector(e).toDouble()).toList();
}
  /// ================= SHIMMER =================
  Widget shimmerBox(BuildContext context, {double height = 60}) {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.cardColor,
      highlightColor: theme.cardColor.withOpacity(
        theme.brightness == Brightness.dark ? 0.6 : 0.4,
      ),
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
  /// ================= RANGE =================
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

  /// ================= FETCH =================
  Future<void> _fetchSummaryByFilter(FilterRange filter) async {
    if (_isFetching || filter == _activeFilter) return;

    _isFetching = true;
    setState(() => _activeFilter = filter);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final storeId = prefs.getInt('store_id');
    if (token == null || storeId == null) {
      _isFetching = false;
      return;
    }

    final range = _resolveRange(filter);

    await Future.wait([
      ref.read(laporanViewModelProvider.notifier).fetchSummary(
            storeId: storeId,
            token: token,
            start: range.start,
            end: range.end,
          ),
      ref.read(laporanViewModelProvider.notifier).fetchDailyList(
            storeId: storeId,
            token: token,
            start: range.start,
            end: range.end,
          ),
    ]);

    final state = ref.read(laporanViewModelProvider);
    if (mounted && state.summary != null) {
      setState(() => _cachedSummary = state.summary);
    }

    _isFetching = false;
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (_hasFetched) return;
      _hasFetched = true;
      await _fetchSummaryByFilter(_activeFilter);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(laporanViewModelProvider);
    final summary = state.summary ?? _cachedSummary;
    final dailyList = state.dailyList;
    final bool firstLoad = summary == null;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilterWaktu(
            active: _activeFilter,
            onChanged: _fetchSummaryByFilter,
          ),
          const SizedBox(height: 12),

          firstLoad
              ? GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.35,
                  ),
                  children: List.generate(
                    4,
                    (_) => shimmerBox(context, height: 140),
                  ),
                )
              : GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.35,
                  ),
                  children: [
                    DashboardCard(
                      title: 'Kas Masuk',
                      value: rupiah(summary.totalPendapatan),
                      icon: Icons.trending_up,
                      valueColor: Colors.greenAccent,
                      chartData: chartFromDaily(
                        dailyList,
                        (r) => r.totalIncome,
                      ),
                    ),
                    DashboardCard(
                      title: 'Penjualan Tertinggi',
                      value: rupiah(summary.bestSalesDay),
                      icon: Icons.show_chart,
                      valueColor: Colors.greenAccent,
                      chartData: chartFromDaily(
                        dailyList,
                        (r) => r.totalIncome,
                      ),
                    ),
                    DashboardCard(
                      title: 'Penjualan Terendah',
                      value: rupiah(summary.lowestSalesDay),
                      icon: Icons.trending_down,
                      valueColor: theme.colorScheme.error,
                      borderColor: theme.colorScheme.error,
                      chartData: chartFromDaily(
                        dailyList,
                        (r) => r.totalIncome,
                      ),
                    ),
                    DashboardCard(
                      title: 'Rata-rata Harian',
                      value: rupiah(summary.avgDaily),
                      icon: Icons.calendar_today,
                      valueColor:
                          theme.textTheme.bodyLarge?.color ?? Colors.white,
                      chartData: chartFromDaily(
                        dailyList,
                        (r) => r.avgDaily,
                      ),
                    ),
                  ],
                ),

          const SizedBox(height: 16),

          firstLoad
              ? shimmerBox(context, height: 120)
              : _TotalTransaksiCard(
                  total: summary.totalTransaksi,
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
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Text(
            'Total Transaksi',
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            '$total',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'transaksi periode ini',
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
