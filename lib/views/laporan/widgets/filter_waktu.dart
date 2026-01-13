import 'package:flutter/material.dart';

/// ===============================
/// ENUM FILTER RANGE
/// ===============================
enum FilterRange {
  today,
  last7Days,
  last30Days,
  oneYear,
  all,
}

/// ===============================
/// FILTER WAKTU WIDGET (THEME SAFE)
/// ===============================
class FilterWaktu extends StatelessWidget {
  final FilterRange active;
  final ValueChanged<FilterRange> onChanged;

  const FilterWaktu({
    super.key,
    required this.active,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          Icons.filter_alt_outlined,
          size: 14,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 6),
        Text(
          "Filter Waktu",
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),
        const SizedBox(width: 10),

        /// ================= FILTER CHIPS =================
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _chip(context, "Hari ini", FilterRange.today),
                _chip(context, "7 hari", FilterRange.last7Days),
                _chip(context, "30 hari", FilterRange.last30Days),
                _chip(context, "1 tahun", FilterRange.oneYear),
                _chip(context, "Semua", FilterRange.all),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip(BuildContext context, String text, FilterRange value) {
    final theme = Theme.of(context);
    final isActive = value == active;

    final Color activeBg = theme.colorScheme.primary;
    final Color inactiveBg = theme.cardColor;
    final Color borderColor = isActive
        ? theme.colorScheme.primary
        : theme.dividerColor;

    final Color textColor = isActive
        ? theme.colorScheme.onPrimary
        : theme.textTheme.bodyMedium!.color!;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => onChanged(value),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
