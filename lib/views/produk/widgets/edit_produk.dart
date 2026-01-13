import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:barcode_widget/barcode_widget.dart' as bw;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/base_url.dart';
import '../../../config/theme.dart';
import '../../../models/produk_model.dart';
import '../../../viewmodels/kelola_produk_viewmodel.dart';
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
  late TextEditingController _bundleQtyController;
  late TextEditingController _bundleTotalPriceController;

  // ← TARUH DI SINI
  double parseRupiah(String value) {
    return double.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
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

    _costPriceController = TextEditingController(
      text: formatRupiah.format(p.costPrice),
    );
    _sellPriceController = TextEditingController(
      text: formatRupiah.format(p.sellPrice),
    );

    _stockController = TextEditingController(text: p.stock.toString());
    _descriptionController = TextEditingController(text: p.description ?? "");

    _promoType = p.promoType; // null / percentage / buyxgety

    _promoPercentController = TextEditingController(
      text: _promoType == 'percentage' ? p.promoPercent?.toString() ?? '' : '',
    );

    _buyQtyController = TextEditingController(
      text: _promoType == 'buyxgety' ? p.buyQty?.toString() ?? '' : '',
    );

    _freeQtyController = TextEditingController(
      text: _promoType == 'buyxgety' ? p.freeQty?.toString() ?? '' : '',
    );

    _selectedCategory = p.category;
    _bundleQtyController = TextEditingController(
      text: _promoType == 'bundle'
          ? widget.produk.bundleQty?.toString() ?? ''
          : '',
    );

    _bundleTotalPriceController = TextEditingController(
      text: _promoType == 'bundle'
          ? formatRupiah.format(widget.produk.bundleTotalPrice ?? 0)
          : '',
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

  /// =====================
  /// DECORATION (SAMA DENGAN TAMBAH PRODUK)
  /// =====================
  /// =====================
  /// DECORATION (DARK / LIGHT READY)
  /// =====================
  InputDecoration _inputDecoration(
    BuildContext context,
    String label, {
    bool disabled = false,
  }) {
    final theme = Theme.of(context);

    return InputDecoration(
      labelText: label,
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: theme.textTheme.bodyMedium?.color,
      ),
      filled: true,
      fillColor: disabled
          ? theme.disabledColor.withOpacity(0.08)
          : theme.cardColor, // ✅ ikut dark/light
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: theme.dividerColor, // ✅ adaptif
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.primary, // 🔥 brand tetap
          width: 2,
        ),
      ),
    );
  }

  Card _buildCard(Widget child) {
    final theme = Theme.of(context);
    return Card(
      color: theme.cardColor, // ✅ ikut dark / light
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }

  /// =====================
  /// IMAGE PICKER
  /// =====================
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    final XFile? img = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, // ⬅️ opsional: kompres biar ringan
    );

    if (!mounted) return; // ⬅️ cegah error kalau widget sudah dispose

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
      costPrice: parseRupiah(_costPriceController.text),
      sellPrice: parseRupiah(_sellPriceController.text),
      stock: int.tryParse(_stockController.text) ?? 0,
      category: _selectedCategory,
      description: _descriptionController.text,

      promoType: _promoType,

      promoPercent: _promoType == 'percentage'
          ? double.tryParse(_promoPercentController.text)
          : null,

      buyQty: _promoType == 'buyxgety'
          ? int.tryParse(_buyQtyController.text)
          : null,

      freeQty: _promoType == 'buyxgety'
          ? int.tryParse(_freeQtyController.text)
          : null,

      // 🔥 BUNDLE
      bundleQty: _promoType == 'bundle'
          ? int.tryParse(_bundleQtyController.text)
          : null,

      bundleTotalPrice: _promoType == 'bundle'
          ? parseRupiah(_bundleTotalPriceController.text)
          : null,

      clearPromo: _promoType == null,
      updatedAt: DateTime.now(),
    );

    final vm = ref.read(kelolaProdukViewModelProvider.notifier);
    final success = await vm.updateProduk(
      widget.produk.id,
      updatedProduk,
      imageFile: _pickedImage,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Produk berhasil diperbarui"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.state.errorMessage ?? "Gagal update produk"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(kelolaProdukViewModelProvider).isLoading;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: Text(
          "Edit Produk",
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
        child: Column(
          children: [
            /// NAMA, SKU, BARCODE
            _buildCard(
              Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: _inputDecoration(context, "Nama Produk"),
                    style: Theme.of(context).textTheme.bodyMedium,
                    cursorColor: Theme.of(context).colorScheme.primary,
                  ),

                  const SizedBox(height: 8),
                  TextField(
                    controller: _skuController,
                    decoration: _inputDecoration(context, "SKU"),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),

                  /// BARCODE (READ ONLY)
                  TextField(
                    controller: _barcodeController,
                    enabled: false,
                    decoration: _inputDecoration(
                      context,
                      "Barcode",
                      disabled: true,
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
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
                ],
              ),
            ),

            const SizedBox(height: 12),

            /// ================= PROMO =================
            _buildCard(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String?>(
                    value: _promoType,
                    decoration: _inputDecoration(context, "Jenis Promo"),
                    style: Theme.of(context).textTheme.bodyMedium,
                    dropdownColor: Theme.of(context).cardColor,

                    items: const [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text("Tanpa Diskon"),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'percentage',
                        child: Text("Diskon (%)"),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'buyxgety',
                        child: Text("Beli X Gratis Y"),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'bundle',
                        child: Text("Harga Bundle"),
                      ),
                    ],

                    onChanged: (value) {
                      setState(() {
                        _promoType = value;

                        _promoPercentController.clear();
                        _buyQtyController.clear();
                        _freeQtyController.clear();
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  /// ===== DISKON PERSEN =====
                  if (_promoType == 'percentage')
                    TextField(
                      controller: _promoPercentController,
                      decoration: _inputDecoration(context, "Promo (%)"),
                      style: Theme.of(context).textTheme.bodyMedium,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                    ),

                  /// ===== BUY X GET Y =====
                  if (_promoType == 'buyxgety')
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _buyQtyController,
                            decoration: _inputDecoration(context, "Buy Qty"),
                            style: Theme.of(context).textTheme.bodyMedium,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _freeQtyController,
                            decoration: _inputDecoration(context, "Free Qty"),
                            style: Theme.of(context).textTheme.bodyMedium,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                      ],
                    ),

                  /// ===== BUNDLE =====
                  if (_promoType == 'bundle')
                    Column(
                      children: [
                        TextField(
                          controller: _bundleQtyController,
                          decoration: _inputDecoration(
                            context,
                            "Jumlah per Bundle",
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _bundleTotalPriceController,
                          decoration: _inputDecoration(context, "Harga Bundle")
                              .copyWith(
                                prefixText: 'Rp ',
                                prefixStyle: Theme.of(
                                  context,
                                ).textTheme.bodyMedium,
                              ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) => onRupiahChanged(
                            _bundleTotalPriceController,
                            value,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
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
                        color: Theme.of(context).textTheme.bodyMedium?.color,

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
            SafeArea(
              top: false, // ❗ hanya lindungi bagian bawah
              child: Padding(
                padding: const EdgeInsets.only(
                  bottom: 8,
                ), // jarak dari nav sistem
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : _updateProduk,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(
                        52,
                      ), // ⬅️ tinggi nyaman
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Update Produk",
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
          ],
        ),
      ),
    );
  }
}
