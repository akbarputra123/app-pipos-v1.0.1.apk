import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../viewmodels/owner_viewmodel.dart';

class ProfileOwnerScreen extends ConsumerStatefulWidget {
  const ProfileOwnerScreen({super.key});

  @override
  ConsumerState<ProfileOwnerScreen> createState() =>
      _ProfileOwnerScreenState();
}

class _ProfileOwnerScreenState
    extends ConsumerState<ProfileOwnerScreen> {
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(ownerViewModelProvider.notifier).fetchOwnerProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(ownerViewModelProvider);
    final owner = state.owner;

    if (state.isLoading && owner == null) {
      return Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.primary,
        ),
      );
    }

    if (owner == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _box(theme),
        child: Text(
          state.error ?? "Data owner tidak ditemukan",
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.error),
        ),
      );
    }

    return Stack(
      children: [
        /// ================= MAIN CONTENT =================
        Container(
          decoration: _box(theme),
          child: Column(
            children: [
              /// ================= HEADER =================
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.business,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Informasi Bisnis (Owner)",
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(
                                    fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Data bisnis utama milik owner",
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showEditDialog(owner),
                      icon: const Icon(Icons.edit,
                          size: 16, color: Colors.white),
                      label: const Text(
                        "Edit",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),

              Divider(color: theme.dividerColor),

              _row(theme, "ID", owner.id.toString()),
              _row(theme, "Nama Bisnis", owner.businessName),
              _row(theme, "Email", owner.email),
              _row(theme, "Telepon", owner.phone),
              _row(theme, "Alamat", owner.address),
              _row(
                theme,
                "Created At",
                DateFormat('dd MMM yyyy, HH:mm')
                    .format(owner.createdAt),
              ),
            ],
          ),
        ),

        /// ================= LOADING OVERLAY =================
        if (_isSaving) ...[
          Positioned.fill(
            child: Container(
              color: theme.colorScheme.background
                  .withOpacity(0.6),
            ),
          ),
          Positioned.fill(
            child: Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// ================= EDIT DIALOG =================
  void _showEditDialog(owner) {
    final theme = Theme.of(context);

    final nameCtrl =
        TextEditingController(text: owner.businessName);
    final emailCtrl = TextEditingController(text: owner.email);
    final phoneCtrl = TextEditingController(text: owner.phone);
    final addressCtrl =
        TextEditingController(text: owner.address);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom:
                MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Edit Informasi Owner",
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              _input(theme, "Nama Bisnis", nameCtrl),
              _input(theme, "Email", emailCtrl,
                  keyboardType:
                      TextInputType.emailAddress),
              _input(theme, "Telepon", phoneCtrl,
                  keyboardType:
                      TextInputType.phone),
              _input(theme, "Alamat", addressCtrl,
                  maxLines: 2),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () =>
                          Navigator.pop(context),
                      child: Text(
                        "Batal",
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(
                                color: theme.hintColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            theme.colorScheme.error,
                      ),
                      child: const Text(
                        "Simpan",
                        style:
                            TextStyle(color: Colors.white),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        setState(() => _isSaving = true);

                        try {
                          final success = await ref
                              .read(ownerViewModelProvider
                                  .notifier)
                              .updateOwnerProfile({
                            "business_name":
                                nameCtrl.text,
                            "email": emailCtrl.text,
                            "phone": phoneCtrl.text,
                            "address": addressCtrl.text,
                          });

                          if (!mounted) return;

                          if (success) {
                            await ref
                                .read(
                                    ownerViewModelProvider
                                        .notifier)
                                .fetchOwnerProfile();

                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                backgroundColor:
                                    Colors.green,
                                content: const Text(
                                    "✅ Profil owner berhasil diperbarui"),
                              ),
                            );
                          } else {
                            throw "Gagal memperbarui data";
                          }
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.red,
                              content: Text(
                                  "❌ Gagal menyimpan data: $e"),
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(
                                () => _isSaving = false);
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ================= ROW =================
  Widget _row(ThemeData theme, String label, String value) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _input(
    ThemeData theme,
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: theme.textTheme.bodyMedium,
        cursorColor: theme.colorScheme.primary,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: theme.cardColor,
          labelStyle: theme.textTheme.bodySmall,
          enabledBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: theme.dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: theme.colorScheme.primary),
          ),
        ),
      ),
    );
  }

  BoxDecoration _box(ThemeData theme) {
    return BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: theme.shadowColor.withOpacity(0.3),
          blurRadius: 12,
        ),
      ],
    );
  }
}
