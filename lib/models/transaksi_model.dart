/// =======================================================
/// KODE ASLI KAMU (TIDAK DIUBAH SAMA SEKALI)
/// =======================================================

class TransaksiItemModel {
  /// ===============================
  /// DATA INTI (BACKEND)
  /// ===============================
  final int productId;
  final int quantity;
  final String? discountType;   // percentage | buyxgety | null
  final double? discountValue;  // percent value / dll
  final String? notes;

  /// ===============================
  /// SNAPSHOT UNTUK UI / STRUK
  /// ===============================
  final String name;   // NAMA PRODUK SAAT TRANSAKSI
  final double price;  // HARGA SAAT TRANSAKSI

  const TransaksiItemModel({
    required this.productId,
    required this.quantity,
    required this.name,
    required this.price,
    this.discountType,
    this.discountValue,
    this.notes,
  });

  /// ===============================
  /// JSON → BACKEND
  /// ===============================
  Map<String, dynamic> toJson() {
    return {
      "product_id": productId,
      "quantity": quantity,
      if (discountType != null) "discount_type": discountType,
      if (discountValue != null) "discount_value": discountValue,
      if (notes != null) "notes": notes,
    };
  }

  /// ===============================
  /// JSON ← BACKEND
  /// ===============================
  factory TransaksiItemModel.fromJson(Map<String, dynamic> json) {
    return TransaksiItemModel(
      productId: json['product_id'] ?? 0,
      quantity: json['quantity'] ?? 0,
      name: json['name']?.toString() ?? '-',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      discountType: json['discount_type']?.toString(),
      discountValue:
          double.tryParse(json['discount_value']?.toString() ?? ''),
      notes: json['notes']?.toString(),
    );
  }
}

class TransaksiModel {
  final String? transactionId;
  final String paymentType;
  final String paymentMethod;

  /// 🔥 WAJIB ADA
  final double receivedAmount;

  final List<TransaksiItemModel> items;

  /// 🔥 NILAI FINAL TRANSAKSI
  final double? subtotal;
  final double? taxPercent;
  final double? taxAmount;
  final double? total;
  final double? change;

  /// META
  final String? createdAt;
  final String? cashier;

  const TransaksiModel({
    this.transactionId,
    required this.paymentType,
    required this.paymentMethod,
    required this.receivedAmount,
    required this.items,
    this.subtotal,
    this.taxPercent,
    this.taxAmount,
    this.total,
    this.change,
    this.createdAt,
    this.cashier,
  });

  /// ===============================
  /// COPY WITH
  /// ===============================
  TransaksiModel copyWith({
    String? transactionId,
    String? paymentType,
    String? paymentMethod,
    double? receivedAmount,
    List<TransaksiItemModel>? items,
    double? subtotal,
    double? taxPercent,
    double? taxAmount,
    double? total,
    double? change,
    String? createdAt,
    String? cashier,
  }) {
    return TransaksiModel(
      transactionId: transactionId ?? this.transactionId,
      paymentType: paymentType ?? this.paymentType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receivedAmount: receivedAmount ?? this.receivedAmount,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      taxPercent: taxPercent ?? this.taxPercent,
      taxAmount: taxAmount ?? this.taxAmount,
      total: total ?? this.total,
      change: change ?? this.change,
      createdAt: createdAt ?? this.createdAt,
      cashier: cashier ?? this.cashier,
    );
  }

  /// ===============================
  /// PAYLOAD POST
  /// ===============================
  Map<String, dynamic> toJson() {
    return {
      "payment_type": paymentType,
      "payment_method": paymentMethod,
      "received_amount": receivedAmount,
      "items": items.map((e) => e.toJson()).toList(),
    };
  }

  factory TransaksiModel.fromJson(Map<String, dynamic> json) {
    return TransaksiModel(
      transactionId: json['transaction_id']?.toString()
          ?? DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: json['created_at']?.toString()
          ?? DateTime.now().toIso8601String(),
      paymentType: json['payment_type'] ?? 'cash',
      paymentMethod: json['payment_method'] ?? 'cash',
      receivedAmount: double.tryParse(
            json['received_amount']?.toString() ??
                json['received']?.toString() ??
                '0',
          ) ??
          0,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0'),
      taxPercent: double.tryParse(json['tax_percent']?.toString() ?? '0'),
      taxAmount: double.tryParse(json['tax_amount']?.toString() ?? '0'),
      total: double.tryParse(json['total']?.toString() ?? '0'),
      change: double.tryParse(json['change']?.toString() ?? '0'),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => TransaksiItemModel.fromJson(e))
          .toList(),
      cashier: json['cashier']?.toString(),
    );
  }
}









class GetTransaksiItemAdapter {
  static TransaksiItemModel fromJson(Map<String, dynamic> json) {
    String? notes;

    if (json['discount_type'] == 'buyxgety') {
      // tampilkan BuyX-GetY dari backend
      notes = 'BuyX-GetY';
    }

    return TransaksiItemModel(
      productId: json['productId'] ?? 0,
      quantity: json['qty'] ?? 0,
      name: json['name']?.toString() ?? '-',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,

      discountType: json['discount_type']?.toString(),
      discountValue: double.tryParse(
        json['discount_value']?.toString() ?? '',
      ),

      // 🔥 SIMPAN lineTotal & discountAmount DI NOTES
      notes:
          "${json['lineTotal']}|${json['discount_amount']}",
    );
  }
}



class GetTransaksiAdapter {
  static TransaksiModel fromJson(Map<String, dynamic> json) {
    return TransaksiModel(
      // 🔥 PAKAI ID DATABASE
      transactionId: json['transaction_id']?.toString(),

      paymentType: 'cash',
      paymentMethod: json['method']?.toString() ?? 'cash',

      receivedAmount:
          double.tryParse(json['received']?.toString() ?? '0') ?? 0,

      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0'),
      taxPercent:
          double.tryParse(json['tax_percentage']?.toString() ?? '0'),
      taxAmount: double.tryParse(json['tax']?.toString() ?? '0'),
      total: double.tryParse(json['total']?.toString() ?? '0'),
      change: double.tryParse(json['change']?.toString() ?? '0'),

      createdAt: json['createdAt']?.toString(),

      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => GetTransaksiItemAdapter.fromJson(e))
          .toList(),
    );
  }
}




