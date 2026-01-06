import 'package:flutter/material.dart';

class HeaderLaporan extends StatelessWidget {
  final int activeIndex;
  final Function(int) onMenuTap; // callback ke parent

  const HeaderLaporan({
    super.key,
    required this.activeIndex,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> menus = [
      "Laporan Keuangan",
      "Dashboard",
      "Laporan Produk",
      "Laporan Karyawan",
    ];

    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: List.generate(menus.length, (index) {
            final isActive = index == activeIndex;
            return GestureDetector(
              onTap: () => onMenuTap(index),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF8B1E1E)
                      : const Color(0xFF1C1C1C),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  menus[index],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
