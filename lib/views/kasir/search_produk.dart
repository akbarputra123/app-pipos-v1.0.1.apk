// lib/views/produk/search_produk.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';

// StateProvider untuk keyword search
final searchKeywordProvider = StateProvider<String>((ref) => "");

class SearchProduk extends ConsumerWidget {
  const SearchProduk({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextField(
      onChanged: (value) {
        ref.read(searchKeywordProvider.notifier).state = value;
      },
      decoration: InputDecoration(
        hintText: "Cari produk...",
        prefixIcon: const Icon(Icons.search, color: AppColors.cardSoft),
        filled: true,
        fillColor: AppColors.card.withOpacity(0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.cardSoft, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.cardSoft, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.textPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      ),
      style: const TextStyle(color: AppColors.textPrimary),
    );
  }
}
