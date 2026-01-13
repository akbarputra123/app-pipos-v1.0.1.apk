import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MiniLineChart extends StatelessWidget {
  final Color color;
  final List<double> data;

  const MiniLineChart({
    super.key,
    required this.color,
    required this.data,
  });

  String _formatY(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)} jt';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)} rb';
    } else {
      return value.toInt().toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    // ================= SAFE DATA =================
    final double minY = data.reduce((a, b) => a < b ? a : b);
    final double maxY = data.reduce((a, b) => a > b ? a : b);

    /// 🔥 DETEKSI SEMUA DATA = 0
    final bool allZero = data.every((v) => v == 0);

    /// 🔥 AMAN UNTUK RANGE (ANTI BUG fl_chart)
    final double safeMinY = allZero ? 0 : minY * 0.9;
    final double safeMaxY = allZero ? 1 : maxY * 1.1;
    final double safeInterval = allZero ? 1 : (safeMaxY - safeMinY);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: data.length.toDouble() - 1,
        minY: safeMinY,
        maxY: safeMaxY,

        /// ================= GRID =================
        gridData: FlGridData(
          show: true,
          horizontalInterval: safeInterval,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withOpacity(0.05),
            strokeWidth: 1,
          ),
          drawVerticalLine: false,
        ),

        borderData: FlBorderData(show: false),

        /// ================= TITLES =================
        titlesData: FlTitlesData(
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),

          /// ❌ Y-AXIS DIMATIKAN (DASHBOARD MINI)
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),

          /// X-AXIS (HARI)
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
                final index = value.toInt();
                if (index < 0 || index > 6) return const SizedBox();

                return Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    days[index],
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.white.withOpacity(0.35),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        /// ================= LINE =================
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              data.length,
              (i) => FlSpot(i.toDouble(), data[i]),
            ),
            isCurved: true,
            barWidth: 2.2,
            color: color,
            dotData: FlDotData(show: false),

            /// 🔥 JANGAN TAMPILKAN AREA JIKA DATA 0
            belowBarData: BarAreaData(
              show: !allZero,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withOpacity(0.35),
                  color.withOpacity(0.05),
                ],
              ),
            ),
          ),
        ],
      ),

      /// ================= ANIMATION =================
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }
}
