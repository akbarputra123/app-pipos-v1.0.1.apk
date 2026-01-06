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
    final List<String> filters = [
      "Hari ini",
      "7 hari",
      "30 hari",
      "1 tahun",
      "Semua data",
    ];

    return Row(
      children: [
        const Icon(
          Icons.filter_alt_outlined,
          size: 14,
          color: Colors.redAccent,
        ),
        const SizedBox(width: 6),
        Text(
          "Filter Waktu",
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(width: 10),
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
                          ? const Color(0xFFE53935)
                          : const Color(0xFF1C1C1C),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                    child: Text(
                      filters[index],
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
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
