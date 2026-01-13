import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../viewmodels/auth_viewmodel.dart';
import '../shared/base_sidebar.dart';

class PilihTokoDialog extends ConsumerWidget {
  const PilihTokoDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authViewModelProvider);
    final user = authState.userData;

    return Dialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 420, // 🔥 BATAS TINGGI DIALOG
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              /// ================= HEADER =================
              Row(
                children: [
                  const Icon(Icons.store, color: Colors.redAccent),
                  const SizedBox(width: 8),
                  Text(
                    'Pilih Toko',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Divider(color: theme.dividerColor),
              const SizedBox(height: 8),

              /// ================= LIST (SCROLLABLE) =================
              Expanded(
                child: user == null || user.stores.isEmpty
                    ? const Center(child: Text('Tidak ada toko tersedia'))
                    : ListView.separated(
                        itemCount: user.stores.length,
                        separatorBuilder: (_, __) =>
                            Divider(color: theme.dividerColor),
                        itemBuilder: (context, i) {
                          final store = user.stores[i];

                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              // 1️⃣ simpan toko aktif
                              await ref
                                  .read(authViewModelProvider.notifier)
                                  .setActiveStore(store.id);

                              // 2️⃣ tutup dialog DULU
                              Navigator.of(context).pop();

                              // 3️⃣ tunggu 1 frame (WAJIB)
                              await Future.delayed(
                                const Duration(milliseconds: 50),
                              );

                              // 4️⃣ navigasi pakai ROOT navigator
                              Navigator.of(
                                context,
                                rootNavigator: true,
                              ).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const BaseSidebar(role: 'owner'),
                                ),
                                (route) => false,
                              );
                            },

                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 6,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.greenAccent.withOpacity(
                                        0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.storefront,
                                      color: Colors.greenAccent,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          store.name,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          store.address,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
