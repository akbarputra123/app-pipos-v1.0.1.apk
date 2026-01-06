import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:barcode_widget/barcode_widget.dart' as bw;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/base_url.dart';
import '../../config/theme.dart';
import '../../models/produk_model.dart';
import '../../viewmodels/kelola_produk_viewmodel.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class EditProdukScreen extends ConsumerStatefulWidget {
  final ProdukModel produk;

  const EditProdukScreen({super.key, required this.produk});

  @override
  ConsumerState<EditProdukScreen> createState() => _EditProdukScreenState();
}

class _EditProdukScreenState extends ConsumerState<EditProdukScreen> {
  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _barcodeController;
  late TextEditingController _costPriceController;
  late TextEditingController _sellPriceController;
  late TextEditingController _stockController;
  late TextEditingController _descriptionController;
  late TextEditingController _promoPercentController;
  late TextEditingController _buyQtyController;
  late TextEditingController _freeQtyController;
   // ← TARUH DI SINI
  double parseRupiah(String value) {
    return double.tryParse(
          value.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;
  }


  String? _promoType;
  String? _selectedCategory;
  File? _pickedImage;
@override
void initState() {
  super.initState();
  final p = widget.produk;

  _nameController = TextEditingController(text: p.name);
  _skuController = TextEditingController(text: p.sku ?? "");
  _barcodeController = TextEditingController(text: p.barcode ?? "");

  // 🔥 FIX RUPIAH
  _costPriceController = TextEditingController(
    text: formatRupiah.format(p.costPrice),
  );
  _sellPriceController = TextEditingController(
    text: formatRupiah.format(p.sellPrice),
  );

  _stockController = TextEditingController(text: p.stock.toString());
  _descriptionController = TextEditingController(text: p.description ?? "");

  _promoType = p.promoType;
  _promoPercentController = TextEditingController(
    text: p.promoPercent?.toString() ?? "",
  );
  _buyQtyController = TextEditingController(text: p.buyQty?.toString() ?? "");
  _freeQtyController = TextEditingController(
    text: p.freeQty?.toString() ?? "",
  );

  _selectedCategory = p.category;
}


  final formatRupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: '',
    decimalDigits: 0,
  );

  void onRupiahChanged(TextEditingController controller, String value) {
    String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) digits = '0';

    final number = double.parse(digits);
    final formatted = formatRupiah.format(number);

    controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// =====================
  /// DECORATION (SAMA DENGAN TAMBAH PRODUK)
  /// =====================
  InputDecoration _inputDecoration(String label, {bool disabled = false}) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: AppColors.textPrimary),
    filled: true,
    fillColor: disabled
        ? AppColors.cardSoft.withOpacity(0.5)
        : AppColors.card,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.cardSoft, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.primary, width: 2),
    ),
  );
}


  Card _buildCard(Widget child) {
    return Card(
      color: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }

  /// =====================
  /// IMAGE PICKER
  /// =====================
  Future<void> _pickImage() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() {
        _pickedImage = File(img.path);
      });
    }
  }

  Future<void> _updateProduk() async {
  final updatedProduk = widget.produk.copyWith(
    name: _nameController.text,
    sku: _skuController.text,

    // 🔥 FIX RUPIAH (INI KUNCI)
    costPrice: parseRupiah(_costPriceController.text),
    sellPrice: parseRupiah(_sellPriceController.text),

    stock: int.tryParse(_stockController.text) ?? 0,
    category: _selectedCategory,
    description: _descriptionController.text,
    promoType: _promoType,
    promoPercent: _promoType == "percentage"
        ? double.tryParse(_promoPercentController.text)
        : null,
    buyQty: _promoType == "buyxgety"
        ? int.tryParse(_buyQtyController.text)
        : null,
    freeQty: _promoType == "buyxgety"
        ? int.tryParse(_freeQtyController.text)
        : null,
    updatedAt: DateTime.now(),
  );

  final vm = ref.read(kelolaProdukViewModelProvider.notifier);
  final success = await vm.updateProduk(
    widget.produk.id,
    updatedProduk,
    imageFile: _pickedImage,
  );

if (success) {
  Navigator.pop(context, true);
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Produk berhasil diperbarui"),
      backgroundColor: Colors.green, // hijau untuk sukses
    ),
  );
} else {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(vm.state.errorMessage ?? "Gagal update produk"),
      backgroundColor: Colors.red, // merah untuk gagal
    ),
  );
}

}


  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(kelolaProdukViewModelProvider).isLoading;

    return Scaffold(
   backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text(
          "Edit Produk",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.cardSoft,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white, // warna icon
          size: 26, // ukuran lebih besar → terlihat lebih bold
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(2), // samakan dengan thickness
          child: Divider(height: 2, thickness: 2, color: AppColors.primary),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// NAMA, SKU, BARCODE
            _buildCard(
              Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: _inputDecoration("Nama Produk"),
                    style: const TextStyle(color: Colors.white),
                    cursorColor: Colors.white,
                  ),

                  const SizedBox(height: 8),
                  TextField(
                    controller: _skuController,
                    decoration: _inputDecoration("SKU"),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),

                  /// BARCODE (READ ONLY)
                  TextField(
                    controller: _barcodeController,
                    enabled: false,
                    decoration: _inputDecoration("Barcode", disabled: true),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: bw.BarcodeWidget(
                      barcode: bw.Barcode.code128(),
                      data: _barcodeController.text,
                      height: 80,
                      drawText: true,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            /// HARGA & STOK
            _buildCard(
              Column(
                children: [
                  TextField(
                    controller: _costPriceController,
                    decoration: _inputDecoration("Harga Modal"),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        onRupiahChanged(_costPriceController, value),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),

                  const SizedBox(height: 8),
                  TextField(
                    controller: _sellPriceController,
                    decoration: _inputDecoration("Harga Jual"),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        onRupiahChanged(_sellPriceController, value),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),

                  const SizedBox(height: 8),
                  TextField(
                    controller: _stockController,
                    decoration: _inputDecoration("Stok"),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            /// PROMO
            _buildCard(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: _promoType,
                    decoration: _inputDecoration("Jenis Promo"),
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(
                        value: "percentage",
                        child: Text("Diskon %"),
                      ),
                      DropdownMenuItem(
                        value: "buyxgety",
                        child: Text("Beli X Gratis Y"),
                      ),
                    ],
                    onChanged: (v) => setState(() => _promoType = v),
                  ),
                  const SizedBox(height: 8),
                  if (_promoType == "percentage")
                    TextField(
                      controller: _promoPercentController,
                      decoration: _inputDecoration("Promo %"),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                    ),
                  if (_promoType == "buyxgety")
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _buyQtyController,
                            decoration: _inputDecoration("Buy Qty"),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _freeQtyController,
                            decoration: _inputDecoration("Free Qty"),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            /// GAMBAR
            _buildCard(
              Row(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary),
                        color: AppColors.textPrimary,
                        image: _pickedImage != null
                            ? DecorationImage(
                                image: FileImage(_pickedImage!),
                                fit: BoxFit.cover,
                              )
                            : (widget.produk.imageUrl != null &&
                                  widget.produk.imageUrl!.trim().isNotEmpty)
                            ? DecorationImage(
                                image: NetworkImage(
                                  widget.produk.imageUrl!.startsWith('http')
                                      ? widget.produk.imageUrl!
                                      : "${BaseUrl.api}/${widget.produk.imageUrl}",
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child:
                          _pickedImage == null &&
                              (widget.produk.imageUrl == null ||
                                  widget.produk.imageUrl!.trim().isEmpty)
                          ? const Icon(Icons.image, size: 36)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _pickImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text(
                      "Ganti Gambar",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// BUTTON UPDATE
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : _updateProduk,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Update Produk",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
