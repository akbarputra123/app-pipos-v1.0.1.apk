import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../viewmodels/owner_viewmodel.dart';

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
    final state = ref.watch(ownerViewModelProvider);
    final owner = state.owner;

    if (state.isLoading && owner == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (owner == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _box(),
        child: Text(
          state.error ?? "Data owner tidak ditemukan",
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    return Stack(
      children: [
        /// ================= MAIN CONTENT =================
        Container(
          decoration: _box(),
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
                        color: Colors.blue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          const Icon(Icons.business, color: Colors.blue),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Informasi Bisnis (Owner)",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Data bisnis utama milik owner",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showEditDialog(owner),
                      icon: const Icon(Icons.edit,
                          size: 16, color: Colors.white),
                      label: const Text("Edit",
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: Colors.grey),

              _row("ID", owner.id.toString()),
              _row("Nama Bisnis", owner.businessName),
              _row("Email", owner.email),
              _row("Telepon", owner.phone),
              _row("Alamat", owner.address),
              _row(
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
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),
          const Positioned.fill(
            child: Center(
              child:
                  CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
        ],
      ],
    );
  }

  /// ================= EDIT DIALOG =================
  void _showEditDialog(owner) {
    final nameCtrl =
        TextEditingController(text: owner.businessName);
    final emailCtrl = TextEditingController(text: owner.email);
    final phoneCtrl = TextEditingController(text: owner.phone);
    final addressCtrl = TextEditingController(text: owner.address);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF1A1A1A),
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
                const Text(
                  "Edit Informasi Owner",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                _input("Nama Bisnis", nameCtrl),
                _input("Email", emailCtrl,
                    keyboardType: TextInputType.emailAddress),
                _input("Telepon", phoneCtrl,
                    keyboardType: TextInputType.phone),
                _input("Alamat", addressCtrl, maxLines: 2),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Batal",
                          style:
                              TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
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
                              "business_name": nameCtrl.text,
                              "email": emailCtrl.text,
                              "phone": phoneCtrl.text,
                              "address": addressCtrl.text,
                            });

                            if (!mounted) return;

                            if (success) {
                              await ref
                                  .read(ownerViewModelProvider
                                      .notifier)
                                  .fetchOwnerProfile();

                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  backgroundColor:
                                      Colors.green,
                                  content: Text(
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
                              setState(() => _isSaving = false);
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
        );
      },
    );
  }

  /// ================= ROW =================
  Widget _row(String label, String value) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child:
                Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _input(
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
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          enabledBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: Colors.grey.shade700),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red),
          ),
        ),
      ),
    );
  }

  BoxDecoration _box() {
    return BoxDecoration(
      color: const Color(0xFF1A1A1A),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 12,
        ),
      ],
    );
  }
}
