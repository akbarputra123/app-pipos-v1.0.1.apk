import 'package:flutter/material.dart';

/// =======================================================
/// CARD PRODUK (SCROLLABLE + EDIT/HAPUS)
/// =======================================================
class CardProduk extends StatelessWidget {
  final String title;
  final IconData titleIcon;
  final List<ProdukItem> items;

  const CardProduk({
    super.key,
    required this.title,
    required this.titleIcon,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxHeight: 300, // ⬅️ tinggi card tetap (AMAN GRID)
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ===== HEADER =====
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                Icon(
                  titleIcon,
                  size: 14,
                  color: Colors.redAccent,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: Colors.white.withOpacity(0.06),
          ),

          /// ===== LIST PRODUK (SCROLLABLE) =====
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'Tidak ada data',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(8),
                    physics: const BouncingScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      return _ProdukItemTile(item: items[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// =======================================================
/// ITEM PRODUK (ULTRA COMPACT - AMAN GRID)
/// =======================================================
class _ProdukItemTile extends StatelessWidget {
  final ProdukItem item;

  const _ProdukItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isCritical = item.isCritical;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: isCritical
            ? const Color(0xFF2A1515)
            : const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCritical
              ? Colors.redAccent.withOpacity(0.35)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          /// ICON (LEBIH KECIL)
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Icon(
              Icons.inventory_2,
              size: 14,
              color: Colors.redAccent,
            ),
          ),

          const SizedBox(width: 6),

          /// INFO (SUPER COMPACT)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,     // ⬅️ lebih kecil
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Stok ${item.stock}/${item.minStock}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 8.5, // ⬅️ lebih kecil
                          height: 1.1,
                          color: Colors.white.withOpacity(0.55),
                        ),
                      ),
                    ),
                    if (isCritical)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'K',
                          style: TextStyle(
                            fontSize: 8,  // ⬅️ kecil
                            height: 1,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 4),

          /// ACTIONS (KECIL)
       
        ],
      ),
    );
  }
}


/// =======================================================
/// ACTION ICON
/// =======================================================
class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _ActionIcon({
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 14,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// =======================================================
/// MODEL
/// =======================================================
class ProdukItem {
  final String name;
  final int stock;
  final int minStock;
  final bool isCritical;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  ProdukItem({
    required this.name,
    required this.stock,
    required this.minStock,
    this.isCritical = false,
    this.onEdit,
    this.onDelete,
  });
}
