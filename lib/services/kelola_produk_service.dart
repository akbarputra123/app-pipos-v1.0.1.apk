import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart';
import '../models/produk_model.dart';
import '../config/base_url.dart';


class KelolaProdukService {
  /// =====================
  /// GET PRODUK BY STORE
  /// =====================
  static Future<List<ProdukModel>> getProdukByStore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final storeId = prefs.getInt('store_id');

      if (storeId == null) throw "Store ID tidak ditemukan";

      final url = Uri.parse("${BaseUrl.api}/api/stores/$storeId/products");

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          final List items = body['data']['items'];
          return items.map((e) => ProdukModel.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      print("❌ getProdukByStore error: $e");
      return [];
    }
  }

  /// =====================
  /// CREATE PRODUK (MULTIPART)
  /// =====================
  static Future<bool> createProdukWithImage(
    ProdukModel produk, {
    File? imageFile,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final storeId = prefs.getInt('store_id');

      if (token == null || storeId == null) {
        throw "Token / Store ID tidak ditemukan";
      }

      final url = Uri.parse("${BaseUrl.api}/api/stores/$storeId/products");
      final request = http.MultipartRequest("POST", url);
      request.headers['Authorization'] = "Bearer $token";

      final data = produk.toJsonFiltered();

      // 🔥 KIRIM SEMUA FIELD (NULL → STRING KOSONG)
      data.forEach((key, value) {
        request.fields[key] = value == null ? '' : value.toString();
      });

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            imageFile.path,
            filename: basename(imageFile.path),
          ),
        );
      }

      // DEBUG
      print("📤 CREATE PAYLOAD:");
      request.fields.forEach((k, v) => print("$k => '$v'"));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      print("📥 CREATE RESPONSE: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        return body['success'] == true;
      }
      return false;
    } catch (e) {
      print("❌ createProdukWithImage error: $e");
      return false;
    }
  }

  /// =====================
  /// UPDATE PRODUK (MULTIPART)
  /// =====================
  static Future<bool> updateProdukWithImage(
    int productId,
    ProdukModel produk, {
    File? imageFile,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final storeId = prefs.getInt('store_id');

      if (token == null || storeId == null) {
        throw "Token / Store ID tidak ditemukan";
      }

      final url =
          Uri.parse("${BaseUrl.api}/api/stores/$storeId/products/$productId");

      final request = http.MultipartRequest("PUT", url);
      request.headers['Authorization'] = "Bearer $token";

      final data = produk.toJsonFiltered();

      // =====================
      // KIRIM FIELD NON-NULL
      // =====================
      data.forEach((key, value) {
        if (value == null) return;
        request.fields[key] = value.toString();
      });

      // =====================
      // RESET SEMUA PROMO
      // =====================
      if (produk.promoType == null) {
        request.fields.remove('promoType');
        request.fields.remove('promoPercent');
        request.fields.remove('buyQty');
        request.fields.remove('freeQty');
        request.fields.remove('bundleQty');
        request.fields.remove('bundleTotalPrice');
      }

      // =====================
      // PROMO SANITIZER
      // (ANTI PROMO TUMPANG TINDIH)
      // =====================
      if (produk.promoType == "percentage") {
        request.fields.remove('buyQty');
        request.fields.remove('freeQty');
        request.fields.remove('bundleQty');
        request.fields.remove('bundleTotalPrice');
      } else if (produk.promoType == "buyxgety") {
        request.fields.remove('promoPercent');
        request.fields.remove('bundleQty');
        request.fields.remove('bundleTotalPrice');
      } else if (produk.promoType == "bundle") {
        request.fields.remove('promoPercent');
        request.fields.remove('buyQty');
        request.fields.remove('freeQty');
      }

      // ❗ createdAt TIDAK BOLEH DIUPDATE
      request.fields.remove('createdAt');

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            imageFile.path,
            filename: basename(imageFile.path),
          ),
        );
      }

      // DEBUG
      print("📤 UPDATE PAYLOAD:");
      request.fields.forEach((k, v) => print("$k => '$v'"));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      print("📥 UPDATE RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['success'] == true;
      }
      return false;
    } catch (e) {
      print("❌ updateProdukWithImage error: $e");
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

      if (token == null || storeId == null) {
        throw "Token / Store ID tidak ditemukan";
      }

      final url =
          Uri.parse("${BaseUrl.api}/api/stores/$storeId/products/$productId");

      final response = await http.delete(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        final body = jsonDecode(response.body);
        return body['success'] == true;
      }
      return false;
    } catch (e) {
      print("❌ deleteProduk error: $e");
      return false;
    }
  }
}
