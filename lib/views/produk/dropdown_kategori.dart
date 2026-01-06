// lib/views/produk/dropdown_kategori.dart
import 'package:flutter/material.dart';
import '../../config/theme.dart';

class DropdownKategori extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String?> onChanged;

  const DropdownKategori({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardSoft, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCategory,
          isExpanded: true,
          dropdownColor: AppColors.card,
          style: const TextStyle(color: AppColors.textPrimary),
          items: [
            const DropdownMenuItem(
              value: "Semua",
              child: Text("Semua Kategori"),
            ),
            ...categories.map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(cat),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
