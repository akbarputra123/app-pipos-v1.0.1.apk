// lib/views/produk/total_produk_card.dart
import 'package:flutter/material.dart';
import '../../models/produk_model.dart';
import '../../config/theme.dart';

class TotalProdukCard extends StatelessWidget {
  final List<ProdukModel> produkList;

  const TotalProdukCard({super.key, required this.produkList});

  int get totalProduk => produkList.length;

  int get stokMenipis => produkList.where((p) => p.stock < 10).length;

  int get kategoriUnik => produkList.map((p) => p.category ?? "Tidak Ada").toSet().length;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(width: 8),
          _buildCard(
            icon: Icons.shopping_bag,
            label: "Total Produk",
            value: totalProduk.toString(),
            color: AppColors.primary,
          ),
          _buildCard(
            icon: Icons.warning,
            label: "Stok Menipis",
            value: stokMenipis.toString(),
            color: stokMenipis > 0 ? Colors.redAccent : Colors.green,
            isPulse: stokMenipis > 0, // hanya berdenyut jika stok menipis > 0
          ),
          _buildCard(
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

  Widget _buildCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isPulse = false,
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
          // Icon dengan animasi pulse loop
          isPulse
              ? const PulseIcon(icon: Icons.warning, color: Colors.redAccent)
              : Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget pulse loop
class PulseIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  const PulseIcon({super.key, required this.icon, required this.color});

  @override
  State<PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<PulseIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true); // loop berdenyut

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
