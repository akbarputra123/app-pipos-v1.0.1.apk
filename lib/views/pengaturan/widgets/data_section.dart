import 'package:flutter/material.dart';
import 'backup_data.dart';

class DataSection extends StatelessWidget {
  const DataSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: _box(theme),
      child: Column(
        children: [
          _DataTile(
            icon: Icons.cloud_upload,
            iconColor: Colors.green, // ✅ tetap
            title: 'Backup Data',
            subtitle: 'Simpan data ke file',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BackupDataScreen(),
                ),
              );
            },
          ),

          Divider(
            color: theme.dividerColor.withOpacity(0.4),
            height: 1,
          ),

          _DataTile(
            icon: Icons.cloud_download,
            iconColor: Colors.blue, // ✅ tetap
            title: 'Import Data',
            subtitle: 'Ambil data dari file',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  BoxDecoration _box(ThemeData theme) {
    return BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: theme.shadowColor.withOpacity(0.3),
          blurRadius: 12,
        ),
      ],
    );
  }
}

/// ================= ITEM =================
/// ⬇️ TETAP DI FILE YANG SAMA
class _DataTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _DataTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            /// ICON
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor),
            ),

            const SizedBox(width: 14),

            /// TEXT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            /// ARROW
            Icon(
              Icons.chevron_right,
              color: theme.iconTheme.color?.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}
