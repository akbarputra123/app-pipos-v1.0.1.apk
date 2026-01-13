class ProdukModel {
  // =====================
  // BASIC
  // =====================
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

  // =====================
  // PROMO
  // =====================
  final String? promoType; // percentage | buyxgety | bundle
  final double? promoPercent;
  final int? buyQty;
  final int? freeQty;

  // 🔥 PROMO BUNDLE
  final int? bundleQty;
  final double? bundleTotalPrice;

  // =====================
  // META
  // =====================
  final int isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // =====================
  // CART STATE
  // =====================
  int qty;       // jumlah input user
  int qtyPaid;   // jumlah dibayar (buyxgety)
  int qtyBonus;  // bonus (buyxgety)
  int qtyTotal;  // tampil di cart

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

    // PROMO
    this.promoType,
    this.promoPercent,
    this.buyQty,
    this.freeQty,

    // 🔥 BUNDLE
    this.bundleQty,
    this.bundleTotalPrice,

    required this.isActive,
    required this.createdAt,
    required this.updatedAt,

    // CART DEFAULT
    this.qty = 0,
    this.qtyPaid = 0,
    this.qtyBonus = 0,
    this.qtyTotal = 0,
  });

  // =====================
  // FROM JSON (API → APP)
  // =====================
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

      // 🔥 BUNDLE
      bundleQty: json['bundleQty'],
      bundleTotalPrice: json['bundleTotalPrice'] != null
          ? (json['bundleTotalPrice']).toDouble()
          : null,

      isActive: json['isActive'] ?? 1,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),

      qty: json['qty'] ?? 0,
      qtyPaid: json['qtyPaid'] ?? 0,
      qtyBonus: json['qtyBonus'] ?? 0,
      qtyTotal: json['qtyTotal'] ?? 0,
    );
  }

  // =====================
  // TO JSON (APP → API)
  // =====================
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

      // CART
      "qty": qty,
      "qtyPaid": qtyPaid,
      "qtyBonus": qtyBonus,
      "qtyTotal": qtyTotal,
    };

    // =====================
    // PROMO FILTER
    // =====================
    if (promoType == null) {
      data["promoType"] = null;
      data["promoPercent"] = null;
      data["buyQty"] = null;
      data["freeQty"] = null;
      data["bundleQty"] = null;
      data["bundleTotalPrice"] = null;

    } else if (promoType == "percentage") {
      data["promoType"] = "percentage";
      data["promoPercent"] = promoPercent;
      data["buyQty"] = null;
      data["freeQty"] = null;
      data["bundleQty"] = null;
      data["bundleTotalPrice"] = null;

    } else if (promoType == "buyxgety") {
      data["promoType"] = "buyxgety";
      data["buyQty"] = buyQty;
      data["freeQty"] = freeQty;
      data["promoPercent"] = null;
      data["bundleQty"] = null;
      data["bundleTotalPrice"] = null;

    } else if (promoType == "bundle") {
      data["promoType"] = "bundle";
      data["bundleQty"] = bundleQty;
      data["bundleTotalPrice"] = bundleTotalPrice;
      data["promoPercent"] = null;
      data["buyQty"] = null;
      data["freeQty"] = null;
    }

    return data;
  }

  // =====================
  // HELPER
  // =====================
  bool get isPercentage => promoType == "percentage";
  bool get isBuyXGetY => promoType == "buyxgety";
  bool get isBundle => promoType == "bundle";

  // =====================
  // BUY X GET Y LOGIC
  // =====================
  void applyBuyXGetY() {
    if (!isBuyXGetY || buyQty == null || freeQty == null) {
      qtyTotal = qty;
      return;
    }

    qtyPaid = qty;
    qtyBonus = (qtyPaid ~/ buyQty!) * freeQty!;
    qtyTotal = qtyPaid + qtyBonus;
  }

  // =====================
  // BUNDLE PRICE LOGIC
  // =====================
  double getTotalPrice() {
    if (isBundle && bundleQty != null && bundleTotalPrice != null) {
      final bundleCount = qty ~/ bundleQty!;
      final remainder = qty % bundleQty!;
      return (bundleCount * bundleTotalPrice!) +
          (remainder * sellPrice);
    }

    if (isPercentage && promoPercent != null) {
      return qty * (sellPrice * (1 - promoPercent! / 100));
    }

    return qty * sellPrice;
  }

  // =====================
  // RESET CART
  // =====================
  void resetCart() {
    qty = 0;
    qtyPaid = 0;
    qtyBonus = 0;
    qtyTotal = 0;
  }

  // =====================
  // COPY WITH
  // =====================
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
    int? bundleQty,
    double? bundleTotalPrice,

    bool clearPromo = false,

    int? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? qty,
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

      promoType: clearPromo ? null : promoType ?? this.promoType,
      promoPercent: clearPromo ? null : promoPercent ?? this.promoPercent,
      buyQty: clearPromo ? null : buyQty ?? this.buyQty,
      freeQty: clearPromo ? null : freeQty ?? this.freeQty,
      bundleQty: clearPromo ? null : bundleQty ?? this.bundleQty,
      bundleTotalPrice:
          clearPromo ? null : bundleTotalPrice ?? this.bundleTotalPrice,

      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      qty: qty ?? this.qty,
      qtyPaid: qtyPaid,
      qtyBonus: qtyBonus,
      qtyTotal: qtyTotal,
    );
  }
}
