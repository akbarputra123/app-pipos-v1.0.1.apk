import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/kelola_user.dart';
import '../../../viewmodels/kelola_user_viewmodel.dart';


class TambahUserScreen extends ConsumerStatefulWidget {
  const TambahUserScreen({super.key});

  @override
  ConsumerState<TambahUserScreen> createState() => _TambahUserScreenState();
}

class _TambahUserScreenState extends ConsumerState<TambahUserScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailController = TextEditingController();

  String _role = 'cashier';
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isActive = true;

  final List<String> _roles = ['admin', 'cashier'];

  InputDecoration _inputDecoration(BuildContext context, String label) {
    final theme = Theme.of(context);

    return InputDecoration(
      labelText: label,
      labelStyle: theme.textTheme.bodySmall,
      filled: true,
      fillColor: theme.cardColor,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  Future<void> _saveUser() async {
  if (_passwordController.text != _confirmPasswordController.text) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Password dan Konfirmasi tidak sama"),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  final newUser = KelolaUser(
    id: 0,
    ownerId: 0,
    storeId: 0,
    name: _nameController.text,
    email: _emailController.text,
    username: _usernameController.text,
    password: _passwordController.text,
    role: _role,
    isActive: _isActive ? 1 : 0,
    createdAt: DateTime.now(),
  );

  final vm = ref.read(kelolaUserViewModelProvider.notifier);
  final success = await vm.createUser(newUser);

  if (!mounted) return;

  if (success) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("User berhasil ditambahkan"),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  } else {
    final error =
        ref.read(kelolaUserViewModelProvider).errorMessage ?? "";

    /// 🔥 DETEKSI USERNAME SUDAH DIGUNAKAN
    if (error.toLowerCase().contains('username')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Username sudah digunakan, silakan pilih username lain",
          ),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.isNotEmpty
              ? error
              : "Gagal menambahkan user"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(kelolaUserViewModelProvider);
    final isLoading = state.isLoading;

    final hasAdmin = state.users.any(
      (u) => u.role.toLowerCase().trim() == 'admin',
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
       appBar: AppBar(
        title: Text(
          "Tambah User",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.cardColor, // ✅ ikut dark / light
        foregroundColor:
            theme.textTheme.titleMedium?.color, // teks & icon otomatis kontras
        elevation: 0,
        iconTheme: IconThemeData(color: theme.iconTheme.color, size: 26),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Divider(
            height: 2,
            thickness: 2,
            color: theme.colorScheme.primary, // aksen brand tetap
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                style: theme.textTheme.bodyMedium,
                decoration: _inputDecoration(context, 'Nama'),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _usernameController,
                style: theme.textTheme.bodyMedium,
                decoration: _inputDecoration(context, 'Username'),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: theme.textTheme.bodyMedium,
                decoration: _inputDecoration(context, 'Email'),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _role,
                decoration: _inputDecoration(context, 'Role'),
                dropdownColor: theme.cardColor,
                style: theme.textTheme.bodyMedium,
                items: _roles
                    .where((r) => r != 'admin' || !hasAdmin)
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => _role = v!),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: theme.textTheme.bodyMedium,
                decoration: _inputDecoration(context, 'Password').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: theme.iconTheme.color,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                style: theme.textTheme.bodyMedium,
                decoration: _inputDecoration(context, 'Konfirmasi Password')
                    .copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: theme.iconTheme.color,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _saveUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Tambah User',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
