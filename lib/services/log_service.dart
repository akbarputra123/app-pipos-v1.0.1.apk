import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/base_url.dart';
import '../models/log_model.dart';

class LogService {
  late final Dio _dio;

  LogService() {
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
  /// AUTH HEADER
  /// ===============================
  Options _options(String token) {
    return Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
  }

  /// ===============================
  /// GET ACTIVITY LOGS
  /// ===============================
  Future<LogResponse?> getActivityLogs({
    int page = 1,
    int limit = 10,
  }) async {
    const title = 'ACTIVITY LOGS';

    try {
      /// ===============================
      /// AMBIL TOKEN & STORE DARI LOGIN
      /// ===============================
      final prefs = await SharedPreferences.getInstance();
      final storeId = prefs.getInt('store_id');
      final token = prefs.getString('token');

      if (storeId == null || token == null || token.isEmpty) {
        log('❌ [$title] store_id / token tidak tersedia');
        return null;
      }

      final path = '/api/stores/$storeId/activity-logs';
      final query = {
        'page': page,
        'limit': limit,
      };

      final startTime = DateTime.now();
      final url = '${_dio.options.baseUrl}$path';

      /// ===============================
      /// LOG REQUEST
      /// ===============================
      log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      log('📡 [$title] REQUEST');
      log('➡️ METHOD : GET');
      log('➡️ URL    : $url');
      log('🧾 QUERY  : $query');
      log('🔐 TOKEN  : ${token.substring(0, 12)}...');
      log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      final response = await _dio.get(
        path,
        queryParameters: query,
        options: _options(token),
      );

      /// ===============================
      /// LOG RESPONSE
      /// ===============================
      log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      log('📡 [$title] RESPONSE');
      log('🔢 STATUS : ${response.statusCode}');
      log(
        '⏱️ TIME   : ${DateTime.now().difference(startTime).inMilliseconds} ms',
      );
      log('📦 BODY   : ${response.data}');
      log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      if (response.statusCode == 200 &&
          response.data != null &&
          response.data['success'] == true) {
        /// 🔥 SESUAI MODEL KAMU
        return LogResponse.fromJson(response.data);
      }

      throw Exception(
        response.data?['message'] ?? 'Gagal mengambil activity log',
      );
    } on DioException catch (e, st) {
      log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      log('❌ [$title] DIO ERROR');
      log('💬 MESSAGE : ${e.message}');
      if (e.response != null) {
        log('🔢 STATUS  : ${e.response?.statusCode}');
        log('📦 BODY    : ${e.response?.data}');
      }
      log('🧨 STACK   : $st');
      log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    } catch (e, st) {
      log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      log('❌ [$title] ERROR');
      log('💬 MESSAGE : $e');
      log('🧨 STACK   : $st');
      log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    }
  }
}
