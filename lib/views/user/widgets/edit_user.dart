import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/kelola_user.dart';
import '../../../config/theme.dart';
import '../../../viewmodels/kelola_user_viewmodel.dart';

class EditUserScreen extends ConsumerStatefulWidget {
  final KelolaUser user;
  final Function(KelolaUser) onSave;

  const EditUserScreen({super.key, required this.user, required this.onSave});

  @override
  ConsumerState<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends ConsumerState<EditUserScreen> {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  late String _role;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isActive = true;

  final List<String> _roles = ['admin', 'cashier'];

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.user.name);
    _usernameController = TextEditingController(text: widget.user.username);
    _emailController = TextEditingController(text: widget.user.email);

    // 🔐 PASSWORD TIDAK DITAMPILKAN
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    _role = widget.user.role.toLowerCase();
    _isActive = widget.user.isActive == 1;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// ================= SAVE =================
  Future<void> _save() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password dan Konfirmasi tidak sama"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final updatedUser = KelolaUser(
      id: widget.user.id,
      ownerId: widget.user.ownerId,
      storeId: widget.user.storeId,
      name: _nameController.text,
      email: _emailController.text,
      username: _usernameController.text,
      password: _passwordController.text.isEmpty
          ? widget
                .user
                .password // ⬅️ pakai password lama
          : _passwordController.text, // ⬅️ password baru

      role: _role,
      isActive: _isActive ? 1 : 0,
      createdAt: widget.user.createdAt,
    );

    final success = await ref
        .read(kelolaUserViewModelProvider.notifier)
        .updateUser(updatedUser);

    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("User berhasil diperbarui!"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      final error = ref.read(kelolaUserViewModelProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? "Gagal memperbarui user"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// ================= INPUT DECORATION =================
  InputDecoration _inputDecoration(BuildContext context, String label) {
    final theme = Theme.of(context);

    return InputDecoration(
      labelText: label,
      labelStyle: theme.textTheme.bodyMedium,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

       appBar: AppBar(
        title: Text(
          "Edit User",
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              /// NAME
              TextField(
                controller: _nameController,
                style: theme.textTheme.bodyMedium,
                decoration: _inputDecoration(context, 'Name'),
              ),
              const SizedBox(height: 16),

              /// USERNAME
              TextField(
                controller: _usernameController,
                style: theme.textTheme.bodyMedium,
                decoration: _inputDecoration(context, 'Username'),
              ),
              const SizedBox(height: 16),

              /// EMAIL
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: theme.textTheme.bodyMedium,
                decoration: _inputDecoration(context, 'Email'),
              ),
              const SizedBox(height: 16),

              /// ROLE
              DropdownButtonFormField<String>(
                value: _role,
                decoration: _inputDecoration(context, 'Role'),
                dropdownColor: theme.cardColor,
                style: theme.textTheme.bodyMedium,
                items: _roles
                    .map(
                      (role) =>
                          DropdownMenuItem(value: role, child: Text(role)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _role = value);
                },
              ),
              const SizedBox(height: 16),

              /// ACTIVE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Aktifkan User?', style: theme.textTheme.bodyMedium),
                  Switch(
                    value: _isActive,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (val) => setState(() => _isActive = val),
                  ),
                ],
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

              /// SAVE BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Update User',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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
