import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/base_url.dart';
import '../models/store_profile_model.dart';
import 'auth_service.dart';

class ProfileService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: BaseUrl.api,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await AuthService.getToken() ?? '';
          if (token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );

  /// ============================
  /// GET STORE ID FROM SESSION
  /// ============================
  static Future<int?> _getStoreId() async {
    final prefs = await SharedPreferences.getInstance();
    final storeId = prefs.getInt('store_id');
    print("🔹 ProfileService: storeId = $storeId");
    return storeId;
  }

  /// ============================
  /// GET STORE PROFILE
  /// ============================
  static Future<StoreProfile?> getStoreProfile() async {
    try {
      final storeId = await _getStoreId();
      if (storeId == null) {
        print("❌ storeId null, request dibatalkan");
        return null;
      }

      final response = await _dio.get('/api/stores/$storeId');
      print("📥 GET STORE PROFILE → ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final store = StoreProfile.fromJson(data);
        print("✅ Parsing StoreProfile berhasil");
        return store;
      }

      print("❌ GET STORE PROFILE gagal");
      return null;
    } catch (e, stackTrace) {
      print("❌ GET STORE PROFILE ERROR: $e");
      print(stackTrace);
      return null;
    }
  }

  /// ============================
  /// GET TAX PERCENTAGE
  /// ============================
  static Future<double> getTaxPercentage() async {
    try {
      final store = await getStoreProfile();
      return store?.taxPercentage ?? 0.0;
    } catch (e) {
      print("🔥 getTaxPercentage error: $e");
      return 0.0;
    }
  }

  /// ============================
  /// UPDATE TAX / PPN
  /// ============================
  static Future<bool> updateTaxPercentage(double tax) async {
    try {
      print('================ UPDATE PPN =================');
      print('📤 Tax               : $tax %');

      final storeId = await _getStoreId();
      if (storeId == null) {
        print('❌ Store ID null');
        return false;
      }

      final response = await _dio.put(
        '/api/stores/$storeId',
        data: {
          "tax_percentage": tax,
        },
      );

      print('📥 Status Code       : ${response.statusCode}');
      print('📥 Response Data     : ${response.data}');

      return response.statusCode == 200;
    } on DioException catch (e) {
      print('🚨 UPDATE PPN DIO ERROR');
      print(e.response?.data);
      return false;
    }
  }

  /// ============================
  /// UPDATE STORE PROFILE
  /// ============================
  static Future<StoreProfile?> updateProfile(
    Map<String, dynamic> dataMap,
  ) async {
    try {
      print('================ UPDATE STORE =================');
      print('📤 Request Data      : $dataMap');

      final storeId = await _getStoreId();
      if (storeId == null) {
        print('❌ Store ID null');
        return null;
      }

      final response = await _dio.put(
        '/api/stores/$storeId',
        data: dataMap,
      );

      print('📥 Status Code       : ${response.statusCode}');
      print('📥 Response Data     : ${response.data}');

      if (response.statusCode == 200) {
        return StoreProfile.fromJson(response.data['data']);
      }

      return null;
    } on DioException catch (e) {
      print('🚨 UPDATE STORE DIO ERROR');
      print(e.response?.data);
      return null;
    }
  }

  /// ============================
  /// DELETE STORE PROFILE
  /// ============================
  static Future<bool> deleteProfile() async {
    try {
      final storeId = await _getStoreId();
      if (storeId == null) return false;

      final response = await _dio.delete('/api/stores/$storeId');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ DELETE STORE ERROR: $e');
      return false;
    }
  }

  /// ============================
  /// CREATE STORE PROFILE
  /// ============================
  static Future<StoreProfile?> createProfile(
    Map<String, dynamic> dataMap,
  ) async {
    try {
      final response = await _dio.post('/api/stores', data: dataMap);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return StoreProfile.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      print('❌ CREATE STORE ERROR: $e');
      return null;
    }
  }
}
