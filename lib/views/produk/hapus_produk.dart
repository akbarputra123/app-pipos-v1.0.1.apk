// lib/views/produk/dialog_hapus_produk.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/kelola_produk_viewmodel.dart';
import '../../models/produk_model.dart';
import '../../config/theme.dart'; // untuk warna konsisten
Future<void> showHapusProdukDialog({
  required BuildContext context,
  required WidgetRef ref,
  required ProdukModel produk,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: AppColors.card,
      title: const Text(
        "Konfirmasi Hapus",
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: Text(
        "Apakah Anda yakin ingin menghapus produk \"${produk.name}\"?",
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
          ),
          child: const Text("Batal"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: TextButton.styleFrom(
            foregroundColor: Colors.redAccent,
          ),
          child: const Text("Hapus"),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  // Panggil deleteProduk dari ViewModel
  final success = await ref
      .read(kelolaProdukViewModelProvider.notifier)
      .deleteProduk(produk.id);

  // pastikan widget masih ter-mount sebelum memanggil ScaffoldMessenger
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? "Produk berhasil dihapus"
              : (ref.read(kelolaProdukViewModelProvider).errorMessage ??
                  "Gagal menghapus produk"),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
