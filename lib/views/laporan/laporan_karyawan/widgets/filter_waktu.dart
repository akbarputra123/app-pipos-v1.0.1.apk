import 'package:flutter/material.dart';

/// ================= ENUM FILTER =================
/// ⬅️ TARUH DI SINI (BIAR TIDAK ERROR FILE)
enum FilterWaktuType {
  today,
  last7Days,
  last30Days,
  lastYear,
  all,
}

class FilterWaktu extends StatelessWidget {
  final FilterWaktuType active;
  final ValueChanged<FilterWaktuType> onChanged;

  const FilterWaktu({
    super.key,
    required this.active,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        /// ICON
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

        /// CHIPS
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _FilterChip(
                  text: "Hari ini",
                  active: active == FilterWaktuType.today,
                  onTap: () => onChanged(FilterWaktuType.today),
                ),
                _FilterChip(
                  text: "7 hari",
                  active: active == FilterWaktuType.last7Days,
                  onTap: () => onChanged(FilterWaktuType.last7Days),
                ),
                _FilterChip(
                  text: "30 hari",
                  active: active == FilterWaktuType.last30Days,
                  onTap: () => onChanged(FilterWaktuType.last30Days),
                ),
                _FilterChip(
                  text: "1 tahun",
                  active: active == FilterWaktuType.lastYear,
                  onTap: () => onChanged(FilterWaktuType.lastYear),
                ),
                _FilterChip(
                  text: "Semua data",
                  active: active == FilterWaktuType.all,
                  onTap: () => onChanged(FilterWaktuType.all),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// ================= CHIP =================

class _FilterChip extends StatelessWidget {
  final String text;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.text,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
