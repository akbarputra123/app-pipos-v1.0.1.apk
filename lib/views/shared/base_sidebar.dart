import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kimpos/viewmodels/profile_viewmodel.dart';
import 'package:kimpos/views/dashboard/dashboard_screen.dart';
import 'package:kimpos/views/pengaturan/pengaturan.dart';

import '../../viewmodels/plan_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/theme_notifier.dart';
import '../../viewmodels/kelola_produk_viewmodel.dart';

import '../auth/login_screen.dart';
import '../kasir/kasir_screen.dart';
import '../produk/produk_screen.dart';
import '../transaksi/transaksi.dart';
import '../user/user_screen.dart';
import '../laporan/laporan.dart';
import '../log/log_aktivitas.dart';

class BaseSidebar extends ConsumerStatefulWidget {
  final String role; // owner | admin | kasir
  const BaseSidebar({super.key, required this.role});

  @override
  ConsumerState<BaseSidebar> createState() => _BaseSidebarState();
}

class _BaseSidebarState extends ConsumerState<BaseSidebar> {
  int selectedIndex = 0;
  bool isSidebarOpen = false;

  late List<String> titles;
  late List<IconData> icons;
  late List<Widget> pages;

  @override
  void initState() {
    super.initState();
    _setupMenu();

    /// 🔥 WAJIB: FETCH STORE SETIAP LOGIN
    Future.microtask(() {
      ref.read(profileViewModelProvider.notifier).fetchProfile();
    });

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _setupMenu() {
    if (widget.role == 'owner') {
      titles = [
        'Beranda',
        'Produk',
        'Transaksi',
        'Karyawan',
        'Laporan',
        'Pengaturan',
        'Log Aktivitas',
        'Logout',
      ];
      icons = [
        Icons.home,
        Icons.inventory,
        Icons.receipt_long,
        Icons.people,
        Icons.bar_chart,
        Icons.settings,
        Icons.history,
        Icons.logout,
      ];
      pages = [
        const DashboardScreen(),
        const ProdukScreen(),
        const TransaksiScreen(),
        const UserScreen(),
        const LaporanScreen(),
        const PengaturanScreen(),
        const LogAktivitasScreen(),
        const SizedBox(),
      ];
    } else if (widget.role == 'admin') {
      titles = [
        'Beranda',
        'Produk',
        'Transaksi',
        'Karyawan',
        'Laporan',
        'Pengaturan',
        'Log Aktivitas',
        'Logout',
      ];
      icons = [
        Icons.home,
        Icons.inventory,
        Icons.receipt_long,
        Icons.people,
        Icons.bar_chart,
        Icons.settings,
        Icons.history,
        Icons.logout,
      ];
      pages = [
        const DashboardScreen(),
        const ProdukScreen(),
        const TransaksiScreen(),
        const UserScreen(),
        const LaporanScreen(),
        const PengaturanScreen(),
        const LogAktivitasScreen(),
        const SizedBox(),
      ];
    } else {
      titles = ['Beranda', 'Kasir', 'Produk', 'Logout'];
      icons = [
        Icons.home,
        Icons.point_of_sale,
        Icons.inventory,
        Icons.logout,
      ];
      pages = [
        const DashboardScreen(),
        const KasirScreen(),
        const ProdukScreen(),
        const SizedBox(),
      ];
    }
  }

  
void _onTap(int index) {
  if (titles[index] == 'Logout') {
    /// ================= RESET STATE =================
    ref.read(authViewModelProvider.notifier).logout();

    // 🔥 RESET CACHE PROVIDER
    ref.invalidate(profileViewModelProvider);
    ref.invalidate(planNotifierProvider);
    ref.invalidate(kelolaProdukViewModelProvider);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
    return;
  }

  setState(() {
    selectedIndex = index;
    isSidebarOpen = false;
  });
}


  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeNotifierProvider) == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                height: 96,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  color: Colors.black,
                  border: Border(
                    bottom: BorderSide(color: Colors.red, width: 2),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () => setState(() => isSidebarOpen = true),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Consumer(
                          builder: (context, ref, _) {
                            final store =
                                ref.watch(profileViewModelProvider).store;
                            return Text(
                              store?.name ?? 'PIPOS',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            );
                          },
                        ),
                        Text(
                          titles[selectedIndex],
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(child: pages[selectedIndex]),
            ],
          ),

          /// ================= SIDEBAR =================
          if (isSidebarOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => isSidebarOpen = false),
                child: Container(
                  color: Colors.black54,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 260,
                      color: Colors.black,
                      child: Column(
                        children: [
                          const SizedBox(height: 32),

                          /// ===== HEADER =====
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: Image.asset(
                                  'assets/images/logo1.jpeg',
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'PIPOS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Consumer(
                                builder: (context, ref, _) {
                                  final plan =
                                      ref.watch(planNotifierProvider);
                                  return plan.when(
                                    data: (p) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        p?.data.plan ?? 'FREE',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    loading: () => const SizedBox(),
                                    error: (_, __) => const SizedBox(),
                                  );
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          /// ===== THEME BUTTON =====
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                _themeButton(
                                  icon: Icons.dark_mode,
                                  text: 'Dark',
                                  active: isDark,
                                  onTap: () => ref
                                      .read(themeNotifierProvider.notifier)
                                      .toggle(true),
                                ),
                                const SizedBox(width: 10),
                                _themeButton(
                                  icon: Icons.light_mode,
                                  text: 'Light',
                                  active: !isDark,
                                  onTap: () => ref
                                      .read(themeNotifierProvider.notifier)
                                      .toggle(false),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          /// ===== MENU =====
                          Expanded(
                            child: ListView.builder(
                              itemCount: titles.length,
                              itemBuilder: (context, i) {
                                final active = i == selectedIndex;
                                return GestureDetector(
                                  onTap: () => _onTap(i),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: active
                                          ? Colors.red
                                          : Colors.transparent,
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          icons[i],
                                          color: active
                                              ? Colors.white
                                              : Colors.white54,
                                        ),
                                        const SizedBox(width: 14),
                                        Text(
                                          titles[i],
                                          style: TextStyle(
                                            color: active
                                                ? Colors.white
                                                : Colors.white70,
                                            fontWeight: active
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
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
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _themeButton({
    required IconData icon,
    required String text,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red),
            color: active ? Colors.red : Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: active ? Colors.white : Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(
                  color: active ? Colors.white : Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
