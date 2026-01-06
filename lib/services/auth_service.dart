// lib/services/auth_service.dart

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/base_url.dart';
import '../models/user_model.dart';

class AuthService {
  static const String loginEndpoint = "/api/auth/login";

  // Instance Dio
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
  );

  /// =====================
  /// LOGIN
  /// =====================
static Future<AuthResponse?> login({
  required String identifier, // username / email
  required String password,
}) async {
  try {
    print("📤 LOGIN REQUEST");
    print("➡️ identifier: $identifier");
    print("➡️ password: $password");

    final response = await _dio.post(
      loginEndpoint,
      data: {
        "identifier": identifier,
        "password": password,
      },
      options: Options(
        validateStatus: (status) => true, // supaya tetap masuk response walau error
      ),
    );

    // =====================
    // LOG RESPONSE DETAIL
    // =====================
    print("📥 LOGIN RESPONSE");
    print("🔢 Status Code : ${response.statusCode}");
    print("📦 Response Data:");
    print(response.data); // <-- RESPONSE BODY UTAMA
    print("📑 Headers:");
    response.headers.forEach((k, v) => print("$k: $v"));

    final auth = AuthResponse.fromJson(response.data);

    if (response.statusCode == 200 && auth.success) {
      if (auth.token != null && auth.user != null) {
        await _saveSession(auth);
      }
    }

    return auth;
  } on DioError catch (e) {
    print("❌ DIO ERROR");

    if (e.response != null) {
      print("🔢 Status Code : ${e.response?.statusCode}");
      print("📦 Error Response Body:");
      print(e.response?.data); // <-- ERROR RESPONSE BODY
      print("📑 Headers:");
      e.response?.headers.forEach((k, v) => print("$k: $v"));

      return AuthResponse(
        success: false,
        message: e.response?.data?['message'] ??
            'Error ${e.response?.statusCode}',
      );
    } else {
      print("❌ Dio Message: ${e.message}");
      return AuthResponse(
        success: false,
        message: 'Exception: ${e.message}',
      );
    }
  } catch (e) {
    print("❌ UNKNOWN ERROR LOGIN: $e");
    return AuthResponse(
      success: false,
      message: "Terjadi kesalahan koneksi",
    );
  }
}

  /// =====================
  /// SIMPAN SESSION
  /// =====================
  static Future<void> _saveSession(AuthResponse auth) async {
    final prefs = await SharedPreferences.getInstance();
    final user = auth.user!;

    if (auth.token != null) {
      await prefs.setString('token', auth.token!);
    }

    await prefs.setInt('user_id', user.id);
    await prefs.setInt('owner_id', user.ownerId);

    if (user.storeId != null) {
      await prefs.setInt('store_id', user.storeId!);
    }

    await prefs.setString('role', user.role);
    await prefs.setString('username', user.username);
    await prefs.setString('name', user.name??"");
    await prefs.setString('email', user.email);
    await prefs.setString('db_name', user.dbName);
    await prefs.setString('plan', user.plan);
  }

  /// =====================
  /// GET TOKEN
  /// =====================
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
/// =====================
/// GET CASHIER ROLE (UNTUK STRUK)
/// =====================
/// =====================
/// GET CASHIER USERNAME (UNTUK STRUK)
/// =====================
static Future<String> getCashierUsername() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('username') ?? 'ADMIN';
}

/// =====================
/// GET USER ROLE (DARI SESSION LOGIN)
/// =====================
static Future<String> getUserRole() async {
  final prefs = await SharedPreferences.getInstance();
  final roleRaw = prefs.getString('role') ?? 'admin';

  print("🔐 ROLE RAW DARI LOGIN = '$roleRaw'");

  return roleRaw.toLowerCase().trim();
}
/// =====================
/// GET USER ID (🔥 PENTING)
/// =====================
static Future<int?> getUserId() async {
  final prefs = await SharedPreferences.getInstance();
  final id = prefs.getInt('user_id');

  print("🆔 USER ID DARI SESSION = $id");
  return id;
}

  /// =====================
  /// LOGOUT
  /// =====================
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
