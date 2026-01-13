import 'package:flutter/material.dart';
import 'line_chart_widget.dart';

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color valueColor;
  final Color? borderColor;
  final List<double>? chartData;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.valueColor,
    this.borderColor,
    this.chartData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),

      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor ?? theme.dividerColor),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, size: 10, color: valueColor),
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                  ),
                ],
              ),

              /// VALUE
             RichText(
  text: TextSpan(
    children: [
      TextSpan(
        text: 'Rp ',
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 10, // 🔥 kecil
          color: valueColor.withOpacity(0.9),
        ),
      ),
      TextSpan(
        text: value.replaceAll('Rp ', ''),
        style: theme.textTheme.titleMedium?.copyWith(
          fontSize: 10, // 🔥 fokus ke angka
          fontWeight: FontWeight.w600,
          color: valueColor,
        ),
      ),
    ],
  ),
),
              const SizedBox(height: 6),

              /// GRAFIK (ADAPTIF)
              if (chartData != null)
                Expanded(
                  child: MiniLineChart(color: valueColor, data: chartData!),
                ),
            ],
          );
        },
      ),
    );
  }
}
