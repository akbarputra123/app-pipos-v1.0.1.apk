import 'package:flutter/material.dart';

class HeaderLaporan extends StatelessWidget {
  final int activeIndex;
  final Function(int) onMenuTap;

  const HeaderLaporan({
    super.key,
    required this.activeIndex,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isActive
                      ? theme.colorScheme.primary // ✅ aktif
                      : theme.cardColor, // ✅ non aktif
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive
                        ? theme.colorScheme.primary
                        : theme.dividerColor,
                  ),
                ),
                child: Text(
                  menus[index],
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive
                        ? theme.colorScheme.onPrimary // kontras aman
                        : theme.textTheme.bodyMedium?.color,
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
