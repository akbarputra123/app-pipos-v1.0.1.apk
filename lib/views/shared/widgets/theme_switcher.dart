import 'package:flutter/material.dart';

class ThemeSwitcher extends StatelessWidget {
  final bool isDark;
  final VoidCallback onDark;
  final VoidCallback onLight;

  const ThemeSwitcher({
    super.key,
    required this.isDark,
    required this.onDark,
    required this.onLight,
  });

  Widget _btn(
  BuildContext context, {
  required IconData icon,
  required String text,
  required bool active,
  required VoidCallback onTap,
}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  /// ================= WARNA DINAMIS =================
  final Color activeBg = theme.colorScheme.primary;
  final Color activeBorder = theme.colorScheme.primary;

  final Color inactiveBorder = isDark
      ? Colors.white24 // 🌙 dark → border terang
      : Colors.black26; // 🌞 light → border gelap

  final Color textColor = active
      ? theme.colorScheme.onPrimary
      : theme.textTheme.bodyMedium!.color!;

  return Expanded(
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: active ? activeBg : Colors.transparent,
          border: Border.all(
            color: active ? activeBorder : inactiveBorder,
            width: active ? 1.8 : 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 6),
            Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _btn(
          context,
          icon: Icons.dark_mode,
          text: 'Dark',
          active: isDark,
          onTap: onDark,
        ),
        const SizedBox(width: 10),
        _btn(
          context,
          icon: Icons.light_mode,
          text: 'Light',
          active: !isDark,
          onTap: onLight,
        ),
      ],
    );
  }
}
