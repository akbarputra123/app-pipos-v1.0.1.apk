import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:barcode_widget/barcode_widget.dart' as bw;
import '../../../config/theme.dart'; // pastikan path sesuai
import 'produk_scan.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/produk_model.dart';
import '../../../viewmodels/kelola_produk_viewmodel.dart';
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
  final TextEditingController _bundleQtyController = TextEditingController();
  final TextEditingController _bundleTotalPriceController =
      TextEditingController();

  String? _promoType;
  File? _pickedImage;
  String? _selectedCategory;

  InputDecoration _inputDecoration(BuildContext context, String label) {
    final theme = Theme.of(context);

    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: theme.cardColor, // ✅ ikut dark / light
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.primaryDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      labelStyle: theme.textTheme.bodyMedium,
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
    final theme = Theme.of(context);
    return Card(
      color: theme.cardColor, // ✅ ikut dark / light
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }

  Widget _buildImagePicker() {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: theme.cardColor, // ✅ ikut dark/light
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
    final rawCostPrice = _costPriceController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final rawSellPrice = _sellPriceController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    final produk = ProdukModel(
  id: 0,
  name: _nameController.text,
  sku: _skuController.text,
  barcode: _barcodeController.text,
  costPrice: double.tryParse(rawCostPrice) ?? 0,
  sellPrice: double.tryParse(rawSellPrice) ?? 0,
  stock: int.tryParse(_stockController.text) ?? 0,
  category: _selectedCategory,
  description: _descriptionController.text,
  imageUrl: _pickedImage?.path,

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

  // 🔥 BUNDLE
  bundleQty: _promoType == "bundle"
      ? int.tryParse(_bundleQtyController.text)
      : null,

  bundleTotalPrice: _promoType == "bundle"
      ? double.tryParse(
          _bundleTotalPriceController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        )
      : null,

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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: Text(
          "Tambah Produk",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.cardColor, // ✅ ikut dark / light
        foregroundColor: theme.textTheme.titleMedium?.color, // teks & icon aman
        elevation: 0,
        iconTheme: IconThemeData(color: theme.iconTheme.color, size: 26),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Divider(
            height: 2,
            thickness: 2,
            color: theme.colorScheme.primary, // aksen tetap
          ),
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
                    decoration: _inputDecoration(context, "Nama Produk"),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),

                  const SizedBox(height: 8),
                  TextField(
                    controller: _skuController,
                    decoration: _inputDecoration(context, "SKU"),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _barcodeController,
                          decoration: _inputDecoration(context, "Barcode"),
                          style: Theme.of(context).textTheme.bodyMedium,
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
                    decoration: _inputDecoration(context, "Harga Modal"),
                    style: Theme.of(context).textTheme.bodyMedium,
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        onRupiahChanged(_costPriceController, value),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),

                  const SizedBox(height: 8),
                  TextField(
                    controller: _sellPriceController,
                    decoration: _inputDecoration(context, "Harga Jual"),
                    style: Theme.of(context).textTheme.bodyMedium,
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        onRupiahChanged(_sellPriceController, value),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),

                  const SizedBox(height: 8),
                  TextField(
                    controller: _stockController,
                    decoration: _inputDecoration(context, "Stok"),
                    style: Theme.of(context).textTheme.bodyMedium,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: _inputDecoration(context, "Kategori"),
                    dropdownColor: Theme.of(context).cardColor,

                    style: Theme.of(context).textTheme.bodyMedium,
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
                    decoration: _inputDecoration(context, "Deskripsi"),
                    style: Theme.of(context).textTheme.bodyMedium,
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
                  /// TITLE
                  Text(
                    "Promo",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  /// DROPDOWN PROMO
                  DropdownButtonFormField<String?>(
                    value: _promoType,
                    items: const [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text("Tanpa Promo"),
                      ),
                      DropdownMenuItem<String?>(
                        value: "percentage",
                        child: Text("Diskon %"),
                      ),
                      DropdownMenuItem<String?>(
                        value: "buyxgety",
                        child: Text("Beli X Gratis Y"),
                      ),
                      DropdownMenuItem<String?>(
                        value: "bundle",
                        child: Text("Harga Bundle"),
                      ),
                    ],

                    decoration: _inputDecoration(context, "Jenis Promo"),
                    dropdownColor: Theme.of(context).cardColor,
                    style: Theme.of(context).textTheme.bodyMedium,
                    onChanged: (value) {
                      setState(() {
                        _promoType = value;

                        /// RESET INPUT SAAT GANTI
                        _promoPercentController.clear();
                        _buyQtyController.clear();
                        _freeQtyController.clear();
                      });
                    },
                  ),

                  const SizedBox(height: 8),

                  /// PROMO PERCENTAGE
                  if (_promoType == "percentage") ...[
                    TextField(
                      controller: _promoPercentController,
                      decoration: _inputDecoration(context, "Promo %"),
                      style: Theme.of(context).textTheme.bodyMedium,
                      keyboardType: TextInputType.number,
                    ),
                  ]
                  /// PROMO BUY X GET Y
                  else if (_promoType == "buyxgety") ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _buyQtyController,
                            decoration: _inputDecoration(context, "Buy Qty"),
                            style: Theme.of(context).textTheme.bodyMedium,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _freeQtyController,
                            decoration: _inputDecoration(context, "Free Qty"),
                            style: Theme.of(context).textTheme.bodyMedium,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ]
                  /// ===== PROMO BUNDLE =====
                  else if (_promoType == "bundle") ...[
                    TextField(
                      controller: _bundleQtyController,
                      decoration: _inputDecoration(
                        context,
                        "Jumlah per Bundle",
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _bundleTotalPriceController,
                      decoration: _inputDecoration(
                        context,
                        "Harga Bundle",
                      ).copyWith(prefixText: "Rp "),
                      style: Theme.of(context).textTheme.bodyMedium,
                      keyboardType: TextInputType.number,
                      onChanged: (value) =>
                          onRupiahChanged(_bundleTotalPriceController, value),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.85, // ⬅️ lebar tombol (85% layar)
                    child: ElevatedButton(
                      onPressed:
                          ref.watch(kelolaProdukViewModelProvider).isLoading
                          ? null
                          : _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size.fromHeight(
                          52,
                        ), // ⬅️ tinggi tombol
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: ref.watch(kelolaProdukViewModelProvider).isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Simpan Produk",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
