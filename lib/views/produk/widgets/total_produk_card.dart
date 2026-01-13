// lib/views/produk/total_produk_card.dart
import 'package:flutter/material.dart';
import '../../../models/produk_model.dart';
import '../../../config/theme.dart';

class TotalProdukCard extends StatelessWidget {
  final List<ProdukModel> produkList;

  const TotalProdukCard({super.key, required this.produkList});

  int get totalProduk => produkList.length;

  /// 🔥 stok < 10 tapi bukan 0
  int get stokMenipis =>
      produkList.where((p) => p.stock > 0 && p.stock < 10).length;

  /// 🔥 stok benar-benar habis
  int get stokHabis =>
      produkList.where((p) => p.stock == 0).length;

  int get kategoriUnik =>
      produkList.map((p) => p.category ?? "Tidak Ada").toSet().length;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(width: 8),

          /// TOTAL PRODUK
          _buildCard(
            context,
            icon: Icons.shopping_bag,
            label: "Total Produk",
            value: totalProduk.toString(),
            color: AppColors.primary,
          ),

          /// STOK HABIS
          _buildCard(
            context,
            icon: Icons.remove_shopping_cart,
            label: "Stok Habis",
            value: stokHabis.toString(),
            color: stokHabis > 0 ? AppColors.danger : AppColors.success,
            isPulse: stokHabis > 0,
          ),

          /// STOK MENIPIS
          _buildCard(
            context,
            icon: Icons.warning,
            label: "Stok Menipis",
            value: stokMenipis.toString(),
            color: stokMenipis > 0
                ? const Color.fromARGB(255, 255, 218, 5)
                : AppColors.success,
            isPulse: stokMenipis > 0,
          ),

          /// KATEGORI
          _buildCard(
            context,
            icon: Icons.category,
            label: "Kategori",
            value: kategoriUnik.toString(),
            color: Colors.orange,
          ),

          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isPulse = false,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.cardColor, // ✅ ikut theme
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          isPulse
              ? PulseIcon(icon: icon, color: color)
              : Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color:
                  theme.textTheme.bodySmall?.color?.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          FittedBox(
            child: Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color, // 🔥 warna status tetap
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// =======================
/// ICON PULSE LOOP
/// =======================
class PulseIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  const PulseIcon({super.key, required this.icon, required this.color});

  @override
  State<PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<PulseIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Icon(widget.icon, color: widget.color, size: 24),
    );
  }
}
