import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../viewmodels/log_viewmodel.dart';
import '../../models/log_model.dart';

class LogAktivitasScreen extends ConsumerStatefulWidget {
  const LogAktivitasScreen({super.key});

  @override
  ConsumerState<LogAktivitasScreen> createState() =>
      _LogAktivitasScreenState();
}

class _LogAktivitasScreenState
    extends ConsumerState<LogAktivitasScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(logViewModelProvider.notifier).fetchLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(logViewModelProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          /// ================= LIST =================
          Expanded(
            child: Builder(
              builder: (_) {
                if (state.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  );
                }

                if (state.error != null) {
                  return Center(
                    child: Text(
                      state.error!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  );
                }

                if (state.items.isEmpty) {
                  return Center(
                    child: Text(
                      'Belum ada aktivitas',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.hintColor),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.items.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final log = state.items[index];
                    return _LogCard(
                      title: log.action ?? 'Aktivitas',
                      subtitle:
                          log.description ?? 'Tidak ada deskripsi',
                      user: log.user ?? '-',
                      time: _timeAgo(log.createdAt),
                      icon: _iconFromAction(log.action),
                    );
                  },
                );
              },
            ),
          ),

          /// ================= PAGINATION (SAFE AREA) =================
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(
                  top: BorderSide(color: theme.dividerColor),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: state.page > 1
                        ? () {
                            ref
                                .read(logViewModelProvider.notifier)
                                .fetchLogs(limit: state.limit);
                          }
                        : null,
                    child: Text(
                      'Sebelumnya',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: state.page > 1
                            ? theme.textTheme.bodySmall?.color
                            : theme.disabledColor,
                      ),
                    ),
                  ),
                  Text(
                    'Halaman ${state.page} dari ${state.pages}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  TextButton(
                    onPressed: state.page < state.pages
                        ? () {
                            ref
                                .read(logViewModelProvider.notifier)
                                .loadMore();
                          }
                        : null,
                    child: Text(
                      'Berikutnya »',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ================= ICON MAPPING =================
  IconData _iconFromAction(String? action) {
    final a = action?.toLowerCase() ?? '';
    if (a.contains('login')) return Icons.login;
    if (a.contains('logout')) return Icons.logout;
    if (a.contains('delete')) return Icons.delete;
    if (a.contains('update')) return Icons.edit;
    if (a.contains('create')) return Icons.add_circle;
    if (a.contains('setting')) return Icons.settings;
    return Icons.history;
  }

  /// ================= TIME AGO =================
  String _timeAgo(DateTime? date) {
    if (date == null) return '-';

    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.isNegative) {
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    }

    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';

    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }
}

/// =======================================================
/// CARD LOG (DARK / LIGHT READY)
/// =======================================================
class _LogCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String user;
  final String time;
  final IconData icon;

  const _LogCard({
    required this.title,
    required this.subtitle,
    required this.user,
    required this.time,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          /// ICON
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.error,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          /// TEXT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),

          /// USER + TIME
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                user,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
