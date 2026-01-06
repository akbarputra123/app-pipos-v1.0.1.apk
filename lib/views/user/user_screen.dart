import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../viewmodels/kelola_user_viewmodel.dart';
import 'card_user.dart';
import 'search_bar_user.dart';
import 'card_total_user.dart';
import 'edit_user.dart';
import 'hapus_user.dart';
import 'tambah_user.dart';
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

      body: SizedBox(
        child: kelolaUserState.isLoading
            ? Shimmer.fromColors(
                baseColor: AppColors.card,
                highlightColor: Colors.white.withOpacity(0.6),
                child: Column(
                  children: [
                 
                    // Search bar + tombol tambah
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Card total user
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    // Dropdown role
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    // Label daftar user + refresh
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 5,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 120,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          Container(
                            width: 48,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // List user skeleton
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: 6,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            height: 90,
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.cardSoft.withOpacity(0.4),
                                width: 1.5,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  const SizedBox(height: 16),
                  // Search bar + tombol tambah
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
                          child: const Icon(Icons.person_add, size: 24),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        const TambahUserScreen(),
                                transitionsBuilder:
                                    (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                      child,
                                    ) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      );
                                    },
                                transitionDuration: const Duration(
                                  milliseconds: 300,
                                ),
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
                        ),
                      ],
                    ),
                  ),
                  // Card total user
                  // Card total user
                  if (kelolaUserState.users.isNotEmpty)
                    CardTotalUser(users: kelolaUserState.users),
                  SizedBox(height: 10,),
                  // Dropdown role
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ), // dikurangi
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardSoft, width: 1),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: filterRole,
                          isExpanded: true,
                          dropdownColor: AppColors.card,
                          style: const TextStyle(color: AppColors.textPrimary),
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
                            if (value != null)
                              setState(() => filterRole = value);
                          },
                        ),
                      ),
                    ),
                  ),

                // Label daftar user + refresh
Padding(
  padding: const EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 2,
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      /// ===== LABEL "DAFTAR USER" =====
      Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        child: const Text(
          "Daftar User",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      /// ===== BUTTON REFRESH =====
      Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: IconButton(
          onPressed: () {
            kelolaUserVM.getUsers(force: true);
          },
          icon: const Icon(
            Icons.refresh,
            color: AppColors.primary,
          ),
          tooltip: "Refresh",
        ),
      ),
    ],
  ),
),

                  // List user
                  Expanded(
                    child: ListView.builder(
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
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        EditUserScreen(
                                          user: user,
                                          onSave: (updatedUser) async {
                                            await kelolaUserVM.updateUser(
                                              updatedUser,
                                            );
                                          },
                                        ),
                                transitionsBuilder:
                                    (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                      child,
                                    ) {
                                      const begin = Offset(1.0, 0.0);
                                      const end = Offset.zero;
                                      const curve = Curves.easeInOut;
                                      final tween = Tween(
                                        begin: begin,
                                        end: end,
                                      ).chain(CurveTween(curve: curve));
                                      return SlideTransition(
                                        position: animation.drive(tween),
                                        child: child,
                                      );
                                    },
                              ),
                            );
                          },
                          onDelete: () async {
                            // Pastikan context di sini adalah context Scaffold
                            await showDeleteUserDialog(
                              context: context, // context dari UserScreen
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
      ),
    );
  }
}
