import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../services/laporan_service.dart';
import '../models/laporan_model.dart';

/// ===============================
/// STATE
/// ===============================
class LaporanState {
  final bool isLoading;
  final String? error;

  final ReportSummary? summary;
  final ReportProduct? productReport;
  final ReportCashier? cashierReport;
  final DailyReport? dailyReport;
  final List<DailyReport> dailyList;
  final List<PeriodicReport> periodicList;

  LaporanState({
    this.isLoading = false,
    this.error,
    this.summary,
    this.productReport,
    this.cashierReport,
    this.dailyReport,
    this.dailyList = const [],
    this.periodicList = const [],
  });

  LaporanState copyWith({
    bool? isLoading,
    String? error,
    ReportSummary? summary,
    ReportProduct? productReport,
    ReportCashier? cashierReport,
    DailyReport? dailyReport,
    List<DailyReport>? dailyList,
    List<PeriodicReport>? periodicList,
  }) {
    return LaporanState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      summary: summary ?? this.summary,
      productReport: productReport ?? this.productReport,
      cashierReport: cashierReport ?? this.cashierReport,
      dailyReport: dailyReport ?? this.dailyReport,
      dailyList: dailyList ?? this.dailyList,
      periodicList: periodicList ?? this.periodicList,
    );
  }
}

/// ===============================
/// VIEWMODEL (FULL LOG)
/// ===============================
class LaporanViewModel extends StateNotifier<LaporanState> {
  LaporanViewModel(this._service) : super(LaporanState()) {
    log('🟢 LaporanViewModel initialized');
  }

  final LaporanService _service;

  // ===============================
  // INTERNAL LOG HELPERS
  // ===============================
  void _logStart(String source, Map<String, dynamic> params) {
    log('━━━━━━━━━━━━━━━━━━━━━━━━');
    log('🧠 VM START   : $source');
    log('🧾 PARAMS     : $params');
  }

  void _logSuccess(String source, [String? info]) {
    log('✅ VM SUCCESS : $source');
    if (info != null) log('📦 DATA       : $info');
  }

  void _logError(String source, Object e) {
    log('❌ VM ERROR   : $source');
    log('💬 MESSAGE    : $e');
  }

  void _logDone(String source) {
    log('🟢 VM DONE    : $source');
    log('━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  void _setLoading(String source) {
    log('⏳ VM LOADING : $source');
    state = state.copyWith(isLoading: true, error: null);
  }

  void _setError(String source, String message) {
    state = state.copyWith(isLoading: false, error: message);
  }

  void _setDone() {
    state = state.copyWith(isLoading: false);
  }

  /// ===============================
  /// 1. SUMMARY
  /// ===============================
  Future<void> fetchSummary({
    required int storeId,
    required String token,
    required DateTime start,
    required DateTime end,
  }) async {
    const source = 'fetchSummary';
    _logStart(source, {
      'storeId': storeId,
      'start': start,
      'end': end,
    });

    try {
      _setLoading(source);

      final data = await _service.getSummaryReport(
        storeId: storeId,
        token: token,
        start: start,
        end: end,
      );

      state = state.copyWith(summary: data);

      _logSuccess(
        source,
        'transaksi=${data.totalTransaksi}, pendapatan=${data.totalPendapatan}',
      );
    } catch (e) {
      _logError(source, e);
      _setError(source, e.toString());
    } finally {
      _setDone();
      _logDone(source);
    }
  }

  /// ===============================
  /// 3. KASIR
  /// ===============================
  Future<void> fetchCashierReport({
    required int storeId,
    required String token,
    required DateTime start,
    required DateTime end,
  }) async {
    const source = 'fetchCashierReport';
    _logStart(source, {
      'storeId': storeId,
      'start': start,
      'end': end,
    });

    try {
      _setLoading(source);

      final data = await _service.getCashierReport(
        storeId: storeId,
        token: token,
        start: start,
        end: end,
      );

      state = state.copyWith(cashierReport: data);

      _logSuccess(
        source,
        'totalKaryawan=${data.totalKaryawan}, avgPerformance=${data.avgPerformance}',
      );
    } catch (e) {
      _logError(source, e);
      _setError(source, e.toString());
    } finally {
      _setDone();
      _logDone(source);
    }
  }

  /// ===============================
  /// 4. GENERATE DAILY
  /// ===============================
  Future<bool> generateDailyReport({
    required int storeId,
    required String token,
    required DateTime date,
  }) async {
    const source = 'generateDailyReport';
    _logStart(source, {
      'storeId': storeId,
      'date': date,
    });

    try {
      _setLoading(source);

      await _service.generateDailyReport(
        storeId: storeId,
        token: token,
        date: date,
      );

      _logSuccess(source, 'generate success');
      return true;
    } catch (e) {
      _logError(source, e);
      _setError(source, e.toString());
      return false;
    } finally {
      _setDone();
      _logDone(source);
    }
  }

  /// ===============================
  /// CLEAR ERROR
  /// ===============================
  void clearError() {
    log('🧹 VM clearError');
    state = state.copyWith(error: null);
  }


  /// ===============================
/// 5. DAILY LIST
/// ===============================
Future<void> fetchDailyList({
  required int storeId,
  required String token,
  required DateTime start,
  required DateTime end,
}) async {
  const source = 'fetchDailyList';
  _logStart(source, {
    'storeId': storeId,
    'start': start,
    'end': end,
  });

  try {
    _setLoading(source);

    final data = await _service.getDailyReportList(
      storeId: storeId,
      token: token,
      start: start,
      end: end,
    );

    state = state.copyWith(dailyList: data);

    _logSuccess(source, 'total=${data.length}');
  } catch (e) {
    _logError(source, e);
    _setError(source, e.toString());
  } finally {
    _setDone();
    _logDone(source);
  }
}

/// ===============================
/// 2. PRODUCT REPORT
/// ===============================
Future<void> fetchProductReport({
  required int storeId,
  required String token,
  required DateTime start,
  required DateTime end,
}) async {
  const source = 'fetchProductReport';
  _logStart(source, {
    'storeId': storeId,
    'start': start,
    'end': end,
  });

  try {
    _setLoading(source);

    final data = await _service.getProductReport(
      storeId: storeId,
      token: token,
      start: start,
      end: end,
    );

    state = state.copyWith(productReport: data);

    _logSuccess(
      source,
      'totalProducts=${data.totalProducts}, sold=${data.totalSold}',
    );
  } catch (e) {
    _logError(source, e);
    _setError(source, e.toString());
  } finally {
    _setDone();
    _logDone(source);
  }
}


}

/// ===============================
/// PROVIDER
/// ===============================
final laporanServiceProvider = Provider<LaporanService>((ref) {
  log('🔌 LaporanService provider created');
  return LaporanService();
});

final laporanViewModelProvider =
    StateNotifierProvider<LaporanViewModel, LaporanState>((ref) {
  log('📦 LaporanViewModel provider created');
  return LaporanViewModel(ref.read(laporanServiceProvider));
});
