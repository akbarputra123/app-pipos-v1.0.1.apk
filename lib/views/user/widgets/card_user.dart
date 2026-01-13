import 'package:flutter/material.dart';
import '../../../models/kelola_user.dart';

class CardUser extends StatelessWidget {
  final KelolaUser user;
  final VoidCallback? onEdit;
  final Future<void> Function()? onDelete; // async-safe

  const CardUser({
    super.key,
    required this.user,
    this.onEdit,
    this.onDelete,
  });

  Color _roleColor(BuildContext context) {
    switch (user.role.toLowerCase()) {
      case 'admin':
        return Colors.green;
      case 'cashier':
        return Colors.orange;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roleColor = _roleColor(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: theme.cardColor, // ✅ ikut dark/light
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          /// AVATAR
          CircleAvatar(
            radius: 24,
            backgroundColor: roleColor.withOpacity(0.15),
            child: Icon(
              Icons.person,
              color: roleColor,
            ),
          ),

          const SizedBox(width: 12),

          /// USER INFO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "ID: ${user.id}",
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 6),

                /// ROLE BADGE
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.role,
                    style: TextStyle(
                      color: roleColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// STATUS + ACTION
          Row(
            children: [
              /// STATUS BADGE
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: user.isActive == 1
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  user.isActive == 1 ? "Aktif" : "Nonaktif",
                  style: TextStyle(
                    color: user.isActive == 1
                        ? Colors.green
                        : Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              /// EDIT
              IconButton(
                tooltip: "Edit User",
                onPressed: onEdit,
                icon: Icon(
                  Icons.edit,
                  color: Colors.orange.shade400,
                ),
              ),

              /// DELETE
              IconButton(
                tooltip: "Hapus User",
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
