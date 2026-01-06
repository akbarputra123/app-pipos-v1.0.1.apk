// =======================================================
// SERVICE BACKUP DATA (EXPORT)
// Endpoint : /api/backup/export
// TOKEN DARI LOGIN (SharedPreferences)
// LOG LENGKAP
// =======================================================

import 'dart:developer';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/base_url.dart';

class BackupDataService {
  late final Dio _dio;

  BackupDataService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: BaseUrl.api,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    /// ================= INTERCEPTOR (TOKEN + LOG) =================
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('token');

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          options.extra['startTime'] = DateTime.now();

          log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          log('📡 BACKUP EXPORT REQUEST');
          log('➡️ ${options.method} ${options.baseUrl}${options.path}');
          log('🧾 Body    : ${options.data}');
          log('🧾 Headers : ${options.headers}');
          log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

          handler.next(options);
        },
        onResponse: (response, handler) {
          final startTime = response.requestOptions.extra['startTime'];
          final duration = startTime != null
              ? DateTime.now().difference(startTime)
              : null;

          log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          log('✅ BACKUP EXPORT RESPONSE');
          log('⬅️ Status : ${response.statusCode}');
          log('📦 Type   : ${response.headers.value('content-type')}');
          log('📦 Size   : ${_calculateSize(response.data)}');
          if (duration != null) {
            log('⏱️ Time   : ${duration.inMilliseconds} ms');
          }
          log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

          handler.next(response);
        },
        onError: (DioException e, handler) {
          final startTime = e.requestOptions.extra['startTime'];
          final duration = startTime != null
              ? DateTime.now().difference(startTime)
              : null;

          log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          log('❌ BACKUP EXPORT ERROR');
          log('➡️ ${e.requestOptions.method} '
              '${e.requestOptions.baseUrl}${e.requestOptions.path}');
          log('❗ Message : ${e.message}');
          if (e.response != null) {
            log('❗ Status  : ${e.response?.statusCode}');
            log('❗ Data    : ${e.response?.data}');
          }
          if (duration != null) {
            log('⏱️ Time    : ${duration.inMilliseconds} ms');
          }
          log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

          handler.next(e);
        },
      ),
    );
  }

  /// =======================================================
  /// EXPORT DATA (SINGLE / MULTI -> ZIP)
  /// =======================================================
  Future<Uint8List> exportData({
    required List<String> dataList, // 🔥 FIX
    required String type,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _dio.get(
  '/api/backup/export',
  queryParameters: {
    'data': dataList.join(','),
    'type': type,
  },
  options: Options(responseType: ResponseType.bytes),
);

      return Uint8List.fromList(response.data);
    } on DioException catch (e) {
      String message = 'Gagal export data';

      if (e.response?.data != null) {
        try {
          if (e.response!.data is List<int>) {
            final decoded =
                String.fromCharCodes(e.response!.data as List<int>);
            if (decoded.contains('{')) {
              message = decoded;
            }
          } else if (e.response!.data is Map &&
              e.response!.data['message'] != null) {
            message = e.response!.data['message'];
          }
        } catch (_) {}
      }

      throw Exception(message);
    }
  }

  /// ================= HELPER SIZE =================
  String _calculateSize(dynamic data) {
    if (data is List<int>) {
      final kb = data.length / 1024;
      return kb > 1024
          ? '${(kb / 1024).toStringAsFixed(2)} MB'
          : '${kb.toStringAsFixed(2)} KB';
    }
    return '-';
  }
}
