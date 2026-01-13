// lib/views/produk/dialog_hapus_produk.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../viewmodels/kelola_produk_viewmodel.dart';
import '../../../models/produk_model.dart';

Future<void> showHapusProdukDialog({
  required BuildContext context,
  required WidgetRef ref,
  required ProdukModel produk,
}) async {
  final theme = Theme.of(context);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),

      /// ✅ THEME AWARE (AUTO DARK / LIGHT)
      backgroundColor: theme.dialogBackgroundColor,

      title: Text(
        "Konfirmasi Hapus",
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),

      content: Text(
        'Apakah Anda yakin ingin menghapus produk "${produk.name}"?',
        style: theme.textTheme.bodyMedium,
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          style: TextButton.styleFrom(
            foregroundColor: theme.textTheme.bodyMedium?.color,
          ),
          child: const Text("Batal"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
          ),
          child: const Text("Hapus"),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  /// ================= DELETE PRODUK =================
  final success = await ref
      .read(kelolaProdukViewModelProvider.notifier)
      .deleteProduk(produk.id);

  if (!context.mounted) return;

  /// ⏳ Delay kecil → UX lebih halus (dialog benar-benar tertutup)
  await Future.delayed(const Duration(milliseconds: 120));

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        success
            ? "Produk berhasil dihapus"
            : (ref.read(kelolaProdukViewModelProvider).errorMessage ??
                "Gagal menghapus produk"),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onInverseSurface,
        ),
      ),

      /// ✅ SNACKBAR THEME SAFE
      backgroundColor:
          success ? Colors.green : theme.colorScheme.error,

      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
