import 'package:flutter/material.dart';
import 'usb_printer.dart';

class TestPrinterPage extends StatefulWidget {
  const TestPrinterPage({Key? key}) : super(key: key);

  @override
  State<TestPrinterPage> createState() => _TestPrinterPageState();
}

class _TestPrinterPageState extends State<TestPrinterPage> {
  List<String> usbDevices = [];
  String? selectedDevice;
  bool isLoadingUsb = true;
  TextEditingController testTextController = TextEditingController(text: "TES PRINTER\n1234567890");

  @override
  void initState() {
    super.initState();
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

  Future<void> testPrint() async {
    if (selectedDevice == null) {
      print("[LOG] Tidak ada printer yang dipilih, batal print");
      return;
    }

    final testText = testTextController.text;
    print("[LOG] Mencetak teks uji...");
    print("[LOG] Device: $selectedDevice");
    print("[LOG] Teks: $testText");

    // Kita pakai printBarcodeWithName untuk uji, nama = testText, barcode dummy
    final success = await UsbPrinter.printBarcodeWithName(
      name: testText, 
      barcode: "1234567890", 
      deviceName: selectedDevice!,
    );

    print("[LOG] Hasil print: $success");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? '✅ Teks uji berhasil dicetak'
            : '❌ Gagal mencetak teks uji'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Test Printer USB")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: testTextController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Teks uji",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('USB Printer',
                style: TextStyle(fontWeight: FontWeight.bold)),
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
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: testPrint,
                icon: const Icon(Icons.print),
                label: const Text('Cetak Teks Uji'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
