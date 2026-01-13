import 'package:flutter/material.dart';

/// =======================================================
/// CARD PRODUK (THEME AWARE, FIX HEIGHT)
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
    final theme = Theme.of(context);

    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(
              theme.brightness == Brightness.dark ? 0.6 : 0.2,
            ),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          /// ================= HEADER =================
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                Icon(
                  titleIcon,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: theme.dividerColor,
          ),

          /// ================= LIST =================
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'Tidak ada data',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
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
/// ITEM PRODUK (THEME AWARE)
/// =======================================================
class _ProdukItemTile extends StatelessWidget {
  final ProdukItem item;

  const _ProdukItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCritical = item.isCritical;

    final Color bgColor = isCritical
        ? theme.colorScheme.error.withOpacity(0.12)
        : theme.colorScheme.surface;

    final Color borderColor = isCritical
        ? theme.colorScheme.error.withOpacity(0.4)
        : theme.dividerColor.withOpacity(0.5);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          /// ICON
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.inventory_2,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),

          const SizedBox(width: 12),

          /// INFO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Stok ${item.stock}/${item.minStock}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          height: 1.2,
                          color: theme.textTheme.bodySmall?.color
                              ?.withOpacity(0.65),
                        ),
                      ),
                    ),
                    if (isCritical)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'KRITIS',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            height: 1,
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          /// ACTIONS
          if (item.onEdit != null) ...[
            const SizedBox(width: 8),
            _ActionIcon(
              icon: Icons.edit,
              onTap: item.onEdit,
            ),
          ],
          if (item.onDelete != null) ...[
            const SizedBox(width: 6),
            _ActionIcon(
              icon: Icons.delete,
              onTap: item.onDelete,
            ),
          ],
        ],
      ),
    );
  }
}

/// =======================================================
/// ACTION ICON (THEME AWARE)
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
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: theme.iconTheme.color,
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
