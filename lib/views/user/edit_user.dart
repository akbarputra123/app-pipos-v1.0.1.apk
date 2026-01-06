import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/kelola_user.dart';
import '../../config/theme.dart';
import '../../viewmodels/kelola_user_viewmodel.dart';

class EditUserScreen extends ConsumerStatefulWidget {
  final KelolaUser user;
  final Function(KelolaUser) onSave;

  const EditUserScreen({
    super.key,
    required this.user,
    required this.onSave,
  });

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
    _passwordController = TextEditingController(text: widget.user.password);
    _confirmPasswordController = TextEditingController(text: widget.user.password);
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
      password: _passwordController.text,
      role: _role,
      isActive: _isActive ? 1 : 0,
      createdAt: widget.user.createdAt,
    );

    final bool success = await ref.read(kelolaUserViewModelProvider.notifier)
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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textPrimary),
      filled: true,
      fillColor: AppColors.card,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.cardSoft, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text('Edit User'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card.withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(controller: _nameController, style: const TextStyle(color: AppColors.textPrimary), decoration: _inputDecoration('Name')),
                const SizedBox(height: 16),
                TextField(controller: _usernameController, style: const TextStyle(color: AppColors.textPrimary), decoration: _inputDecoration('Username')),
                const SizedBox(height: 16),
                TextField(controller: _emailController, style: const TextStyle(color: AppColors.textPrimary), keyboardType: TextInputType.emailAddress, decoration: _inputDecoration('Email')),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: _inputDecoration('Role'),
                  dropdownColor: AppColors.primaryDark,
                  style: const TextStyle(color: AppColors.textPrimary),
                  items: _roles.map((role) => DropdownMenuItem(
                    value: role,
                    child: Text(role, style: const TextStyle(color: AppColors.textPrimary)),
                  )).toList(),
                  onChanged: (value) { if (value != null) setState(() => _role = value); },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Aktifkan User?', style: TextStyle(color: AppColors.textPrimary)),
                    Switch(value: _isActive, activeColor: AppColors.primary, onChanged: (val) => setState(() => _isActive = val)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _inputDecoration('Password').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _inputDecoration('Konfirmasi Password').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
