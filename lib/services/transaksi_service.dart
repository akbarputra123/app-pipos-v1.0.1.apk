import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/produk_model.dart';
import '../models/transaksi_model.dart';
import '../config/base_url.dart';

class TransaksiService {
  final String baseUrl;

  TransaksiService({this.baseUrl = BaseUrl.api});

  // ======================================================
  // 🔹 HELPER: MAP PRODUK KE PAYLOAD (WAJIB ADA DI SINI)
  // ======================================================
  Map<String, dynamic> _mapProdukToPayload(ProdukModel produk) {
    final Map<String, dynamic> item = {
      "product_id": produk.id,
      "quantity": produk.qty,
    };

    if (produk.promoType != null) {
      // PROMO PERCENTAGE
      if (produk.promoType == "percentage" || produk.promoType == "percent") {
        item["discount_type"] = "percentage";
        item["discount_value"] = (produk.promoPercent ?? 0).toDouble();
      }

      // PROMO BUY X GET Y
      if (produk.promoType == "buyxgety" || produk.promoType == "buy_get") {
        item["discount_type"] = "buyxgety";
        item["buy_qty"] = produk.buyQty ?? 0;
        item["free_qty"] = produk.freeQty ?? 0;
      }
    }

    print("🧾 PAYLOAD ITEM => $item");
    return item;
  }

  // ======================================================
  // 🔹 CREATE TRANSACTION
  // ======================================================
  Future<TransaksiModel?> createTransaction(
    List<ProdukModel> products, {
    required double receivedAmount,
  }) async {
    print("\n================= CREATE TRANSACTION =================");

    if (products.isEmpty) {
      print("❌ Produk kosong");
      return null;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final storeId = prefs.getInt('store_id') ?? 0;
      final token = prefs.getString('token') ?? "";

      print("Store ID : $storeId");
      print("Token    : ${token.isNotEmpty ? 'VALID' : 'KOSONG'}");

      if (storeId == 0 || token.isEmpty) return null;

      /// ✅ SATU SUMBER PAYLOAD
      final items = products.map((p) => _mapProdukToPayload(p)).toList();

      final body = jsonEncode({
        "payment_type": "cash",
        "payment_method": "cash",
        "received_amount": receivedAmount,
        "items": items,
      });

      print("REQUEST BODY => $body");

      final response = await http.post(
        Uri.parse("$baseUrl/api/stores/$storeId/transactions"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: body,
      );

      print("STATUS => ${response.statusCode}");
      print("BODY   => ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body)['data'];

        return TransaksiModel(
          // ================= META =================
          transactionId: data['transaction_id']?.toString() ?? '-',
          createdAt: data['created_at']?.toString() ?? '',
          cashier: data['cashier']?.toString() ?? 'ADMIN',

          // ================= PAYMENT =================
          paymentType: data['payment_type']?.toString() ?? 'cash',
          paymentMethod: data['payment_method']?.toString() ?? 'cash',
          receivedAmount:
              double.tryParse(data['received_amount']?.toString() ?? '0') ??
              0.0,

          // ================= SNAPSHOT ITEM =================
          items: products.map((p) {
            return TransaksiItemModel(
              productId: p.id,
              quantity: p.qty,
              name: p.name, // SNAPSHOT NAMA
              price: p.sellPrice, // SNAPSHOT HARGA
              // PROMO (JIKA ADA)
              discountType: p.promoType,
              discountValue: p.promoType == 'percentage'
                  ? (p.promoPercent ?? 0).toDouble()
                  : null,
            );
          }).toList(),

          // ================= PERHITUNGAN (SOURCE OF TRUTH) =================
          subtotal: double.tryParse(data['subtotal']?.toString() ?? '0') ?? 0.0,

          taxPercent:
              double.tryParse(data['tax_percent']?.toString() ?? '0') ?? 0.0,

          taxAmount:
              double.tryParse(data['tax_amount']?.toString() ?? '0') ?? 0.0,

          total: double.tryParse(data['total']?.toString() ?? '0') ?? 0.0,

          change: double.tryParse(data['change']?.toString() ?? '0') ?? 0.0,
        );
      }

      return null;
    } catch (e, s) {
      print("🔥 ERROR TRANSAKSI");
      print(e);
      print("STACKTRACE:");
      print(s);
      rethrow;
    } finally {
      print("================= END TRANSACTION =================\n");
    }
  }

  // ======================================================
  // 🔹 GET TRANSACTIONS
  // ======================================================
  Future<List<TransaksiModel>> getTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storeId = prefs.getInt('store_id') ?? 0;
      final token = prefs.getString('token') ?? "";

      final url = "$baseUrl/api/stores/$storeId/transactions";
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final items = (responseData['data']['items'] as List<dynamic>?) ?? [];

        return items.map((tx) => GetTransaksiAdapter.fromJson(tx)).toList();
      } else {
        throw Exception("Gagal mengambil transaksi");
      }
    } catch (e) {
      print("🔥 Error getTransactions: $e");
      rethrow;
    }
  }

  // ======================================================
  // 🔹 DELETE TRANSACTION
  // ======================================================
  Future<bool> deleteTransaction(String transactionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storeId = prefs.getInt('store_id') ?? 0;
      final token = prefs.getString('token') ?? "";

      if (transactionId.isEmpty || storeId == 0 || token.isEmpty) {
        print("❌ Transaction ID, Store ID, atau Token tidak valid");
        return false;
      }

      final url = "$baseUrl/api/stores/$storeId/transactions/$transactionId";
      print("🗑 DELETE URL: $url");

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("Status Code: ${response.statusCode}");
      print("Body: ${response.body}");

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("🔥 Error deleteTransaction: $e");
      return false;
    }
  }

  // ======================================================
  // 🔹 DELETE BATCH
  // ======================================================
  Future<bool> deleteTransactionsBatch(List<String> transactionIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storeId = prefs.getInt('store_id') ?? 0;
      final token = prefs.getString('token') ?? "";

      final url = "$baseUrl/api/stores/$storeId/transactions/batch-delete";
      final body = jsonEncode({"transaction_ids": transactionIds});

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: body,
      );

      return response.statusCode == 200;
    } catch (e) {
      print("🔥 Error deleteTransactionsBatch: $e");
      return false;
    }
  }
}
