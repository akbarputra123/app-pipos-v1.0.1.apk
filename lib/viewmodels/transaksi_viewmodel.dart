import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/produk_model.dart';
import '../services/transaksi_service.dart';
import '../models/transaksi_model.dart';

/// =======================
/// STATE TRANSAKSI
/// =======================
class TransaksiState {
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;
  final TransaksiModel? result;
  final List<TransaksiModel>? transactions;

  const TransaksiState({
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
    this.result,
    this.transactions,
  });

  TransaksiState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
    TransaksiModel? result,
    List<TransaksiModel>? transactions,
  }) {
    return TransaksiState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
      result: result ?? this.result,
      transactions: transactions ?? this.transactions,
    );
  }
}

/// =======================
/// VIEWMODEL TRANSAKSI
/// =======================
class TransaksiViewModel extends StateNotifier<TransaksiState> {
  final TransaksiService _service;

  TransaksiViewModel(this._service) : super(const TransaksiState());

  /// =======================
  /// SUBMIT TRANSAKSI (AMAN)
  /// =======================
  /// =======================
/// SUBMIT TRANSAKSI (FINAL + PROMO FIX)
/// =======================
Future<void> submitTransaction({
  required List<ProdukModel> cartItems,
  required double receivedAmount,
  required double subtotal,
  required double taxPercent,
  required double taxAmount,
  required double total,
  required double change,
}) async {
  if (state.isLoading) return;

  state = const TransaksiState(isLoading: true);

  /// 🔥 SNAPSHOT PRODUK (IMMUTABLE – AMAN)
  final snapshotItems = cartItems
      .map(
        (p) => p.copyWith(
          qty: p.qty,
          sellPrice: p.sellPrice,
          promoType: p.promoType,
          promoPercent: p.promoPercent,
          buyQty: p.buyQty,
          freeQty: p.freeQty,
        ),
      )
      .toList();

  try {
    /// ================= KIRIM KE BACKEND =================
    final transaksi = await _service.createTransaction(
      snapshotItems,
      receivedAmount: receivedAmount,
    );

    if (transaksi != null) {
      /// ==================================================
      /// 🔥 INJECT PROMO SNAPSHOT KE TRANSAKSI RESULT
      /// (INI KUNCI AGAR STRUK TAMPIL PROMO)
      /// ==================================================
      final fixedItems = snapshotItems.map((p) {
        String? discountType;
        double? discountValue;
        String? notes;

        // ===== DISKON PERSENTASE =====
        if (p.promoType == 'percentage' || p.promoType == 'percent') {
          discountType = 'percentage';
          discountValue = p.promoPercent ?? 0;
        }

        // ===== BUY X GET Y =====
        if (p.promoType == 'buyxgety' || p.promoType == 'buy_get') {
          discountType = 'buyxgety';

          // 🔥 FORMAT NOTES UNTUK STRUK: "2+2"
          if (p.buyQty != null && p.freeQty != null) {
            notes = '${p.buyQty}+${p.freeQty}';
          }
        }

        return TransaksiItemModel(
          productId: p.id,
          quantity: p.qty,
          name: p.name,
          price: p.sellPrice,
          discountType: discountType,
          discountValue: discountValue,
          notes: notes,
        );
      }).toList();

      /// ================= FINAL RESULT =================
      final fixedResult = transaksi.copyWith(
        receivedAmount: receivedAmount, // 🔥 WAJIB
        subtotal: subtotal,
        taxPercent: taxPercent,
        taxAmount: taxAmount,
        total: total,
        change: change,
        items: fixedItems, // 🔥 INI PENTING
      );

      state = TransaksiState(
        isLoading: false,
        isSuccess: true,
        result: fixedResult,
      );
    } else {
      state = const TransaksiState(
        isLoading: false,
        isSuccess: false,
        errorMessage: "Transaksi gagal",
      );
    }
  } catch (e, s) {
    print("❌ submitTransaction error: $e");
    print(s);

    state = const TransaksiState(
      isLoading: false,
      isSuccess: false,
      errorMessage: "Terjadi kesalahan sistem",
    );
  }
}

  /// =======================
  /// AMBIL DAFTAR TRANSAKSI
  /// =======================
  Future<void> getTransactions() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final list = await _service.getTransactions();
      state = state.copyWith(
        isLoading: false,
        transactions: list,
        isSuccess: true,
      );
      print("✅ ViewModel: Daftar transaksi berhasil diambil (${list.length})");
    } catch (e) {
      print("❌ ViewModel Error getTransactions: $e");
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        errorMessage: "Gagal mengambil transaksi",
      );
    }
  }


  Future<void> deleteTransaction(String transactionId) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final success = await _service.deleteTransaction(transactionId);

      if (success) {
        final updatedList = state.transactions
            ?.where((t) => t.transactionId != transactionId)
            .toList();

        state = state.copyWith(
          isLoading: false,
          transactions: updatedList,
          isSuccess: true,
        );
        print("✅ ViewModel: Transaksi $transactionId berhasil dihapus");
      } else {
        state = state.copyWith(
          isLoading: false,
          isSuccess: false,
          errorMessage: "Gagal menghapus transaksi",
        );
      }
    } catch (e) {
      print("❌ ViewModel Error deleteTransaction: $e");
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        errorMessage: "Terjadi kesalahan saat menghapus transaksi",
      );
    }
  }


  /// =======================
  /// RESET STATE (AMAN)
  /// =======================
  void reset() {
    print("🔄 ViewModel: Resetting state transaksi");
    state = const TransaksiState();
  }
}

/// =======================
/// PROVIDER
/// =======================
final transaksiViewModelProvider =
    StateNotifierProvider<TransaksiViewModel, TransaksiState>(
      (ref) => TransaksiViewModel(TransaksiService()),
    );
