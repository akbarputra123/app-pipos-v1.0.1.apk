import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import '../models/produk_model.dart';
import '../services/kelola_produk_service.dart';
import 'package:permission_handler/permission_handler.dart';

/// =====================
/// STATE
/// =====================
class KelolaProdukState {
  final bool isLoading;
  final List<ProdukModel> products;
  final String? errorMessage;

  KelolaProdukState({
    this.isLoading = false,
    this.products = const [],
    this.errorMessage,
  });

  KelolaProdukState copyWith({
    bool? isLoading,
    List<ProdukModel>? products,
    String? errorMessage,
  }) {
    return KelolaProdukState(
      isLoading: isLoading ?? this.isLoading,
      products: products ?? this.products,
      errorMessage: errorMessage,
    );
  }
}

/// =====================
/// VIEWMODEL
/// =====================
class KelolaProdukViewModel extends StateNotifier<KelolaProdukState> {
  KelolaProdukViewModel() : super(KelolaProdukState());

  /// Ambil semua produk
  Future<void> getProduk() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final data = await KelolaProdukService.getProdukByStore();
      state = state.copyWith(isLoading: false, products: data);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      print("❌ getProduk failed: $e");
    }
  }

  /// Tambah produk
  Future<bool> createProduk(ProdukModel produk, {File? imageFile}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final success = await KelolaProdukService.createProdukWithImage(
        produk,
        imageFile: imageFile,
      );
      if (success) await getProduk();
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Update produk
  Future<bool> updateProduk(
    int productId,
    ProdukModel produk, {
    File? imageFile,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final success = await KelolaProdukService.updateProdukWithImage(
        productId,
        produk,
        imageFile: imageFile,
      );
      if (success) await getProduk();
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Hapus produk
  Future<bool> deleteProduk(int productId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final success = await KelolaProdukService.deleteProduk(productId);
      if (success) await getProduk();
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// =====================
  /// Helper untuk UI: string promo
  /// =====================
  String getPromoText(ProdukModel produk) {
    if (produk.promoType == null) return "";
    switch (produk.promoType) {
      case "percentage":
      case "percent":
        return produk.promoPercent != null
            ? "${produk.promoPercent!.toStringAsFixed(0)}% OFF"
            : "";
      case "buyxgety":
      case "buy_get":
        final buy = produk.buyQty ?? 0;
        final free = produk.freeQty ?? 0;
        return "Beli $buy Gratis $free";
      default:
        return "";
    }
  }




  /// Export Produk ke Excel dan simpan ke folder Downloads
  Future<String?> exportProdukToExcel() async {
    try {
      if (state.products.isEmpty) throw "Tidak ada produk untuk diexport";

      // Minta izin storage
      final status = await Permission.storage.request();
      if (Platform.isAndroid) {
        if (await Permission.manageExternalStorage.request().isDenied) {
          throw "Izin storage ditolak";
        }
      } else {
        if (await Permission.storage.request().isDenied) {
          throw "Izin storage ditolak";
        }
      }

      var excel = Excel.createExcel();
      final Sheet sheet = excel['Produk'];

      // Header
      sheet.appendRow([
        "ID",
        "Nama",
        "SKU",
        "Barcode",
        "Harga Modal",
        "Harga Jual",
        "Stok",
        "Kategori",
        "Deskripsi",
        "Promo",
        "Buy Qty",
        "Free Qty",
        "Aktif",
        "Created At",
        "Updated At",
      ]);

      // Data
      for (var p in state.products) {
        sheet.appendRow([
          p.id ?? 0,
          p.name ?? "",
          p.sku ?? "",
          p.barcode ?? "",
          p.costPrice ?? 0,
          p.sellPrice ?? 0,
          p.stock ?? 0,
          p.category ?? "",
          p.description ?? "",
          getPromoText(p),
          p.buyQty ?? 0,
          p.freeQty ?? 0,
      
          p.isActive ?? 0,
          p.createdAt?.toIso8601String() ?? "",
          p.updatedAt?.toIso8601String() ?? "",
        ]);
      }

      // Direktori Downloads
     Directory downloadsDirectory;

if (Platform.isAndroid) {
  downloadsDirectory = Directory('/storage/emulated/0/Download');
  if (!await downloadsDirectory.exists()) {
    downloadsDirectory = (await getExternalStorageDirectory())!;
  }
} else {
  downloadsDirectory = await getApplicationDocumentsDirectory();
}


      final filePath =
          "${downloadsDirectory.path}/produk_export_${DateTime.now().millisecondsSinceEpoch}.xlsx";
      final bytes = excel.encode();
      if (bytes == null) throw "Gagal membuat file Excel";
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      print("✅ Excel berhasil dibuat di: $filePath");
      return filePath;
    } catch (e) {
      print("❌ exportProdukToExcel failed: $e");
      return null;
    }
  }



 void addToCart(ProdukModel produk) {
    final updatedProducts = state.products.map((p) {
      if (p.id == produk.id) return p.copyWith(qty: 1);
      return p;
    }).toList();
    state = state.copyWith(products: updatedProducts);
  }

  void removeFromCart(ProdukModel produk) {
    final updatedProducts = state.products.map((p) {
      if (p.id == produk.id) return p.copyWith(qty: 0);
      return p;
    }).toList();
    state = state.copyWith(products: updatedProducts);
  }

   void increaseQty(ProdukModel produk) {
  final updatedProducts = state.products.map((p) {
    if (p.id == produk.id && p.qty < p.stock) {
      return p.copyWith(qty: p.qty + 1);
    }
    return p;
  }).toList();

  state = state.copyWith(products: updatedProducts);
}


  void decreaseQty(ProdukModel produk) {
    final updatedProducts = state.products.map((p) {
      if (p.id == produk.id && p.qty > 0) {
        return p.copyWith(qty: p.qty - 1);
      }
      return p;
    }).toList();
    state = state.copyWith(products: updatedProducts);
  }

  List<ProdukModel> get cartItems =>
      state.products.where((p) => p.qty > 0).toList();


      /// =====================
/// CLEAR CART
/// =====================
void clearCart() {
  final clearedProducts = state.products.map((p) {
    if (p.qty > 0) {
      return p.copyWith(qty: 0);
    }
    return p;
  }).toList();

  state = state.copyWith(products: clearedProducts);

  print("🧹 KelolaProdukViewModel: Cart berhasil dikosongkan");
}



}

/// =====================
/// PROVIDER
/// =====================
final kelolaProdukViewModelProvider =
    StateNotifierProvider<KelolaProdukViewModel, KelolaProdukState>(
      (ref) => KelolaProdukViewModel(),
    );
