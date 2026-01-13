import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

class StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final String value;
  final String label;

  const StatCard({
    super.key,
    required this.icon,
    required this.iconBgColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.55)
                : Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// ================= ICON =================
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: theme.colorScheme.onPrimary,
            ),
          ),

          const SizedBox(width: 10),

          /// ================= TEXT =================
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// ===== VALUE (AUTO SCALE) =====
                AutoSizeText(
                  value,
                  maxLines: 1,
                  minFontSize: 10,
                  stepGranularity: 0.5,
                  overflow: TextOverflow.visible,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),

                const SizedBox(height: 4),

                /// ===== LABEL =====
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    height: 1.1,
                    color: theme.textTheme.bodySmall?.color
                        ?.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
