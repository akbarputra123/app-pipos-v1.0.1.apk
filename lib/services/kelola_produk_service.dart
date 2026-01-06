import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart';
import '../models/produk_model.dart';
import '../config/base_url.dart';

class KelolaProdukService {
  /// =====================
  /// GET PRODUK BY STORE (LOGIN USER)
  /// =====================
static Future<List<ProdukModel>> getProdukByStore() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final storeId = prefs.getInt('store_id');

    if (storeId == null) throw "Store ID tidak ditemukan, silakan login ulang";

    final url = Uri.parse("${BaseUrl.api}/api/stores/$storeId/products");
    print("🔗 [GET] URL: $url");

    final response = await http.get(url, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });

    // === LOG RESPONSE BODY ===
    print("📦 Response Body: ${response.body}");

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['success'] == true) {
        final List items = body['data']['items'];
        return items.map((item) => ProdukModel.fromJson(item)).toList();
      } else {
        throw body['message'];
      }
    } else {
      throw "Gagal mengambil produk (${response.statusCode})";
    }
  } catch (e) {
    print("❌ ERROR getProdukByStore: $e");
    return [];
  }
}

  /// =====================
/// CREATE PRODUK DENGAN IMAGE (MULTIPART)
/// =====================
static Future<bool> createProdukWithImage(ProdukModel produk, {File? imageFile}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final storeId = prefs.getInt('store_id');

    if (token == null || storeId == null) throw "Token / Store ID tidak ditemukan";

    final url = Uri.parse("${BaseUrl.api}/api/stores/$storeId/products");
    final request = http.MultipartRequest("POST", url);
    request.headers['Authorization'] = "Bearer $token";

    final data = produk.toJsonFiltered();
    data.forEach((key, value) {
      if (value != null) request.fields[key] = value.toString();
    });

    // Tampilkan request body
    print("📤 Request Body:");
    request.fields.forEach((key, value) {
      print("$key: $value");
    });

    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        filename: basename(imageFile.path),
      ));

      // Tampilkan info file
      print("📤 File attached: ${imageFile.path}");
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print("📥 Response Status: ${response.statusCode}");
    print("📥 Response Body: ${response.body}");

    if (response.statusCode == 201 || response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['success'] == true;
    }
    return false;
  } catch (e) {
    print("❌ ERROR createProdukWithImage: $e");
    return false;
  }
}


  /// =====================
  /// UPDATE PRODUK DENGAN IMAGE (MULTIPART)
  /// =====================
  static Future<bool> updateProdukWithImage(int productId, ProdukModel produk, {File? imageFile}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final storeId = prefs.getInt('store_id');

      if (token == null || storeId == null) throw "Token / Store ID tidak ditemukan";

      final url = Uri.parse("${BaseUrl.api}/api/stores/$storeId/products/$productId");
      final request = http.MultipartRequest("PUT", url);
      request.headers['Authorization'] = "Bearer $token";

      final data = produk.toJsonFiltered();
      data.forEach((key, value) {
        if (value != null) request.fields[key] = value.toString();
      });

      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          filename: basename(imageFile.path),
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['success'] == true;
      }
      return false;
    } catch (e) {
      print("❌ ERROR updateProdukWithImage: $e");
      return false;
    }
  }

  /// =====================
  /// DELETE PRODUK
  /// =====================
  static Future<bool> deleteProduk(int productId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final storeId = prefs.getInt('store_id');

      if (token == null || storeId == null) throw "Token / Store ID tidak ditemukan";

      final url = Uri.parse("${BaseUrl.api}/api/stores/$storeId/products/$productId");
      final response = await http.delete(url, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200 || response.statusCode == 204) {
        final body = jsonDecode(response.body);
        return body['success'] == true;
      } else {
        throw "Gagal menghapus produk (${response.statusCode})";
      }
    } catch (e) {
      print("❌ ERROR deleteProduk: $e");
      return false;
    }
  }
}
