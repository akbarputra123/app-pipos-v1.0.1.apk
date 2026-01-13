import '../../models/laporan_model.dart';

class ChartMapper {
  static List<double> kasMasuk(List<DailyReport> list) {
    return list.map((e) => e.totalIncome.toDouble()).toList();
  }

  static List<double> penjualanTertinggi(List<DailyReport> list) {
    return list.map((e) => e.totalIncome.toDouble()).toList();
  }

  static List<double> penjualanTerendah(List<DailyReport> list) {
    return list.map((e) => e.totalIncome.toDouble()).toList();
  }

  static List<double> rataRata(List<DailyReport> list) {
    if (list.isEmpty) return [];

    final avg =
        list.fold<int>(0, (s, e) => s + e.totalIncome) / list.length;

    return List.generate(list.length, (_) => avg);
  }
}
