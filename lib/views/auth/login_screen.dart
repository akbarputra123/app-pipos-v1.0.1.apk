import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/kelola_user_viewmodel.dart';
import '../shared/base_sidebar.dart';
import '../pilih toko/pilih_toko.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController identifierController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool obscurePassword = true;

  /// ================= INPUT DECORATION (THEME AWARE) =================
  InputDecoration _inputDecoration(
    BuildContext context,
    String hint, {
    Widget? suffix,
  }) {
    final theme = Theme.of(context);

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
      ),
      filled: true,
      fillColor: theme.cardColor.withOpacity(0.85),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: theme.dividerColor.withOpacity(0.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: theme.colorScheme.primary,
          width: 1.4,
        ),
      ),
      suffixIcon: suffix,
    );
  }

  /// ================= LOGIN HANDLER =================
  Future<void> _login() async {
    final identifier = identifierController.text.trim();
    final password = passwordController.text.trim();

    await ref
        .read(authViewModelProvider.notifier)
        .login(identifier: identifier, password: password);

    final state = ref.read(authViewModelProvider);

    if (state.authResponse == null || state.authResponse!.success != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.errorMessage ?? 'Login gagal')),
      );
      return;
    }

    // reset cache user
    ref.read(kelolaUserViewModelProvider.notifier).reset();

    final role = state.authResponse!.user!.role;

    if (role == 'owner') {
      /// 🔥 POPUP PILIH TOKO (DI ATAS LOGIN)
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PilihTokoDialog(),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BaseSidebar(role: role),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authViewModelProvider);

    final bool isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            /// ================= BACKGROUND =================
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? const [
                          Color(0xFF160808),
                          Color(0xFF100606),
                          Color(0xFF160808),
                        ]
                      : [
                          theme.colorScheme.primary.withOpacity(0.08),
                          theme.scaffoldBackgroundColor,
                          theme.scaffoldBackgroundColor,
                        ],
                ),
              ),
            ),

            /// ================= RED GLOW =================
            Align(
              alignment: const Alignment(0, -0.9),
              child: Container(
                width: 520,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withOpacity(0.18),
                ),
              ),
            ),

            /// ================= LOGIN CARD =================
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: theme.cardColor.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.6),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            /// ================= LOGO =================
                            Column(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: theme.colorScheme.primary,
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/images/logo1.jpeg',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'PIPos',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                                Text(
                                  'Point of Sales',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            /// ================= IDENTIFIER =================
                            Text('Email atau Username',
                                style: theme.textTheme.bodyMedium),
                            const SizedBox(height: 8),
                            TextField(
                              controller: identifierController,
                              style: theme.textTheme.bodyLarge,
                              decoration:
                                  _inputDecoration(context, 'Email / Username'),
                            ),

                            const SizedBox(height: 16),

                            /// ================= PASSWORD =================
                            Text('Password',
                                style: theme.textTheme.bodyMedium),
                            const SizedBox(height: 8),
                            TextField(
                              controller: passwordController,
                              obscureText: obscurePassword,
                              style: theme.textTheme.bodyLarge,
                              decoration: _inputDecoration(
                                context,
                                'Password',
                                suffix: IconButton(
                                  icon: Icon(
                                    obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      obscurePassword = !obscurePassword;
                                    });
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            /// ================= BUTTON =================
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed:
                                    authState.isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      theme.colorScheme.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: authState.isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      )
                                    : const Text(
                                        'Masuk',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 18),

                            Text(
                              'v1.0.0 • Secure Login',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
