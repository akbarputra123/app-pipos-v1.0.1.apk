import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kimpos/viewmodels/profile_viewmodel.dart';
import 'package:kimpos/viewmodels/auth_viewmodel.dart';
import 'package:kimpos/viewmodels/plan_viewmodel.dart';

import 'package:kimpos/viewmodels/kelola_produk_viewmodel.dart';

import 'package:kimpos/views/dashboard/dashboard_screen.dart';
import 'package:kimpos/views/pengaturan/pengaturan.dart';
import 'package:kimpos/views/auth/login_screen.dart';
import 'package:kimpos/views/kasir/kasir_screen.dart';
import 'package:kimpos/views/produk/produk_screen.dart';
import 'package:kimpos/views/transaksi/transaksi.dart';
import 'package:kimpos/views/user/user_screen.dart';
import 'package:kimpos/views/laporan/laporan.dart';
import 'package:kimpos/views/log/log_aktivitas.dart';

import 'widgets/header.dart';
import 'widgets/base_drawer.dart';

class BaseSidebar extends ConsumerStatefulWidget {
  final String role; // owner | admin | kasir
  const BaseSidebar({super.key, required this.role});

  @override
  ConsumerState<BaseSidebar> createState() => _BaseSidebarState();
}

class _BaseSidebarState extends ConsumerState<BaseSidebar> {
  int selectedIndex = 0;
  bool isSidebarOpen = false;
  bool isLoggingOut = false;

  late List<String> titles;
  late List<IconData> icons;
  late List<Widget> pages;

  @override
  void initState() {
    super.initState();
    _setupMenu();

    Future.microtask(() {
      final auth = ref.read(authViewModelProvider);
      if (auth.userData != null) {
        ref.read(profileViewModelProvider.notifier).fetchProfile();
      }
    });

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  /// ================= MENU CONFIG =================
  void _setupMenu() {
    if (widget.role == 'owner' || widget.role == 'admin') {
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

  /// ================= MENU TAP =================
  Future<void> _onTap(int index) async {
    if (titles[index] == 'Logout') {
      final confirm = await _confirmLogout();
      if (confirm != true) return;

      setState(() {
        isSidebarOpen = false;
        isLoggingOut = true;
      });

      try {
        await ref.read(authViewModelProvider.notifier).logout();

        ref.invalidate(profileViewModelProvider);
        ref.invalidate(planNotifierProvider);
        ref.invalidate(kelolaProdukViewModelProvider);

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout gagal: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => isLoggingOut = false);
        }
      }
      return;
    }

    setState(() {
      selectedIndex = index;
      isSidebarOpen = false;
    });
  }

  /// ================= LOGOUT DIALOG =================
Future<bool?> _confirmLogout() {
  final theme = Theme.of(context);

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      bool loading = false;

      return StatefulBuilder(
        builder: (_, setStateDialog) {
          return AlertDialog(
            backgroundColor: theme.dialogBackgroundColor, // ✅ theme aware
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Konfirmasi Logout',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Apakah kamu yakin ingin logout?',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
              ),
            ),
            actions: [
              /// ===== BATAL =====
              TextButton(
                onPressed:
                    loading ? null : () => Navigator.pop(context, false),
                child: Text(
                  'Batal',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
              ),

              /// ===== LOGOUT =====
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error, // ✅ merah theme
                  foregroundColor: theme.colorScheme.onError,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: const Size(90, 40),
                ),
                onPressed: loading
                    ? null
                    : () async {
                        setStateDialog(() => loading = true);
                        await Future.delayed(
                          const Duration(milliseconds: 300),
                        );
                        Navigator.pop(context, true);
                      },
                child: loading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onError,
                        ),
                      )
                    : const Text('Logout'),
              ),
            ],
          );
        },
      );
    },
  );
}


  /// ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Column(
            children: [
              BaseHeader(
                title: titles[selectedIndex],
                onMenuTap: () => setState(() => isSidebarOpen = true),
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
                    child: BaseDrawer(
                      titles: titles,
                      icons: icons,
                      selectedIndex: selectedIndex,
                      onTap: _onTap,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
