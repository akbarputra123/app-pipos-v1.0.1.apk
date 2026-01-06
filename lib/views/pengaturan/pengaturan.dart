import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import 'profile_toko.dart';
import 'profile_owner.dart';
import 'data_section.dart';
import '../../services/auth_service.dart';

final userRoleProvider = FutureProvider.autoDispose<String>((ref) async {
  return await AuthService.getUserRole();
});

class PengaturanScreen extends ConsumerWidget {
  const PengaturanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(userRoleProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: roleAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text(
            "Error role: $e",
            style: const TextStyle(color: Colors.red),
          ),
        ),
        data: (roleRaw) {
          final role = roleRaw.toLowerCase().trim();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              /// ===== OWNER ONLY =====
              if (role == 'owner') ...[
                const ProfileOwnerScreen(),
                const SizedBox(height: 16),
              ],

              /// ===== STORE (OWNER & ADMIN) =====
              const ProfilTokoScreen(),
              const SizedBox(height: 16),

              /// ===== DATA (OWNER & ADMIN) =====
              const DataSection(),
            ],
          );
        },
      ),
    );
  }
}
