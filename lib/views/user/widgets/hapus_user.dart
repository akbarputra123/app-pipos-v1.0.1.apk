import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../viewmodels/kelola_user_viewmodel.dart';

Future<void> showDeleteUserDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String username,
  required int userId,
}) async {
  final theme = Theme.of(context);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),

      /// ✅ THEME AWARE
      backgroundColor: theme.dialogBackgroundColor,

      title: Text(
        'Hapus User',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),

      content: Text(
        'Apakah Anda yakin ingin menghapus user "$username"?',
        style: theme.textTheme.bodyMedium,
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          style: TextButton.styleFrom(
            foregroundColor: theme.textTheme.bodyMedium?.color,
          ),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
          ),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  /// ================= DELETE USER =================
  final success = await ref
      .read(kelolaUserViewModelProvider.notifier)
      .deleteUser(userId);

  if (!context.mounted) return;

  /// Delay kecil supaya dialog benar-benar tertutup
  await Future.delayed(const Duration(milliseconds: 120));

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        success
            ? 'User "$username" berhasil dihapus'
            : (ref.read(kelolaUserViewModelProvider).errorMessage ??
                'Gagal menghapus user'),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onInverseSurface,
        ),
      ),

      /// ✅ SNACKBAR THEME SAFE
      backgroundColor: success
          ? Colors.green
          : theme.colorScheme.error,

      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
