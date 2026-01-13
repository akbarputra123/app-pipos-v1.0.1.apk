import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../viewmodels/profile_viewmodel.dart';

class BaseHeader extends ConsumerWidget {
  final String title;
  final VoidCallback onMenuTap;

  const BaseHeader({
    super.key,
    required this.title,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return SafeArea(
      bottom: false,
      child: Container(
        height: 88, // ⬅️ sedikit lebih ramping (tidak mengurangi isi)
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.primary,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.menu,
                color: theme.iconTheme.color,
              ),
              onPressed: onMenuTap,
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Consumer(
                    builder: (_, ref, __) {
                      final store =
                          ref.watch(profileViewModelProvider).store;
                      return Text(
                        store?.name ?? 'PIPOS',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color
                          ?.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
