import 'package:dio/dio.dart';
import '../config/base_url.dart';
import '../models/kelola_user.dart';
import 'auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
class KelolaUserService {
  static final Dio _dio = Dio();

  /// =====================
  /// Ambil semua user berdasarkan store_id dari session
  /// =====================
static Future<List<KelolaUser>> getUsers() async {
  try {
    final token = await AuthService.getToken();
    final prefs = await SharedPreferences.getInstance();
    final storeId = prefs.getInt('store_id');

    // 🔍 LOG DEBUG
    print('📦 DEBUG getUsers');
    print('➡️ store_id : $storeId');
    print('➡️ token    : ${token != null ? "ADA" : "NULL"}');

    if (storeId == null || token == null) {
      print("❌ Store ID atau Token tidak tersedia");
      return [];
    }

    final url = '${BaseUrl.api}/api/stores/$storeId/users';
    print('🌐 Request URL: $url');

    final response = await _dio.get(
      url,
      options: Options(
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ),
    );

    print('📥 Status Code: ${response.statusCode}');
    print('📦 Response Data: ${response.data}');

    if (response.statusCode == 200) {
      final kelolaUserResponse = KelolaUserResponse.fromJson(response.data);
      return kelolaUserResponse.data;
    } else {
      print("❌ Gagal mengambil user: ${response.statusCode}");
      return [];
    }
  } catch (e, s) {
    print("❌ Error getUsers: $e");
    print("📌 StackTrace: $s");
    return [];
  }
}


  /// =====================
  /// Tambah user
  /// =====================
  static Future<bool> createUser(KelolaUser user) async {
    try {
      final token = await AuthService.getToken();
      final prefs = await SharedPreferences.getInstance();
      final storeId = prefs.getInt('store_id');

      if (storeId == null || token == null) {
        print("❌ Store ID atau Token tidak tersedia");
        return false;
      }

      final url = '${BaseUrl.api}/api/stores/$storeId/users';

      final response = await _dio.post(
        url,
        data: user.toJson(),
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print("❌ Gagal menambahkan user: ${response.data}");
        return false;
      }
    } catch (e) {
      print("❌ Error createUser: $e");
      return false;
    }
  }

  /// =====================
  /// Update user
  /// =====================
  static Future<bool> updateUser(KelolaUser user) async {
    try {
      final token = await AuthService.getToken();
      final prefs = await SharedPreferences.getInstance();
      final storeId = prefs.getInt('store_id');

      if (storeId == null || token == null) {
        print("❌ Store ID atau Token tidak tersedia");
        return false;
      }

      final url = '${BaseUrl.api}/api/stores/$storeId/users/${user.id}';

      final response = await _dio.put(
        url,
        data: user.toJson(),
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
        ),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("❌ Gagal memperbarui user: ${response.data}");
        return false;
      }
    } catch (e) {
      print("❌ Error updateUser: $e");
      return false;
    }
  }

  /// =====================
  /// Hapus user
  /// =====================
  static Future<bool> deleteUser(int userId) async {
    try {
      final token = await AuthService.getToken();
      final prefs = await SharedPreferences.getInstance();
      final storeId = prefs.getInt('store_id');

      if (storeId == null || token == null) {
        print("❌ Store ID atau Token tidak tersedia");
        return false;
      }

      final url = '${BaseUrl.api}/api/stores/$storeId/users/$userId';

      final response = await _dio.delete(
        url,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
        ),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("❌ Gagal menghapus user: ${response.data}");
        return false;
      }
    } catch (e) {
      print("❌ Error deleteUser: $e");
      return false;
    }
  }
}
