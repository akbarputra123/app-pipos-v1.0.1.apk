// lib/views/produk/search_produk.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';

// StateProvider untuk keyword search
final searchKeywordProvider = StateProvider<String>((ref) => "");

class SearchProduk extends ConsumerWidget {
  const SearchProduk({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return TextField(
      onChanged: (value) {
        ref.read(searchKeywordProvider.notifier).state = value;
      },
      style: theme.textTheme.bodyMedium, // ✅ teks ikut theme
      decoration: InputDecoration(
        hintText: "Cari produk...",
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
        ),
        prefixIcon: const Icon(
          Icons.search,
          color: AppColors.primary, // brand tetap
        ),
        filled: true,
        fillColor: theme.cardColor, // ✅ light/dark otomatis
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: theme.dividerColor,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: theme.dividerColor,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      ),
    );
  }
}
