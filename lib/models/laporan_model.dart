/// ===============================
/// HELPER PARSER
/// ===============================
int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

/// ===============================
/// SUMMARY LAPORAN KEUANGAN
/// ===============================
class ReportSummary {
  final int totalTransaksi;
  final int totalPendapatan;
  final int totalDiskon;
  final int netRevenue;

  final double totalHpp;          // ⬅️ DOUBLE
  final double grossProfit;       // ⬅️ DOUBLE
  final double operationalCost;   // ⬅️ DOUBLE
  final double netProfit;         // ⬅️ DOUBLE

  final String margin;

  final int bestSalesDay;
  final int lowestSalesDay;
  final int avgDaily;

  final List<TopProduct> topProducts;
  final List<LowStockProduct> stokMenipis;

  ReportSummary({
    required this.totalTransaksi,
    required this.totalPendapatan,
    required this.totalDiskon,
    required this.netRevenue,
    required this.totalHpp,
    required this.grossProfit,
    required this.operationalCost,
    required this.netProfit,
    required this.margin,
    required this.bestSalesDay,
    required this.lowestSalesDay,
    required this.avgDaily,
    required this.topProducts,
    required this.stokMenipis,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    return ReportSummary(
      totalTransaksi: json['total_transaksi'] ?? 0,
      totalPendapatan: json['total_pendapatan'] ?? 0,
      totalDiskon: json['total_diskon'] ?? 0,
      netRevenue: json['net_revenue'] ?? 0,

      totalHpp: _toDouble(json['total_hpp']),
      grossProfit: _toDouble(json['gross_profit']),
      operationalCost: _toDouble(json['operational_cost']),
      netProfit: _toDouble(json['net_profit']),

      margin: json['margin'] ?? "0%",
      bestSalesDay: json['best_sales_day'] ?? 0,
      lowestSalesDay: json['lowest_sales_day'] ?? 0,
      avgDaily: json['avg_daily'] ?? 0,

      topProducts: (json['top_products'] as List? ?? [])
          .map((e) => TopProduct.fromJson(e))
          .toList(),

      stokMenipis: (json['stok_menipis'] as List? ?? [])
          .map((e) => LowStockProduct.fromJson(e))
          .toList(),
    );
  }
}

/// ===============================
/// LAPORAN PRODUK
/// ===============================
class ReportProduct {
  final int totalProducts;
  final int totalSold;
  final int stokHabis;
  final List<TopProduct> topProducts;
  final List<LowStockProduct> stokMenipis;

  ReportProduct({
    required this.totalProducts,
    required this.totalSold,
    required this.stokHabis,
    required this.topProducts,
    required this.stokMenipis,
  });

  factory ReportProduct.fromJson(Map<String, dynamic> json) {
    return ReportProduct(
      totalProducts: _toInt(json['total_products']),
      totalSold: _toInt(json['total_sold']),
      stokHabis: _toInt(json['stok_habis']),
      topProducts: (json['top_products'] as List? ?? [])
          .map((e) => TopProduct.fromJson(e))
          .toList(),
      stokMenipis: (json['stok_menipis'] as List? ?? [])
          .map((e) => LowStockProduct.fromJson(e))
          .toList(),
    );
  }
}

/// ===============================
/// LAPORAN KARYAWAN / KASIR
/// ===============================
class ReportCashier {
  final int totalKaryawan;
  final double avgPerformance;
  final double avgAttendance;
  final List<CashierPerformance> cashiers;

  ReportCashier({
    required this.totalKaryawan,
    required this.avgPerformance,
    required this.avgAttendance,
    required this.cashiers,
  });

  factory ReportCashier.fromJson(Map<String, dynamic> json) {
    return ReportCashier(
      totalKaryawan: _toInt(json['total_karyawan']),
      avgPerformance: _toDouble(json['avg_performance']),
      avgAttendance: _toDouble(json['avg_attendance']),
      cashiers: (json['cashiers'] as List? ?? [])
          .map((e) => CashierPerformance.fromJson(e))
          .toList(),
    );
  }
}
class CashierPerformance {
  final int id;
  final String name;
  final String role;
  final int totalTransaksi;
  final double totalPenjualan; // ✅ DOUBLE

  CashierPerformance({
    required this.id,
    required this.name,
    required this.role,
    required this.totalTransaksi,
    required this.totalPenjualan,
  });

  factory CashierPerformance.fromJson(Map<String, dynamic> json) {
    return CashierPerformance(
      id: json['id'] ?? 0,
      name: json['name'] ?? "",
      role: json['role'] ?? "",
      totalTransaksi: json['total_transaksi'] ?? 0,

      // 🔥 FIX UTAMA (AMAN STRING / INT / DOUBLE)
      totalPenjualan: double.tryParse(
            json['total_penjualan'].toString(),
          ) ??
          0.0,
    );
  }
}


/// ===============================
/// LAPORAN HARIAN
/// ===============================
class DailyReport {
  final int id;
  final int storeId;
  final String reportDate;
  final int totalTransactions;
  final int totalIncome;
  final int totalDiscount;
  final int netRevenue;
  final int totalHpp;
  final int grossProfit;
  final int operationalCost;
  final int netProfit;
  final String margin;
  final int bestSalesDay;
  final int lowestSalesDay;
  final int avgDaily;
  final String createdAt;

  DailyReport({
    required this.id,
    required this.storeId,
    required this.reportDate,
    required this.totalTransactions,
    required this.totalIncome,
    required this.totalDiscount,
    required this.netRevenue,
    required this.totalHpp,
    required this.grossProfit,
    required this.operationalCost,
    required this.netProfit,
    required this.margin,
    required this.bestSalesDay,
    required this.lowestSalesDay,
    required this.avgDaily,
    required this.createdAt,
  });

  factory DailyReport.fromJson(Map<String, dynamic> json) {
    return DailyReport(
      id: _toInt(json['id']),
      storeId: _toInt(json['store_id']),
      reportDate: json['report_date']?.toString() ?? "",
      totalTransactions: _toInt(json['total_transactions']),
      totalIncome: _toInt(json['total_income']),
      totalDiscount: _toInt(json['total_discount']),
      netRevenue: _toInt(json['net_revenue']),
      totalHpp: _toInt(json['total_hpp']),
      grossProfit: _toInt(json['gross_profit']),
      operationalCost: _toInt(json['operational_cost']),
      netProfit: _toInt(json['net_profit']),
      margin: json['margin']?.toString() ?? "0%",
      bestSalesDay: _toInt(json['best_sales_day']),
      lowestSalesDay: _toInt(json['lowest_sales_day']),
      avgDaily: _toInt(json['avg_daily']),
      createdAt: json['created_at']?.toString() ?? "",
    );
  }
}

/// ===============================
/// PERIODIC REPORT
/// ===============================
class PeriodicReport {
  final String periodStart;
  final String periodEnd;
  final int totalTransactions;
  final int totalIncome;
  final int totalDiscount;
  final int netRevenue;
  final int totalHpp;
  final int grossProfit;
  final int operationalCost;
  final int netProfit;

  PeriodicReport({
    required this.periodStart,
    required this.periodEnd,
    required this.totalTransactions,
    required this.totalIncome,
    required this.totalDiscount,
    required this.netRevenue,
    required this.totalHpp,
    required this.grossProfit,
    required this.operationalCost,
    required this.netProfit,
  });

  factory PeriodicReport.fromJson(Map<String, dynamic> json) {
    return PeriodicReport(
      periodStart: json['period_start']?.toString() ?? "",
      periodEnd: json['period_end']?.toString() ?? "",
      totalTransactions: _toInt(json['total_transactions']),
      totalIncome: _toInt(json['total_income']),
      totalDiscount: _toInt(json['total_discount']),
      netRevenue: _toInt(json['net_revenue']),
      totalHpp: _toInt(json['total_hpp']),
      grossProfit: _toInt(json['gross_profit']),
      operationalCost: _toInt(json['operational_cost']),
      netProfit: _toInt(json['net_profit']),
    );
  }
}

/// ===============================
/// SHARED MODELS
/// ===============================
class TopProduct {
  final int productId;
  final String sku;
  final String name;
  final int sold;
  final int revenue;

  TopProduct({
    required this.productId,
    required this.sku,
    required this.name,
    required this.sold,
    required this.revenue,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      productId: _toInt(json['product_id']),
      sku: json['sku']?.toString() ?? "",
      name: json['name']?.toString() ?? "",
      sold: _toInt(json['sold']),
      revenue: _toInt(json['revenue']),
    );
  }
}

class LowStockProduct {
  final int id;
  final String name;
  final int remaining;

  LowStockProduct({
    required this.id,
    required this.name,
    required this.remaining,
  });

  factory LowStockProduct.fromJson(Map<String, dynamic> json) {
    return LowStockProduct(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? "",
      remaining: _toInt(json['remaining']),
    );
  }
}
