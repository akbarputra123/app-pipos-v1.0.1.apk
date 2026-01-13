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

  /// =====================
  /// GET PRODUK
  /// =====================
  Future<void> getProduk() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final data = await KelolaProdukService.getProdukByStore();
      state = state.copyWith(isLoading: false, products: data);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// =====================
  /// CREATE
  /// =====================
  Future<bool> createProduk(ProdukModel produk, {File? imageFile}) async {
    state = state.copyWith(isLoading: true);
    final success = await KelolaProdukService.createProdukWithImage(
      produk,
      imageFile: imageFile,
    );
    if (success) await getProduk();
    state = state.copyWith(isLoading: false);
    return success;
  }

  /// =====================
  /// UPDATE
  /// =====================
  Future<bool> updateProduk(
    int productId,
    ProdukModel produk, {
    File? imageFile,
  }) async {
    state = state.copyWith(isLoading: true);
    final success = await KelolaProdukService.updateProdukWithImage(
      productId,
      produk,
      imageFile: imageFile,
    );
    if (success) await getProduk();
    state = state.copyWith(isLoading: false);
    return success;
  }

  /// =====================
  /// DELETE
  /// =====================
  Future<bool> deleteProduk(int productId) async {
    state = state.copyWith(isLoading: true);
    final success = await KelolaProdukService.deleteProduk(productId);
    if (success) await getProduk();
    state = state.copyWith(isLoading: false);
    return success;
  }

  /// =====================
  /// PROMO TEXT (SUPPORT BUNDLE)
  /// =====================
  String getPromoText(ProdukModel p) {
    if (p.promoType == null) return "";

    switch (p.promoType) {
      case "percentage":
        return "${p.promoPercent?.toStringAsFixed(0)}% OFF";

      case "buyxgety":
        return "Beli ${p.buyQty} Gratis ${p.freeQty}";

      case "bundle":
        return "${p.bundleQty} pcs Rp${p.bundleTotalPrice?.toStringAsFixed(0)}";

      default:
        return "";
    }
  }

  /// =====================
  /// ADD TO CART
  /// =====================
  void addToCart(ProdukModel produk) {
    final updated = state.products.map((p) {
      if (p.id != produk.id) return p;

      // ===== BUY X GET Y =====
      if (p.promoType == "buyxgety" &&
          p.buyQty != null &&
          p.freeQty != null) {
        final paidQty = _getPaidQty(p) + 1;
        final bonusQty = (paidQty ~/ p.buyQty!) * p.freeQty!;
        final totalQty = paidQty + bonusQty;

        if (totalQty > p.stock) return p;
        return p.copyWith(qty: totalQty);
      }

      // ===== BUNDLE & NORMAL =====
      if (p.qty < p.stock) {
        return p.copyWith(qty: p.qty + 1);
      }
      return p;
    }).toList();

    state = state.copyWith(products: updated);
  }

  /// =====================
  /// REMOVE FROM CART
  /// =====================
  void removeFromCart(ProdukModel produk) {
    state = state.copyWith(
      products: state.products
          .map((p) => p.id == produk.id ? p.copyWith(qty: 0) : p)
          .toList(),
    );
  }

  /// =====================
  /// INCREASE
  /// =====================
  void increaseQty(ProdukModel produk) => addToCart(produk);

  /// =====================
  /// DECREASE
  /// =====================
  void decreaseQty(ProdukModel produk) {
    final updated = state.products.map((p) {
      if (p.id != produk.id) return p;
      if (p.qty <= 0) return p;

      // BUY X GET Y
      if (p.promoType == "buyxgety" &&
          p.buyQty != null &&
          p.freeQty != null) {
        final paidQty = _getPaidQty(p) - 1;
        if (paidQty <= 0) return p.copyWith(qty: 0);

        final bonusQty = (paidQty ~/ p.buyQty!) * p.freeQty!;
        return p.copyWith(qty: paidQty + bonusQty);
      }

      // BUNDLE & NORMAL
      return p.copyWith(qty: p.qty - 1);
    }).toList();

    state = state.copyWith(products: updated);
  }

  /// =====================
  /// CART ITEMS
  /// =====================
  List<ProdukModel> get cartItems =>
      state.products.where((p) => p.qty > 0).toList();

  /// =====================
  /// CLEAR CART
  /// =====================
  void clearCart() {
    state = state.copyWith(
      products: state.products.map((p) => p.copyWith(qty: 0)).toList(),
    );
  }

  /// =====================
  /// HELPER BUY X GET Y
  /// =====================
  int _getPaidQty(ProdukModel p) {
    if (p.promoType != "buyxgety" ||
        p.buyQty == null ||
        p.freeQty == null) {
      return p.qty;
    }

    int paid = 0;
    while (true) {
      final bonus = (paid ~/ p.buyQty!) * p.freeQty!;
      if (paid + bonus >= p.qty) break;
      paid++;
    }
    return paid;
  }

  /// =====================
  /// EXPORT EXCEL (SUPPORT BUNDLE)
  /// =====================
  Future<String?> exportProdukToExcel() async {
    try {
      await Permission.storage.request();

      var excel = Excel.createExcel();
      final sheet = excel['Produk'];

      sheet.appendRow([
        "ID",
        "Nama",
        "SKU",
        "Harga Jual",
        "Stok",
        "Promo",
        "Bundle Qty",
        "Bundle Price",
        "Aktif",
      ]);

      for (var p in state.products) {
        sheet.appendRow([
          p.id,
          p.name,
          p.sku,
          p.sellPrice,
          p.stock,
          getPromoText(p),
          p.bundleQty,
          p.bundleTotalPrice,
          p.isActive,
        ]);
      }

      Directory dir = Platform.isAndroid
          ? Directory('/storage/emulated/0/Download')
          : await getApplicationDocumentsDirectory();

      final file =
          File("${dir.path}/produk_${DateTime.now().millisecondsSinceEpoch}.xlsx");

      file.writeAsBytesSync(excel.encode()!);
      return file.path;
    } catch (e) {
      return null;
    }
  }
}

/// =====================
/// PROVIDER
/// =====================
final kelolaProdukViewModelProvider =
    StateNotifierProvider<KelolaProdukViewModel, KelolaProdukState>(
  (ref) => KelolaProdukViewModel(),
);
