import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/base_url.dart';
import '../models/owner_profile_model.dart';
import 'auth_service.dart';

class OwnerProfileService {
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
  /// GET OWNER ID FROM SESSION
  /// ============================
  static Future<int?> _getOwnerId() async {
    final prefs = await SharedPreferences.getInstance();
    final ownerId = prefs.getInt('owner_id');
    print("🔹 OwnerProfileService: ownerId = $ownerId");
    return ownerId;
  }

  /// ============================
  /// GET OWNER PROFILE
  /// Endpoint: /api/owners/{owner_id}
  /// ============================
  static Future<OwnerProfile?> getOwnerProfile() async {
    try {
      final ownerId = await _getOwnerId();
      if (ownerId == null) {
        print("❌ OwnerProfileService: ownerId null, request dibatalkan");
        return null;
      }

      final response = await _dio.get('/api/owners/$ownerId');
      print("📥 GET OWNER PROFILE → ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final owner = OwnerProfile.fromJson(data);
        print("✅ Parsing OwnerProfile berhasil");
        return owner;
      }

      print("❌ GET OWNER PROFILE gagal");
      print("❌ Response Data: ${response.data}");
      return null;
    } on DioException catch (e) {
      print("🚨 GET OWNER PROFILE DIO ERROR");
      print("🚨 Status Code : ${e.response?.statusCode}");
      print("🚨 Data        : ${e.response?.data}");
      return null;
    } catch (e, stackTrace) {
      print("🔥 GET OWNER PROFILE ERROR: $e");
      print(stackTrace);
      return null;
    }
  }

  /// ============================
  /// UPDATE OWNER PROFILE
  /// ============================
  static Future<OwnerProfile?> updateOwnerProfile(
    Map<String, dynamic> dataMap,
  ) async {
    try {
      print('================ UPDATE OWNER =================');
      print('📤 Request Data      : $dataMap');

      final ownerId = await _getOwnerId();
      if (ownerId == null) {
        print('❌ Owner ID null');
        return null;
      }

      final response = await _dio.put(
        '/api/owners/$ownerId',
        data: dataMap,
      );

      print('📥 Status Code       : ${response.statusCode}');
      print('📥 Response Data     : ${response.data}');

      if (response.statusCode == 200) {
        return OwnerProfile.fromJson(response.data['data']);
      }

      print('❌ UPDATE OWNER FAILED');
      return null;
    } on DioException catch (e) {
      print('🚨 UPDATE OWNER DIO ERROR');
      print(e.response?.data);
      return null;
    } catch (e, stackTrace) {
      print('🔥 UPDATE OWNER ERROR: $e');
      print(stackTrace);
      return null;
    }
  }
}
