class ProdukModel {
  final int id;
  final String name;
  final String? sku;
  final String? barcode;
  final double costPrice;
  final double sellPrice;
  final int stock;
  final String? category;
  final String? description;
  final String? imageUrl;
  
  // Promo / Diskon
  final String? promoType; // percentage | buyxgety
  final double? promoPercent;
  final int? buyQty;
  final int? freeQty;

  final int isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  int qty; // <-- properti tambahan untuk cart

  ProdukModel({
    required this.id,
    required this.name,
    this.sku,
    this.barcode,
    required this.costPrice,
    required this.sellPrice,
    required this.stock,
    this.category,
    this.description,
    this.imageUrl,
    this.promoType,
    this.promoPercent,
    this.buyQty,
    this.freeQty,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.qty = 0, // default 0
  });

  /// =====================
  /// FROM JSON (API → APP)
  /// =====================
  factory ProdukModel.fromJson(Map<String, dynamic> json) {
    return ProdukModel(
      id: json['id'],
      name: json['name'],
      sku: json['sku'],
      barcode: json['barcode'],
      costPrice: (json['costPrice'] ?? 0).toDouble(),
      sellPrice: (json['sellPrice'] ?? 0).toDouble(),
      stock: json['stock'] ?? 0,
      category: json['category'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      promoType: json['promoType'],
      promoPercent: json['promoPercent'] != null
          ? (json['promoPercent']).toDouble()
          : null,
      buyQty: json['buyQty'],
      freeQty: json['freeQty'],
      isActive: json['isActive'] ?? 1,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      qty: json['qty'] ?? 0, // <-- dari json jika ada
    );
  }

  /// =====================
  /// TO JSON (APP → API)
  /// =====================
  Map<String, dynamic> toJsonFiltered() {
    final data = <String, dynamic>{
      "id": id,
      "name": name,
      "sku": sku,
      "barcode": barcode,
      "costPrice": costPrice,
      "sellPrice": sellPrice,
      "stock": stock,
      "category": category,
      "description": description,
      "imageUrl": imageUrl,
      "isActive": isActive,
      "createdAt": createdAt.toIso8601String(),
      "updatedAt": updatedAt.toIso8601String(),
      "qty": qty, // <-- sertakan qty jika dikirim ke API
    };

    // Tambahkan field promo sesuai tipe
    if (promoType == "percentage" && promoPercent != null) {
      data["promoType"] = "percentage";
      data["promoPercent"] = promoPercent;
    } else if (promoType == "buyxgety") {
      data["promoType"] = "buyxgety";
      if (buyQty != null) data["buyQty"] = buyQty;
      if (freeQty != null) data["freeQty"] = freeQty;
    }

    return data;
  }

  ProdukModel copyWith({
    int? id,
    String? name,
    String? sku,
    String? barcode,
    double? costPrice,
    double? sellPrice,
    int? stock,
    String? category,
    String? description,
    String? imageUrl,
    String? promoType,
    double? promoPercent,
    int? buyQty,
    int? freeQty,
    int? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? qty, // <-- copyWith untuk cart
  }) {
    return ProdukModel(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      costPrice: costPrice ?? this.costPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      promoType: promoType ?? this.promoType,
      promoPercent: promoPercent ?? this.promoPercent,
      buyQty: buyQty ?? this.buyQty,
      freeQty: freeQty ?? this.freeQty,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      qty: qty ?? this.qty, // <-- copyWith untuk qty
    );
  }
}
