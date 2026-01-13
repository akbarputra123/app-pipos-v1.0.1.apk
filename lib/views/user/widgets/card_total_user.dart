// lib/views/user/card_total_user.dart
import 'package:flutter/material.dart';
import '../../../models/kelola_user.dart';

class CardTotalUser extends StatelessWidget {
  final List<KelolaUser> users;

  const CardTotalUser({super.key, required this.users});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Hitung jumlah berdasarkan role
    final totalUsers = users.length;
    final totalAdmin =
        users.where((u) => u.role.trim().toLowerCase() == 'admin').length;
    final totalKasir =
        users.where((u) => u.role.trim().toLowerCase() == 'cashier').length;

    return SizedBox(
      height: 95,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(width: 8),

          /// 🔴 TOTAL USER
          _buildSingleCard(
            context: context,
            icon: Icons.people,
            title: "Total User",
            count: totalUsers,
            borderColor: Colors.red, // ✅ MERAH
            countColor: Colors.red,
          ),

          /// 🟢 ADMIN
          _buildSingleCard(
            context: context,
            icon: Icons.admin_panel_settings,
            title: "Admin",
            count: totalAdmin,
            borderColor: Colors.green, // ✅ HIJAU
            countColor: Colors.green,
          ),

          /// 🟡 KASIR
          _buildSingleCard(
            context: context,
            icon: Icons.person,
            title: "Kasir",
            count: totalKasir,
            borderColor: Colors.orange, // ✅ KUNING / ORANGE
            countColor: Colors.orange,
          ),

          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildSingleCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required int count,
    required Color borderColor,
    required Color countColor,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.cardColor, // ✅ ikut dark / light
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor, // ✅ border sesuai role
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// TITLE
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          /// COUNT
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              count.toString(),
              style: TextStyle(
                color: countColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 4),

          /// ICON
          Icon(
            icon,
            color: countColor,
            size: 24,
          ),
        ],
      ),
    );
  }
}
