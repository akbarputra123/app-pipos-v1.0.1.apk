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
    final state = ref.watch(logViewModelProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          /// ================= LIST =================
          Expanded(
            child: Builder(
              builder: (_) {
                if (state.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state.error != null) {
                  return Center(
                    child: Text(
                      state.error!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                if (state.items.isEmpty) {
                  return const Center(
                    child: Text(
                      'Belum ada aktivitas',
                      style: TextStyle(color: Colors.white54),
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

          /// ================= PAGINATION =================
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0E0E0E),
              border: Border(
                top:
                    BorderSide(color: Colors.white.withOpacity(0.05)),
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
                    style: TextStyle(
                      color: state.page > 1
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                      fontSize: 10,
                    ),
                  ),
                ),
                Text(
                  'Halaman ${state.page} dari ${state.pages} ',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 10,
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
                  child: const Text(
                    'Berikutnya »',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ===============================
  /// ICON MAPPING
  /// ===============================
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

  /// ===============================
  /// TIME AGO
  /// ===============================
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
/// CARD LOG
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          /// ICON
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.redAccent, size: 20),
          ),

          const SizedBox(width: 12),

          /// TEXT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
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
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
