// lib/views/user/card_total_user.dart
import 'package:flutter/material.dart';
import '../../models/kelola_user.dart';
import '../../config/theme.dart';

class CardTotalUser extends StatelessWidget {
  final List<KelolaUser> users;

  const CardTotalUser({super.key, required this.users});

  @override
  Widget build(BuildContext context) {
    // Hitung jumlah berdasarkan role
    final totalUsers = users.length;
    final totalAdmin = users
        .where((u) => u.role.trim().toLowerCase() == 'admin')
        .length;
    final totalKasir = users
        .where((u) => u.role.trim().toLowerCase() == 'cashier')
        .length;

    return SizedBox(
      height: 95,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(width: 8),
          _buildSingleCard(
            icon: Icons.people,
            title: "Total User",
            count: totalUsers,
            color: AppColors.cardSoft,
            countColor: Colors.red, // merah
          ),
          _buildSingleCard(
            icon: Icons.admin_panel_settings,
            title: "Admin",
            count: totalAdmin,
            color: AppColors.cardSoft,
            countColor: Colors.green, // hijau
          ),
          _buildSingleCard(
            icon: Icons.person,
            title: "Kasir",
            count: totalKasir,
            color: AppColors.cardSoft,
            countColor: Colors.orange, // orange
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildSingleCard({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
    required Color countColor, // warna count & icon
  }) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // TITLE DI ATAS COUNT
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
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
          Icon(icon, color: countColor, size: 24), // icon ikut warna count
        ],
      ),
    );
  }
}
