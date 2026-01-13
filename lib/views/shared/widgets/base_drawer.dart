import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../viewmodels/plan_viewmodel.dart';
import '../../../viewmodels/theme_notifier.dart';
import 'base_menu_item.dart';
import 'theme_switcher.dart';

class BaseDrawer extends ConsumerWidget {
  final List<String> titles;
  final List<IconData> icons;
  final int selectedIndex;
  final Function(int) onTap;

  const BaseDrawer({
    super.key,
    required this.titles,
    required this.icons,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = ref.watch(themeNotifierProvider) == ThemeMode.dark;
    final auth = ref.watch(authViewModelProvider).userData;

    return Container(
      width: 260,
      color: theme.scaffoldBackgroundColor, // ✅ ikut theme
      child: Column(
        children: [
          const SizedBox(height: 32),

          /// ===== LOGO + PLAN =====
/// ===== LOGO + PLAN (MATCH DESIGN) =====
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.start, // ⬅️ RATA KIRI
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      /// ===== LOGO BULAT =====
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: Colors.redAccent,
            width: 2,
          ),
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/logo1.jpeg',
            fit: BoxFit.cover,
          ),
        ),
      ),

      const SizedBox(width: 10),

      /// ===== TEXT + BADGE =====
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// PIPOS TEXT
         Text(
  'PIPOS',
  style: theme.textTheme.titleLarge?.copyWith(
    color: theme.colorScheme.onSurface, // 🔥 AUTO HITAM / PUTIH
    fontWeight: FontWeight.w900,
    letterSpacing: 0.5,
  ),
),


          const SizedBox(width: 8),

          /// ===== PRO BADGE =====
          Consumer(
            builder: (_, ref, __) {
              final plan = ref.watch(planNotifierProvider);

              return plan.when(
                data: (p) {
                  final planText = (p?.data.plan ?? 'FREE').toUpperCase();

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent, // 🔥 MERAH SOLID
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      planText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),
        ],
      ),
    ],
  ),
),


          const SizedBox(height: 20),

          /// ===== THEME SWITCHER =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ThemeSwitcher(
              isDark: isDark,
              onDark: () =>
                  ref.read(themeNotifierProvider.notifier).toggle(true),
              onLight: () =>
                  ref.read(themeNotifierProvider.notifier).toggle(false),
            ),
          ),

          const SizedBox(height: 20),

          /// ===== MENU =====
          Expanded(
            child: ListView.builder(
              itemCount: titles.length,
              itemBuilder: (_, i) => BaseMenuItem(
                icon: icons[i],
                title: titles[i],
                active: i == selectedIndex,
                onTap: () => onTap(i),
              ),
            ),
          ),

          Divider(color: theme.dividerColor),

          /// ===== USER INFO =====
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      theme.colorScheme.primary.withOpacity(0.15),
                  child: Icon(
                    Icons.person_outline,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth?.username ?? '-',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        auth?.email ?? '-',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
