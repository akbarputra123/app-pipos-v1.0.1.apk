import 'package:flutter/material.dart';

class FilterWaktu extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onChanged;

  const FilterWaktu({
    super.key,
    required this.activeIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<String> filters = [
      "Hari ini",
      "7 hari",
      "30 hari",
      "1 tahun",
      "Semua data",
    ];

    return Row(
      children: [
        Icon(
          Icons.filter_alt_outlined,
          size: 14,
          color: theme.colorScheme.primary, // ✅ theme aware
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
              children: List.generate(filters.length, (index) {
                final bool active = activeIndex == index;

                return GestureDetector(
                  onTap: () => onChanged(index),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? theme.colorScheme.primary
                          : theme.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: active
                            ? theme.colorScheme.primary
                            : theme.dividerColor,
                      ),
                    ),
                    child: Text(
                      filters[index],
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        fontWeight:
                            active ? FontWeight.w600 : FontWeight.w400,
                        color: active
                            ? theme.colorScheme.onPrimary
                            : theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
