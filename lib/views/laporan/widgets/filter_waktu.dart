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
/// FILTER WAKTU WIDGET
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

        /// ================= FILTER CHIPS =================
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _chip("Hari ini", FilterRange.today),
                _chip("7 hari", FilterRange.last7Days),
                _chip("30 hari", FilterRange.last30Days),
                _chip("1 tahun", FilterRange.oneYear),
                _chip("Semua", FilterRange.all),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip(String text, FilterRange value) {
    final isActive = value == active;

    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
          text,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
