// backup_data_model.dart
// =======================================================
// MODEL BACKUP & IMPORT DATA
// SESUAI CONTROLLER exportData & importData (Node.js)
// =======================================================

import 'kelola_user.dart';
import 'produk_model.dart';


/// =======================================================
/// RESPONSE UTAMA BACKUP DATA
/// (JSON export dari backend)
/// =======================================================
class BackupDataResponse {
  final List<KelolaUser>? users;
  final List<ProdukModel>? products;
  final List<TransaksiBackup>? transactions;
  final List<TransaksiItemBackup>? transactionItems;

  BackupDataResponse({
    this.users,
    this.products,
    this.transactions,
    this.transactionItems,
  });

  factory BackupDataResponse.fromJson(Map<String, dynamic> json) {
    return BackupDataResponse(
      users: json['users'] != null
          ? (json['users'] as List)
              .map((e) => KelolaUser.fromJson(e))
              .toList()
          : null,
      products: json['products'] != null
          ? (json['products'] as List)
              .map((e) => ProdukModel.fromJson(_mapProduk(e)))
              .toList()
          : null,
      transactions: json['transactions'] != null
          ? (json['transactions'] as List)
              .map((e) => TransaksiBackup.fromJson(e))
              .toList()
          : null,
      transactionItems: json['transaction_items'] != null
          ? (json['transaction_items'] as List)
              .map((e) => TransaksiItemBackup.fromJson(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (users != null) data['users'] = users!.map((e) => e.toJson()).toList();
    if (products != null) {
      data['products'] = products!.map((e) => e.toJsonFiltered()).toList();
    }
    if (transactions != null) {
      data['transactions'] =
          transactions!.map((e) => e.toJson()).toList();
    }
    if (transactionItems != null) {
      data['transaction_items'] =
          transactionItems!.map((e) => e.toJson()).toList();
    }
    return data;
  }
}

/// =======================================================
/// MODEL TRANSAKSI (FORMAT BACKUP DB)
/// =======================================================
class TransaksiBackup {
  final int id;
  final int storeId;
  final int userId;
  final double totalCost;
  final String paymentType;
  final String paymentMethod;
  final double receivedAmount;
  final double changeAmount;
  final String? customerName;
  final String? customerPhone;
  final String paymentStatus;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TransaksiBackup({
    required this.id,
    required this.storeId,
    required this.userId,
    required this.totalCost,
    required this.paymentType,
    required this.paymentMethod,
    required this.receivedAmount,
    required this.changeAmount,
    this.customerName,
    this.customerPhone,
    required this.paymentStatus,
    required this.createdAt,
    this.updatedAt,
  });

  factory TransaksiBackup.fromJson(Map<String, dynamic> json) {
    return TransaksiBackup(
      id: json['id'],
      storeId: json['store_id'],
      userId: json['user_id'],
      totalCost: (json['total_cost'] ?? 0).toDouble(),
      paymentType: json['payment_type'] ?? 'cash',
      paymentMethod: json['payment_method'] ?? 'cash',
      receivedAmount: (json['received_amount'] ?? 0).toDouble(),
      changeAmount: (json['change_amount'] ?? 0).toDouble(),
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      paymentStatus: json['payment_status'] ?? 'paid',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "store_id": storeId,
        "user_id": userId,
        "total_cost": totalCost,
        "payment_type": paymentType,
        "payment_method": paymentMethod,
        "received_amount": receivedAmount,
        "change_amount": changeAmount,
        "customer_name": customerName,
        "customer_phone": customerPhone,
        "payment_status": paymentStatus,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
      };
}

/// =======================================================
/// MODEL ITEM TRANSAKSI (FORMAT BACKUP DB)
/// =======================================================
class TransaksiItemBackup {
  final int id;
  final int transactionId;
  final int productId;
  final int qty;
  final double price;
  final double subtotal;

  TransaksiItemBackup({
    required this.id,
    required this.transactionId,
    required this.productId,
    required this.qty,
    required this.price,
    required this.subtotal,
  });

  factory TransaksiItemBackup.fromJson(Map<String, dynamic> json) {
    return TransaksiItemBackup(
      id: json['id'],
      transactionId: json['transaction_id'],
      productId: json['product_id'],
      qty: json['qty'],
      price: (json['price'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "transaction_id": transactionId,
        "product_id": productId,
        "qty": qty,
        "price": price,
        "subtotal": subtotal,
      };
}

/// =======================================================
/// HELPER MAP UNTUK SAMAKAN FIELD PRODUK
/// (backend snake_case -> app camelCase)
/// =======================================================
Map<String, dynamic> _mapProduk(Map<String, dynamic> json) {
  return {
    "id": json['id'],
    "name": json['name'],
    "sku": json['sku'],
    "barcode": json['barcode'],
    "costPrice": json['cost_price'],
    "sellPrice": json['price'],
    "stock": json['stock'],
    "category": json['category'],
    "description": json['description'],
    "imageUrl": json['image_url'],
    "promoType": json['jenis_diskon'],
    "promoPercent": json['nilai_diskon'],
    "buyQty": json['buy_qty'],
    "freeQty": json['free_qty'],
    "isActive": json['is_active'],
    "createdAt": json['created_at'],
    "updatedAt": json['updated_at'],
  };
}
