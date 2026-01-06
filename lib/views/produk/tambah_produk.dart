import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:barcode_widget/barcode_widget.dart' as bw;
import '../../config/theme.dart'; // pastikan path sesuai
import 'produk_scan.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/produk_model.dart';
import '../../viewmodels/kelola_produk_viewmodel.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class TambahProdukScreen extends ConsumerStatefulWidget {
  const TambahProdukScreen({super.key});

  @override
  ConsumerState<TambahProdukScreen> createState() => _TambahProdukScreenState();
}

class _TambahProdukScreenState extends ConsumerState<TambahProdukScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _skuController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _costPriceController = TextEditingController();
  final TextEditingController _sellPriceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _promoPercentController = TextEditingController();
  final TextEditingController _buyQtyController = TextEditingController();
  final TextEditingController _freeQtyController = TextEditingController();

  String? _promoType;
  File? _pickedImage;
  String? _selectedCategory;

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.primaryDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.cardSoft),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      labelStyle: const TextStyle(color: AppColors.textPrimary),
    );
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

  Card _buildCard({required Widget child}) {
    return Card(
      color: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary, width: 1.5),
          image: _pickedImage != null
              ? DecorationImage(
                  image: FileImage(_pickedImage!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _pickedImage == null
            ? const Icon(Icons.image, color: AppColors.textPrimary, size: 36)
            : null,
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedImage = File(image.path);
      });
    }
  }
void _saveProduct() async {
  if (_nameController.text.isEmpty || _sellPriceController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Nama dan harga jual wajib diisi")),
    );
    return;
  }

  // parsing harga modal dan jual → hapus semua karakter non-digit
  final rawCostPrice =
      _costPriceController.text.replaceAll(RegExp(r'[^0-9]'), '');
  final rawSellPrice =
      _sellPriceController.text.replaceAll(RegExp(r'[^0-9]'), '');

  final produk = ProdukModel(
    id: 0,
    name: _nameController.text,
    sku: _skuController.text,
    barcode: _barcodeController.text,
    costPrice: double.tryParse(rawCostPrice) ?? 0, // <- di sini
    sellPrice: double.tryParse(rawSellPrice) ?? 0,  // <- di sini
    stock: int.tryParse(_stockController.text) ?? 0,
    category: _selectedCategory,
    description: _descriptionController.text,
    imageUrl: _pickedImage?.path,
    promoType: _promoType,
    promoPercent: _promoType == "percentage"
        ? double.tryParse(_promoPercentController.text)
        : 0,
    buyQty: _promoType == "buyxgety"
        ? int.tryParse(_buyQtyController.text)
        : 0,
    freeQty: _promoType == "buyxgety"
        ? int.tryParse(_freeQtyController.text)
        : 0,
    isActive: 1,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final viewModel = ref.read(kelolaProdukViewModelProvider.notifier);

  final success = await viewModel.createProduk(
    produk,
    imageFile: _pickedImage,
  );

  if (success) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Produk berhasil disimpan!"),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context, true);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          viewModel.state.errorMessage ?? "Gagal menyimpan produk",
        ),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text(
          "Tambah Produk",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.cardSoft,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white, size: 26),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: Divider(height: 2, thickness: 2, color: AppColors.primary),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Nama, SKU, Barcode
            _buildCard(
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: _inputDecoration("Nama Produk"),
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _skuController,
                    decoration: _inputDecoration("SKU"),
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _barcodeController,
                          decoration: _inputDecoration("Barcode"),
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final scannedCode = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProdukScanScreen(),
                            ),
                          );
                          if (scannedCode != null) {
                            setState(() {
                              _barcodeController.text = scannedCode;
                            });
                          }
                        },
                        icon: const Icon(
                          Icons.qr_code_scanner,
                          color: AppColors.primary,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          final generatedCode = DateTime.now()
                              .millisecondsSinceEpoch
                              .toString()
                              .substring(0, 12);
                          setState(() {
                            _barcodeController.text = generatedCode;
                          });
                        },
                        icon: const Icon(
                          Icons.auto_fix_high,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_barcodeController.text.isNotEmpty)
                    Container(
                      color: AppColors.textPrimary,
                      padding: const EdgeInsets.all(8),
                      child: bw.BarcodeWidget(
                        barcode: bw.Barcode.code128(),
                        data: _barcodeController.text,
                        width: 200,
                        height: 80,
                        drawText: true,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Harga, Stok, Kategori, Deskripsi
            _buildCard(
              child: Column(
                children: [
                  TextField(
                    controller: _costPriceController,
                    decoration: _inputDecoration("Harga Modal"),
                    style: const TextStyle(color: AppColors.textPrimary),
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        onRupiahChanged(_costPriceController, value),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),

                  const SizedBox(height: 8),
                  TextField(
                    controller: _sellPriceController,
                    decoration: _inputDecoration("Harga Jual"),
                    style: const TextStyle(color: AppColors.textPrimary),
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        onRupiahChanged(_sellPriceController, value),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),

                  const SizedBox(height: 8),
                  TextField(
                    controller: _stockController,
                    decoration: _inputDecoration("Stok"),
                    style: const TextStyle(color: AppColors.textPrimary),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: _inputDecoration("Kategori"),
                    dropdownColor: AppColors.card,
                    style: const TextStyle(color: AppColors.textPrimary),
                    items: const [
                      DropdownMenuItem(
                        value: "Kesehatan & Kecantikan",
                        child: Text("Kesehatan & Kecantikan"),
                      ),
                      DropdownMenuItem(
                        value: "Rumah Tangga & Gaya Hidup",
                        child: Text("Rumah Tangga & Gaya Hidup"),
                      ),
                      DropdownMenuItem(
                        value: "Fashion & Aksesoris",
                        child: Text("Fashion & Aksesoris"),
                      ),
                      DropdownMenuItem(
                        value: "Elektronik",
                        child: Text("Elektronik"),
                      ),
                      DropdownMenuItem(
                        value: "Bayi & Anak",
                        child: Text("Bayi & Anak"),
                      ),
                      DropdownMenuItem(
                        value: "Makanan & Minuman",
                        child: Text("Makanan & Minuman"),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                        _categoryController.text = value ?? '';
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    decoration: _inputDecoration("Deskripsi"),
                    style: const TextStyle(color: AppColors.textPrimary),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Promo
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Promo",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Dropdown PromoType
                  DropdownButtonFormField<String>(
                    value: _promoType,
                    items: const [
                      DropdownMenuItem(
                        value: "percentage", // backend expects "percentage"
                        child: Text("Diskon %"),
                      ),
                      DropdownMenuItem(
                        value: "buyxgety", // ganti dari "buyfree" ke "buyxgety"
                        child: Text("Beli X Gratis Y"),
                      ),
                    ],
                    decoration: _inputDecoration("Jenis Promo"),
                    dropdownColor: AppColors.card,
                    style: const TextStyle(color: AppColors.textPrimary),
                    onChanged: (value) {
                      setState(() {
                        _promoType = value;
                        // Reset inputan ketika ganti tipe promo
                        _promoPercentController.clear();
                        _buyQtyController.clear();
                        _freeQtyController.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 8),

                  // Tampilkan input sesuai tipe promo
                  if (_promoType == "percentage") ...[
                    TextField(
                      controller: _promoPercentController,
                      decoration: _inputDecoration("Promo %"),
                      style: const TextStyle(color: AppColors.textPrimary),
                      keyboardType: TextInputType.number,
                    ),
                  ] else if (_promoType == "buyxgety") ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _buyQtyController,
                            decoration: _inputDecoration("Buy Qty"),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _freeQtyController,
                            decoration: _inputDecoration("Free Qty"),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Gambar
            _buildCard(
              child: Row(
                children: [
                  _buildImagePicker(),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _pickImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text(
                      "Pilih Gambar",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tombol Simpan
            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: ref.watch(kelolaProdukViewModelProvider).isLoading
                    ? null // disable tombol saat loading
                    : _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: ref.watch(kelolaProdukViewModelProvider).isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: AppColors.textPrimary,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Simpan Produk",
                          style: TextStyle(fontSize: 16, color: Colors.white),
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
