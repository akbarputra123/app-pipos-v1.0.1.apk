import 'package:flutter/material.dart';

class CardTotal extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final String value;
  final String label;

  const CardTotal({
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
          color: theme.dividerColor.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(
              isDark ? 0.6 : 0.15,
            ),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// ===== ICON =====
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBgColor.withOpacity(isDark ? 1 : 0.9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.onPrimary,
              size: 18,
            ),
          ),

          const SizedBox(width: 10),

          /// ===== TEXT =====
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10.5,
                    color: theme.textTheme.bodySmall?.color
                        ?.withOpacity(0.6),
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
