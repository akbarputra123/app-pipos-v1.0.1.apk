import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../../models/produk_model.dart';
import 'usb_printer.dart';
import 'tes_page.dart'; // pastikan ini ada

class CetakBarcodePage extends StatefulWidget {
  final ProdukModel produk;
  const CetakBarcodePage({Key? key, required this.produk}) : super(key: key);

  @override
  State<CetakBarcodePage> createState() => _CetakBarcodePageState();
}

class _CetakBarcodePageState extends State<CetakBarcodePage> {
  late TextEditingController barcodeController;
  List<String> usbDevices = [];
  String? selectedDevice;
  bool isLoadingUsb = true;

  @override
  void initState() {
    super.initState();

    barcodeController = TextEditingController(
      text:
          widget.produk.barcode ??
          widget.produk.sku ??
          widget.produk.id.toString(),
    );

    initUsb();
  }

  Future<void> initUsb() async {
    setState(() => isLoadingUsb = true);

    print("[LOG] Meminta izin USB...");
    final granted = await UsbPrinter.requestUsbPermission();
    print("[LOG] Izin USB diberikan: $granted");

    print("[LOG] Mendapatkan daftar USB devices...");
    usbDevices = await UsbPrinter.getUsbDevices();
    print("[LOG] Devices terdeteksi: $usbDevices");

    if (usbDevices.isNotEmpty) {
      selectedDevice = usbDevices.first;
      print("[LOG] Printer default dipilih: $selectedDevice");
    } else {
      print("[LOG] Tidak ada printer USB terdeteksi");
    }

    setState(() => isLoadingUsb = false);
  }

  Future<void> printBarcode() async {
    if (selectedDevice == null) {
      print("[LOG] Tidak ada printer yang dipilih, batal print");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Tidak ada printer yang dipilih, batal print"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final String productName = widget.produk.name ?? 'PRODUK';
    final String barcode = barcodeController.text;
    final String device = selectedDevice!;

    print("[LOG] Mencetak barcode...");
    print("[LOG] Nama produk: $productName");
    print("[LOG] Barcode: $barcode");
    print("[LOG] Device: $device");

    final bool success = await UsbPrinter.printBarcodeWithName(
      name: productName,
      barcode: barcode,
      deviceName: device,
    );

    print("[LOG] Hasil print: $success");

    // Log lengkap untuk SnackBar
    final String snackMessage =
        """
${success ? '✅ Barcode berhasil dicetak' : '❌ Gagal mencetak barcode'}
Nama Produk : $productName
Barcode     : $barcode
Printer     : $device
Hasil       : ${success ? 'Berhasil' : 'Gagal'}
""";

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Text(snackMessage),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cetak Barcode USB')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: barcodeController,
              decoration: const InputDecoration(
                labelText: 'Barcode',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white, // 🔥 BACKGROUND PUTIH
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black12),
                ),
                child: BarcodeWidget(
                  barcode: Barcode.code128(),
                  data: barcodeController.text,
                  width: 240,
                  height: 90,
                  backgroundColor: Colors.white, // 🔥 DOUBLE SAFETY
                  drawText: true, // tampilkan angka barcode
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Text(
              'USB Printer',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (isLoadingUsb)
              const Center(child: CircularProgressIndicator())
            else if (usbDevices.isEmpty)
              const Text(
                "Tidak ada printer USB terdeteksi",
                style: TextStyle(color: Colors.red),
              )
            else
              DropdownButtonFormField<String>(
                value: selectedDevice,
                isExpanded: true,
                items: usbDevices
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) {
                  setState(() => selectedDevice = v);
                  print("[LOG] Printer dipilih: $v");
                },
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: printBarcode,
                icon: const Icon(Icons.print),
                label: const Text('Cetak Barcode'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TestPrinterPage()),
                  );
                },
                icon: const Icon(Icons.usb),
                label: const Text('Tes Printer USB'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
