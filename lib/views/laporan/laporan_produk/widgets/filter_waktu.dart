import 'package:flutter/material.dart';

class FilterWaktu extends StatefulWidget {
  final ValueChanged<int> onChanged;

  const FilterWaktu({
    super.key,
    required this.onChanged,
  });

  @override
  State<FilterWaktu> createState() => _FilterWaktuState();
}

class _FilterWaktuState extends State<FilterWaktu> {
  int _activeIndex = 0;

  final List<String> filters = [
    "Hari ini",
    "7 hari",
    "30 hari",
    "1 tahun",
    "Semua data",
  ];

  void _onTap(int index) {
    setState(() {
      _activeIndex = index;
    });

    widget.onChanged(index); // 🔥 KIRIM KE PARENT
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        /// ICON FILTER
        const Icon(
          Icons.filter_alt_outlined,
          size: 14,
          color: Colors.redAccent,
        ),
        const SizedBox(width: 6),

        /// LABEL
        Text(
          "Filter Waktu",
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.7),
          ),
        ),

        const SizedBox(width: 10),

        /// FILTER CHIPS
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(filters.length, (index) {
                final isActive = _activeIndex == index;

                return GestureDetector(
                  onTap: () => _onTap(index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
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
