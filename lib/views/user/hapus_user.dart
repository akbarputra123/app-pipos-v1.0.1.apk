import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/kelola_user_viewmodel.dart';
import '../../config/theme.dart'; // AppColors

Future<void> showDeleteUserDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String username,
  required int userId,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: AppColors.card,
      title: const Text(
        'Hapus User',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: Text(
        'Apakah Anda yakin ingin menghapus user "$username"?',
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
          ),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: TextButton.styleFrom(
            foregroundColor: Colors.redAccent,
          ),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  // Hapus user
  final success = await ref
      .read(kelolaUserViewModelProvider.notifier)
      .deleteUser(userId);

  if (!context.mounted) return;

  // Delay sedikit agar AlertDialog sudah tertutup sebelum Snackbar muncul
  Future.delayed(const Duration(milliseconds: 100), () {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'User "$username" berhasil dihapus'
              : (ref.read(kelolaUserViewModelProvider).errorMessage ??
                  'Gagal menghapus user'),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  });
}
