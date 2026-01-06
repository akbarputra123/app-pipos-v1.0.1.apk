import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../config/base_url.dart';
import '../models/laporan_model.dart';

class LaporanService {
  late final Dio _dio;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  LaporanService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: BaseUrl.api,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  /// ===============================
  /// DATE FORMAT
  /// ===============================
  String _apiDate(DateTime date) => _dateFormat.format(date);

  /// ===============================
  /// BUILD DATE QUERY (🔥 FIX UTAMA)
  /// ===============================
  Map<String, dynamic> _buildDateQuery(
    DateTime start,
    DateTime end,
  ) {
    final startDate = _apiDate(start);
    final endDate = _apiDate(end.add(const Duration(days: 1)));

    log('📅 API DATE RANGE');
    log('➡️ start = $startDate');
    log('➡️ end   = $endDate (inclusive fix)');

    return {
      'start': startDate,
      'end': endDate,
    };
  }

  /// ===============================
  /// AUTH HEADER
  /// ===============================
  Options _options(String token) {
    return Options(
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  /// ===============================
  /// LOG HELPERS
  /// ===============================
  void _logRequest({
    required String title,
    required String method,
    required String url,
    Map<String, dynamic>? query,
    dynamic body,
    required String token,
  }) {
    log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    log('📡 [$title] REQUEST');
    log('➡️ METHOD : $method');
    log('➡️ URL    : $url');
    if (query != null && query.isNotEmpty) {
      log('🧾 QUERY  : $query');
    }
    if (body != null) {
      log('📦 BODY   : $body');
    }
    log('🔐 TOKEN  : ${token.isNotEmpty ? "ADA" : "KOSONG"}');
    log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  void _logResponse({
    required String title,
    required Response response,
    required int durationMs,
  }) {
    log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    log('📡 [$title] RESPONSE');
    log('🔢 STATUS : ${response.statusCode}');
    log('⏱️ TIME   : ${durationMs} ms');
    log('📦 BODY   : ${response.data}');
    log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  void _logError({
    required String title,
    required Object error,
    StackTrace? stack,
    Response? response,
  }) {
    log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    log('❌ [$title] ERROR');
    log('💬 MESSAGE : $error');
    if (response != null) {
      log('🔢 STATUS  : ${response.statusCode}');
      log('📦 BODY    : ${response.data}');
    }
    if (stack != null) {
      log('🧨 STACK   : $stack');
    }
    log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  /// ======================================================
  /// 1. SUMMARY REPORT
  /// ======================================================
  Future<ReportSummary> getSummaryReport({
    required int storeId,
    required String token,
    required DateTime start,
    required DateTime end,
  }) async {
    const title = 'SUMMARY REPORT';
    final path = '/api/stores/$storeId/reports/summary';
    final query = _buildDateQuery(start, end);

    final startTime = DateTime.now();
    final url = '${_dio.options.baseUrl}$path';

    _logRequest(
      title: title,
      method: 'GET',
      url: url,
      query: query,
      token: token,
    );

    try {
      final response = await _dio.get(
        path,
        queryParameters: query,
        options: _options(token),
      );

      _logResponse(
        title: title,
        response: response,
        durationMs:
            DateTime.now().difference(startTime).inMilliseconds,
      );

      if (response.statusCode == 200 &&
          response.data['success'] == true) {
        return ReportSummary.fromJson(response.data['data']);
      }

      throw Exception(response.data['message']);
    } catch (e, st) {
      _logError(
        title: title,
        error: e,
        stack: st,
        response: e is DioException ? e.response : null,
      );
      rethrow;
    }
  }

  /// ======================================================
  /// 2. PRODUCT REPORT
  /// ======================================================
  Future<ReportProduct> getProductReport({
    required int storeId,
    required String token,
    required DateTime start,
    required DateTime end,
  }) async {
    const title = 'PRODUCT REPORT';
    final path = '/api/stores/$storeId/reports/products';
    final query = _buildDateQuery(start, end);

    final startTime = DateTime.now();
    final url = '${_dio.options.baseUrl}$path';

    _logRequest(
      title: title,
      method: 'GET',
      url: url,
      query: query,
      token: token,
    );

    try {
      final response = await _dio.get(
        path,
        queryParameters: query,
        options: _options(token),
      );

      _logResponse(
        title: title,
        response: response,
        durationMs:
            DateTime.now().difference(startTime).inMilliseconds,
      );

      if (response.statusCode == 200 &&
          response.data['success'] == true) {
        return ReportProduct.fromJson(response.data['data']);
      }

      throw Exception(response.data['message']);
    } catch (e, st) {
      _logError(
        title: title,
        error: e,
        stack: st,
        response: e is DioException ? e.response : null,
      );
      rethrow;
    }
  }

  /// ======================================================
  /// 3. CASHIER REPORT
  /// ======================================================
  Future<ReportCashier> getCashierReport({
    required int storeId,
    required String token,
    required DateTime start,
    required DateTime end,
  }) async {
    const title = 'CASHIER REPORT';
    final path = '/api/stores/$storeId/reports/cashiers';
    final query = _buildDateQuery(start, end);

    final startTime = DateTime.now();
    final url = '${_dio.options.baseUrl}$path';

    _logRequest(
      title: title,
      method: 'GET',
      url: url,
      query: query,
      token: token,
    );

    try {
      final response = await _dio.get(
        path,
        queryParameters: query,
        options: _options(token),
      );

      _logResponse(
        title: title,
        response: response,
        durationMs:
            DateTime.now().difference(startTime).inMilliseconds,
      );

      if (response.statusCode == 200 &&
          response.data['success'] == true) {
        return ReportCashier.fromJson(response.data['data']);
      }

      throw Exception(response.data['message']);
    } catch (e, st) {
      _logError(
        title: title,
        error: e,
        stack: st,
        response: e is DioException ? e.response : null,
      );
      rethrow;
    }
  }

  /// ======================================================
  /// 4. DAILY REPORT LIST
  /// ======================================================
  Future<List<DailyReport>> getDailyReportList({
    required int storeId,
    required String token,
    required DateTime start,
    required DateTime end,
  }) async {
    const title = 'DAILY REPORT LIST';
    final path = '/api/stores/$storeId/reports/daily/list';
    final query = _buildDateQuery(start, end);

    final startTime = DateTime.now();
    final url = '${_dio.options.baseUrl}$path';

    _logRequest(
      title: title,
      method: 'GET',
      url: url,
      query: query,
      token: token,
    );

    try {
      final response = await _dio.get(
        path,
        queryParameters: query,
        options: _options(token),
      );

      _logResponse(
        title: title,
        response: response,
        durationMs:
            DateTime.now().difference(startTime).inMilliseconds,
      );

      if (response.statusCode == 200 &&
          response.data['success'] == true) {
        return (response.data['data'] as List)
            .map((e) => DailyReport.fromJson(e))
            .toList();
      }

      throw Exception(response.data['message']);
    } catch (e, st) {
      _logError(
        title: title,
        error: e,
        stack: st,
        response: e is DioException ? e.response : null,
      );
      rethrow;
    }
  }

  /// ======================================================
  /// 5. GENERATE DAILY REPORT
  /// ======================================================
  Future<String> generateDailyReport({
    required int storeId,
    required String token,
    required DateTime date,
  }) async {
    const title = 'GENERATE DAILY REPORT';
    final path = '/api/stores/$storeId/reports/daily/generate';
    final query = {
      'date': _apiDate(date),
    };

    final startTime = DateTime.now();
    final url = '${_dio.options.baseUrl}$path';

    _logRequest(
      title: title,
      method: 'POST',
      url: url,
      query: query,
      token: token,
    );

    try {
      final response = await _dio.post(
        path,
        queryParameters: query,
        options: _options(token),
      );

      _logResponse(
        title: title,
        response: response,
        durationMs:
            DateTime.now().difference(startTime).inMilliseconds,
      );

      if (response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data['data']['message'] ??
            'Laporan berhasil dibuat';
      }

      throw Exception(response.data['message']);
    } catch (e, st) {
      _logError(
        title: title,
        error: e,
        stack: st,
        response: e is DioException ? e.response : null,
      );
      rethrow;
    }
  }
}
