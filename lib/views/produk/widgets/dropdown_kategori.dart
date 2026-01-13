// lib/views/produk/dropdown_kategori.dart
import 'package:flutter/material.dart';
import '../../../config/theme.dart';

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
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.cardColor, // ✅ ikut theme
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor, // ✅ ikut theme
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCategory,
          isExpanded: true,
          dropdownColor: theme.cardColor, // ✅ dropdown ikut theme
          style: theme.textTheme.bodyMedium, // ✅ teks ikut theme
          iconEnabledColor: AppColors.primary, // brand tetap
          items: [
            const DropdownMenuItem(
              value: "Semua",
              child: Text("Semua Kategori"),
            ),
            ...categories.map(
              (cat) => DropdownMenuItem(
                value: cat,
                child: Text(cat),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
