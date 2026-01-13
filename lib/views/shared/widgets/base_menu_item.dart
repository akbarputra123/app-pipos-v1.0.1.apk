import 'package:flutter/material.dart';

class BaseMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool active;
  final VoidCallback onTap;

  const BaseMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color activeColor = theme.colorScheme.primary;
    final Color textColor = active
        ? theme.colorScheme.onPrimary
        : theme.textTheme.bodyMedium!.color!;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          color: active
              ? activeColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: textColor,
            ),
            const SizedBox(width: 14),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight:
                    active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
