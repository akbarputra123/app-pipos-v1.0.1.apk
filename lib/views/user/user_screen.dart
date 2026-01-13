import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../viewmodels/kelola_user_viewmodel.dart';
import 'widgets/card_user.dart';
import 'widgets/search_bar_user.dart';
import 'widgets/card_total_user.dart';
import 'widgets/edit_user.dart';
import 'widgets/hapus_user.dart';
import 'widgets/tambah_user.dart';
import '../../config/theme.dart';

class UserScreen extends ConsumerStatefulWidget {
  const UserScreen({super.key});

  @override
  ConsumerState<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends ConsumerState<UserScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";
  String filterRole = "all";

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(kelolaUserViewModelProvider.notifier).getUsers(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final kelolaUserState = ref.watch(kelolaUserViewModelProvider);
    final kelolaUserVM = ref.read(kelolaUserViewModelProvider.notifier);

    final filteredUsers = kelolaUserState.users.where((user) {
      final query = searchQuery.toLowerCase();
      final matchesQuery =
          user.name.toLowerCase().contains(query) ||
          user.username.toLowerCase().contains(query);

      final matchesRole =
          filterRole == "all" || user.role.toLowerCase() == filterRole;

      return matchesQuery && matchesRole;
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: kelolaUserState.isLoading
          ? _buildShimmer(context)

          : Column(
              children: [
                const SizedBox(height: 16),

                /// ================= SEARCH + TAMBAH =================
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SearchBarUser(
                          controller: _searchController,
                          onChanged: (value) =>
                              setState(() => searchQuery = value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TambahUserScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Icon(Icons.person_add, size: 24),
                      ),
                    ],
                  ),
                ),

                /// ================= TOTAL USER =================
                if (kelolaUserState.users.isNotEmpty)
                  CardTotalUser(users: kelolaUserState.users),

                const SizedBox(height: 10),

                /// ================= DROPDOWN ROLE =================
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Builder(
                    builder: (context) {
                      final theme = Theme.of(context);

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: theme.cardColor, // ✅ ikut dark/light
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.dividerColor, // ✅ aman theme
                            width: 1,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: filterRole,
                            isExpanded: true,
                            dropdownColor:
                                theme.cardColor, // ✅ dropdown ikut theme
                            style:
                                theme.textTheme.bodyMedium, // ✅ text ikut theme
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: theme.iconTheme.color,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: "all",
                                child: Text("Semua Role"),
                              ),
                              DropdownMenuItem(
                                value: "admin",
                                child: Text("Admin"),
                              ),
                              DropdownMenuItem(
                                value: "cashier",
                                child: Text("Cashier"),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => filterRole = value);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),

                /// ================= LABEL + REFRESH =================
              Padding(
  padding: const EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 2,
  ),
  child: Builder(
    builder: (context) {
      final theme = Theme.of(context);

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /// ================= TITLE =================
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: theme.cardColor, // ✅ ikut theme
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              "Daftar User",
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          /// ================= REFRESH BUTTON =================
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor, // ✅ box di icon
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.35), // 🔥 shadow merah
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IconButton(
              tooltip: "Refresh",
              icon: Icon(
                Icons.refresh,
                color: theme.colorScheme.primary,
              ),
              onPressed: () {
                kelolaUserVM.getUsers(force: true);
              },
            ),
          ),
        ],
      );
    },
  ),
),

                /// ================= LIST USER (SATU-SATUNYA SCROLL) =================
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return CardUser(
                        user: user,
                        onEdit: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditUserScreen(
                                user: user,
                                onSave: (updatedUser) async {
                                  await kelolaUserVM.updateUser(updatedUser);
                                },
                              ),
                            ),
                          );
                        },
                        onDelete: () async {
                          await showDeleteUserDialog(
                            context: context,
                            ref: ref,
                            username: user.username,
                            userId: user.id,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  /// ================= SHIMMER (DARK / LIGHT AWARE) =================
Widget _buildShimmer(BuildContext context) {
  final theme = Theme.of(context);

  return Shimmer.fromColors(
    baseColor: theme.cardColor,
    highlightColor: theme.dividerColor.withOpacity(0.4),
    child: ListView.builder(
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.all(12),
        height: 90,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
  );
}

}
