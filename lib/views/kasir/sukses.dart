import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:bluetooth_classic/bluetooth_classic.dart';
import 'package:bluetooth_classic/models/device.dart';

import '../../models/transaksi_model.dart';
import '../../models/store_profile_model.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../config/theme.dart';
import '../../models/produk_model.dart';
import '../../viewmodels/kelola_produk_viewmodel.dart';
import '../../viewmodels/transaksi_viewmodel.dart';
import '../produk/usb_printer.dart'; // ✅ USB PRINTER
import '../../services/auth_service.dart';

class SuksesScreen extends ConsumerStatefulWidget {
  final TransaksiModel transaksi;

  const SuksesScreen({super.key, required this.transaksi});

  @override
  ConsumerState<SuksesScreen> createState() => _SuksesScreenState();
}

class _SuksesScreenState extends ConsumerState<SuksesScreen> {
  final BluetoothClassic _bluetooth = BluetoothClassic();
  List<Device> devices = [];
  Device? selectedDevice;

  // ================= USB STATE (TAMBAHAN SAJA) =================
  bool _usbAvailable = false;
  String? _usbDeviceName;
 String? _cashierUsername;



  @override
void initState() {
  super.initState();
  _initBluetooth();
  _initUsbPrinter();

 Future.microtask(() async {
  _cashierUsername = await AuthService.getCashierUsername();
  if (mounted) setState(() {});
});


  WidgetsBinding.instance.addPostFrameCallback((_) {
    final profileVM = ref.read(profileViewModelProvider.notifier);
    if (profileVM.state.store == null) {
      profileVM.fetchProfile();
    }
  });
}


  // ================= USB INIT =================
  Future<void> _initUsbPrinter() async {
    try {
      final devices = await UsbPrinter.getUsbDevices();
      if (devices.isNotEmpty) {
        setState(() {
          _usbAvailable = true;
          _usbDeviceName = devices.first;
        });
      }
    } catch (_) {}
  }

  // ================= BLUETOOTH INIT =================
  Future<void> _initBluetooth() async {
    try {
      await _bluetooth.initPermissions();
      final paired = await _bluetooth.getPairedDevices();
      setState(() => devices = paired);
    } catch (e) {
      debugPrint("Bluetooth init error: $e");
    }
  }


  // ================= STRUK (FIX – SNAPSHOT TRANSAKSI) =================
String _generateStruk(
  StoreProfile profile,
  TransaksiModel transaksi,
) {
  final currency = NumberFormat.currency(
    locale: "id_ID",
    symbol: "Rp ",
    decimalDigits: 0,
  );

  DateTime transaksiDate;
  try {
    transaksiDate = transaksi.createdAt != null &&
            transaksi.createdAt!.contains('T')
        ? DateTime.parse(transaksi.createdAt!).toLocal()
        : DateTime.now().toLocal();
  } catch (_) {
    transaksiDate = DateTime.now().toLocal();
  }

  /// ================= UTIL PROMO =================
  bool _isBuyXGetY(TransaksiItemModel item) {
    return item.discountType
            ?.toLowerCase()
            .replaceAll('_', '') ==
        'buyxgety';
  }

  int _hitungTotalItem(TransaksiItemModel item) {
    final price = item.price;
    final qty = item.quantity;

    // ===== DISKON PERSENTASE =====
    if (item.discountType == 'percentage' &&
        item.discountValue != null &&
        item.discountValue! > 0) {
      final finalPrice =
          price - (price * item.discountValue! / 100);
      return (finalPrice * qty).round();
    }

    // ===== BUY X GET Y =====
    if (_isBuyXGetY(item)) {
      int buy = 0;
      int free = 0;

      // notes format: "2+2"
      if (item.notes != null && item.notes!.contains('+')) {
        final parts = item.notes!.split('+');
        buy = int.tryParse(parts[0]) ?? 0;
        free = int.tryParse(parts[1]) ?? 0;
      } else if (item.discountValue != null) {
        // fallback: Buy X Get X
        buy = item.discountValue!.toInt();
        free = buy;
      }

      if (buy > 0 && free > 0) {
        final group = buy + free;
        final paidQty =
            (qty ~/ group) * buy + (qty % group);
        return (paidQty * price).round();
      }
    }

    // ===== NORMAL =====
    return (price * qty).round();
  }

  final buffer = StringBuffer();

  buffer.writeln(profile.name);
  buffer.writeln(profile.address);
  buffer.writeln(profile.phone);
  buffer.writeln('--------------------------------');
  buffer.writeln('STRUK PEMBAYARAN');
  buffer.writeln('No      : ${transaksi.transactionId}');
  buffer.writeln(
    'Tgl     : ${DateFormat('dd MMM yyyy HH:mm:ss', 'id_ID').format(transaksiDate)}',
  );
  buffer.writeln(
      'Kasir   : ${transaksi.cashier ?? _cashierUsername ?? 'ADMIN'}');
  buffer.writeln('Metode  : ${transaksi.paymentMethod}');
  buffer.writeln('--------------------------------');
  buffer.writeln('ITEM PEMBELIAN');

  for (final item in transaksi.items) {
    buffer.writeln(item.name);

    String promoLabel = '';

    // ===== DISKON % =====
    if (item.discountType == 'percentage' &&
        item.discountValue != null &&
        item.discountValue! > 0) {
      promoLabel =
          ' (Diskon ${item.discountValue!.toStringAsFixed(0)}%)';
    }

    // ===== BUY X GET Y =====
    if (_isBuyXGetY(item)) {
      if (item.notes != null && item.notes!.contains('+')) {
        promoLabel =
            ' (Buy${item.notes!.replaceAll('+', '-Get')})';
      } else if (item.discountValue != null) {
        promoLabel =
            ' (Buy${item.discountValue!.toInt()}-Get${item.discountValue!.toInt()})';
      }
    }

    buffer.writeln(
      '${item.quantity} x ${currency.format(item.price)}$promoLabel',
    );

    buffer.writeln(
      currency.format(_hitungTotalItem(item)),
    );
  }

  buffer.writeln('--------------------------------');
  buffer.writeln('Subtotal : ${currency.format(transaksi.subtotal)}');
  buffer.writeln(
    'PPN (${transaksi.taxPercent?.toStringAsFixed(1) ?? '0'}%) : ${currency.format(transaksi.taxAmount)}',
  );
  buffer.writeln('TOTAL    : ${currency.format(transaksi.total)}');
  buffer.writeln('');
  buffer.writeln(
    'Tunai     : ${currency.format(transaksi.receivedAmount)}',
  );
  buffer.writeln(
    'Kembalian : ${currency.format(transaksi.change)}',
  );
  buffer.writeln('--------------------------------');
  buffer.writeln(profile.receiptTemplate);

  return buffer.toString();
}

Future<void> _printBluetooth(StoreProfile profile) async {
  if (selectedDevice == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Pilih printer Bluetooth terlebih dahulu"),
      ),
    );
    return;
  }

  try {
    const uuid = "00001101-0000-1000-8000-00805f9b34fb";

    // ================= CONNECT =================
    await _bluetooth.connect(selectedDevice!.address, uuid);

    // 🔥 PAKAI SNAPSHOT TRANSAKSI (BUKAN CART)
    final message =
        _generateStruk(profile, widget.transaksi) + "\n\n\n";

    // ================= KIRIM DATA PER BLOK =================
    const blockSize = 256;
    for (int i = 0; i < message.length; i += blockSize) {
      final end =
          (i + blockSize < message.length) ? i + blockSize : message.length;
      final chunk = message.substring(i, end);

      await _bluetooth.write(chunk);
      await Future.delayed(const Duration(milliseconds: 50));
    }

    // ================= TUNGGU PRINTER =================
    await Future.delayed(const Duration(milliseconds: 300));

    // ================= DISCONNECT =================
    await _bluetooth.disconnect();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Cetak berhasil")),
    );
  } catch (e) {
    debugPrint("Bluetooth print error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Cetak gagal")),
    );
  }
}


// ================= PRINT USB (ESC/POS – STRUK SAJA) =================
Future<void> _printUsb(StoreProfile profile) async {
  if (_usbDeviceName == null) return;

  try {
    // 🔥 PAKAI SNAPSHOT TRANSAKSI (BUKAN CART)
    final struk =
        _generateStruk(profile, widget.transaksi) + "\n\n\n";

    final success = await UsbPrinter.printReceipt(
      text: struk,
      deviceName: _usbDeviceName!,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? "Cetak USB berhasil" : "Cetak USB gagal"),
      ),
    );
  } catch (e) {
    debugPrint("USB print error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Cetak USB gagal")),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileViewModelProvider);
    final products = ref.watch(kelolaProdukViewModelProvider).products;

    if (profileState.isLoading || profileState.store == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

  final profile = profileState.store!;
final struk = _generateStruk(profile, widget.transaksi);


    return Scaffold(
      backgroundColor: AppColors.background.withOpacity(0.9),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            color: AppColors.card,
            margin: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 80,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Transaksi Berhasil!",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.textMuted,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        struk,
                        style: const TextStyle(
                          fontFamily: "Courier",
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      if (devices.isNotEmpty)
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 250),
                          child: DropdownButton<Device>(
                            isExpanded: true,
                            hint: const Text(
                              "Pilih Printer Bluetooth",
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                            dropdownColor: AppColors.card,
                            value: selectedDevice,
                            onChanged: (d) =>
                                setState(() => selectedDevice = d),
                            items: devices
                                .map(
                                  (d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(
                                      "${d.name} (${d.address})",
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),

                      if (devices.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: () => _printBluetooth(profile),
                          icon: const Icon(Icons.print),
                          label: const Text("Cetak Bluetooth"),
                        ),
                      if (_usbAvailable)
                        ElevatedButton.icon(
                          onPressed: () => _printUsb(profile),
                          icon: const Icon(Icons.usb),
                          label: const Text("Cetak USB"),
                        ),
                      ElevatedButton.icon(
                        onPressed: () => Share.share(struk),
                        icon: const Icon(Icons.share),
                        label: const Text("Share"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          ref
                              .read(kelolaProdukViewModelProvider.notifier)
                              .clearCart();
                          ref.read(transaksiViewModelProvider.notifier).reset();
                          Navigator.of(context).popUntil((r) => r.isFirst);
                        },
                        child: const Text("Tutup"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
