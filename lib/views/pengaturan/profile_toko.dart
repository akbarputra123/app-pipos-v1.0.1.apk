import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../config/theme.dart';

class ProfilTokoScreen extends ConsumerStatefulWidget {
  const ProfilTokoScreen({super.key});

  @override
  ConsumerState<ProfilTokoScreen> createState() => _ProfilTokoScreenState();
}

class _ProfilTokoScreenState extends ConsumerState<ProfilTokoScreen> {
  double tax = 0.0;
  bool _isSaving = false; // 🔥 LOADING STATE

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
    final state = ref.watch(profileViewModelProvider);
    final data = state.store;

    if (state.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (data == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _box(),
        child: Text(
          state.error ?? "Profil toko tidak ditemukan",
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
                        color: Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.store, color: Colors.red),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Informasi Toko",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Data toko yang digunakan untuk identitas & nota",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showEditDialog(data),
                      icon:
                          const Icon(Icons.edit, size: 16, color: Colors.white),
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

              _row("ID", data.id.toString()),
              _row("Nama Toko", data.name),
              _row("Alamat", data.address),
              _row("Telepon", data.phone),
              _row("PPN", "${tax.toStringAsFixed(0)} %"),
              _row("Receipt Template", data.receiptTemplate),
            ],
          ),
        ),

        /// ================= LOADING OVERLAY =================
        if (_isSaving) ...[
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.6),
            ),
          ),
          const Positioned.fill(
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
        ],
      ],
    );
  }

  /// ================= ROW =================
  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.grey)),
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

/// ================= EDIT DIALOG =================
void _showEditDialog(data) {
  final nameCtrl = TextEditingController(text: data.name);
  final addressCtrl = TextEditingController(text: data.address);
  final phoneCtrl = TextEditingController(text: data.phone);
  final taxCtrl = TextEditingController(text: tax.toStringAsFixed(0));
  final receiptCtrl =
      TextEditingController(text: data.receiptTemplate); // ✅ BARU

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
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Edit Informasi Toko",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              _input("Nama Toko", nameCtrl),
              _input("Alamat", addressCtrl),
              _input("Telepon", phoneCtrl),

              /// ===== RECEIPT TEMPLATE =====
              _input(
                "Receipt Template",
                receiptCtrl,
                maxLines: 3,
              ),

              /// ===== INPUT PPN =====
              _input(
                "PPN (%)",
                taxCtrl,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Batal",
                        style: TextStyle(color: Colors.grey),
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
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);

                        setState(() => _isSaving = true);

                        try {
                          /// UPDATE PROFILE + RECEIPT
                          await ref
                              .read(profileViewModelProvider.notifier)
                              .updateProfile({
                            "name": nameCtrl.text,
                            "address": addressCtrl.text,
                            "phone": phoneCtrl.text,
                            "receipt_template": receiptCtrl.text, // ✅ BARU
                          });

                          /// UPDATE PPN
                          await ref
                              .read(profileViewModelProvider.notifier)
                              .updateTaxPercentage(
                                double.tryParse(taxCtrl.text) ?? 0,
                              );

                          /// REFRESH
                          await ref
                              .read(profileViewModelProvider.notifier)
                              .fetchProfile();

                          tax = await ref
                              .read(profileViewModelProvider.notifier)
                              .fetchTaxPercentage();

                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.green,
                              content:
                                  Text("✅ Profil toko berhasil disimpan"),
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.red,
                              content:
                                  Text("❌ Gagal menyimpan data: $e"),
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


Widget _input(
  String label,
  TextEditingController controller, {
  TextInputType keyboardType = TextInputType.text,
  int maxLines = 1, // ✅ TAMBAHAN
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines, // ✅ DIPAKAI DI SINI
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade700),
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
