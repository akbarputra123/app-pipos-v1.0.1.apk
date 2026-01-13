import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../viewmodels/profile_viewmodel.dart';

class ProfilTokoScreen extends ConsumerStatefulWidget {
  const ProfilTokoScreen({super.key});

  @override
  ConsumerState<ProfilTokoScreen> createState() =>
      _ProfilTokoScreenState();
}

class _ProfilTokoScreenState
    extends ConsumerState<ProfilTokoScreen> {
  double tax = 0.0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      ref.read(profileViewModelProvider.notifier).fetchProfile();
      tax = await ref
          .read(profileViewModelProvider.notifier)
          .fetchTaxPercentage();
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(profileViewModelProvider);
    final data = state.store;

    if (state.isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    if (data == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _box(theme),
        child: Text(
          state.error ?? "Profil toko tidak ditemukan",
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
                        color: theme.colorScheme.primary
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.store,
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
                            "Informasi Toko",
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(
                                    fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Data toko yang digunakan untuk identitas & nota",
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showEditDialog(data),
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

              _row(theme, "ID", data.id.toString()),
              _row(theme, "Nama Toko", data.name),
              _row(theme, "Alamat", data.address),
              _row(theme, "Telepon", data.phone),
              _row(theme, "PPN", "${tax.toStringAsFixed(0)} %"),
              _row(theme, "Receipt Template", data.receiptTemplate),
            ],
          ),
        ),

        /// ================= LOADING OVERLAY =================
        if (_isSaving) ...[
          Positioned.fill(
            child: Container(
              color:
                  theme.colorScheme.background.withOpacity(0.6),
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

  /// ================= EDIT DIALOG =================
  void _showEditDialog(data) {
    final theme = Theme.of(context);

    final nameCtrl = TextEditingController(text: data.name);
    final addressCtrl =
        TextEditingController(text: data.address);
    final phoneCtrl =
        TextEditingController(text: data.phone);
    final taxCtrl =
        TextEditingController(text: tax.toStringAsFixed(0));
    final receiptCtrl =
        TextEditingController(text: data.receiptTemplate);

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
                "Edit Informasi Toko",
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              _input(theme, "Nama Toko", nameCtrl),
              _input(theme, "Alamat", addressCtrl),
              _input(theme, "Telepon", phoneCtrl),
              _input(
                theme,
                "Receipt Template",
                receiptCtrl,
                maxLines: 3,
              ),
              _input(
                theme,
                "PPN (%)",
                taxCtrl,
                keyboardType: TextInputType.number,
              ),

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
                          await ref
                              .read(profileViewModelProvider
                                  .notifier)
                              .updateProfile({
                            "name": nameCtrl.text,
                            "address": addressCtrl.text,
                            "phone": phoneCtrl.text,
                            "receipt_template":
                                receiptCtrl.text,
                          });

                          await ref
                              .read(profileViewModelProvider
                                  .notifier)
                              .updateTaxPercentage(
                                double.tryParse(taxCtrl.text) ??
                                    0,
                              );

                          await ref
                              .read(profileViewModelProvider
                                  .notifier)
                              .fetchProfile();

                          tax = await ref
                              .read(profileViewModelProvider
                                  .notifier)
                              .fetchTaxPercentage();

                          if (!mounted) return;

                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            const SnackBar(
                              backgroundColor:
                                  Colors.green,
                              content: Text(
                                  "✅ Profil toko berhasil disimpan"),
                            ),
                          );
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
