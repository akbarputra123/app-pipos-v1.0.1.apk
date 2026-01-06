import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../models/laporan_model.dart';
import '../../../../viewmodels/laporan_viewmodel.dart';

class ExportProdukBar extends ConsumerWidget {
  const ExportProdukBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productReport =
        ref.watch(laporanViewModelProvider).productReport;

    final enabled = productReport != null;

    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _exportButton(
            enabled: enabled,
            icon: Icons.picture_as_pdf,
            text: "PDF",
            color: const Color(0xFF8B1E1E),
            onPressed: () async {
              final bytes =
                  await _generatePdf(productReport!);
              await _saveFile(bytes, 'laporan_produk.pdf');
              _toast(context, "PDF laporan produk disimpan");
            },
          ),
          const SizedBox(width: 6),
          _exportButton(
            enabled: enabled,
            icon: Icons.table_chart,
            text: "Excel",
            color: const Color(0xFF1F6E43),
            onPressed: () async {
              final bytes =
                  _generateExcel(productReport!);
              await _saveFile(bytes, 'laporan_produk.xlsx');
              _toast(context, "Excel laporan produk disimpan");
            },
          ),
        ],
      ),
    );
  }

  // ================= BUTTON =================
  Widget _exportButton({
    required bool enabled,
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 32,
      child: ElevatedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 14),
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }

  // ================= PDF =================
  Future<Uint8List> _generatePdf(
      ReportProduct report) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'LAPORAN PRODUK',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),

              _pdfRow(
                  "Total Produk", report.totalProducts),
              _pdfRow("Total Terjual", report.totalSold),
              _pdfRow("Stok Habis", report.stokHabis),

              pw.SizedBox(height: 20),

              pw.Text(
                "Produk Terlaris",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),

              pw.Table.fromTextArray(
                headers: const [
                  "Nama Produk",
                  "SKU",
                  "Terjual",
                  "Pendapatan"
                ],
                data: report.topProducts.map((p) {
                  return [
                    p.name,
                    p.sku,
                    p.sold.toString(),
                    p.revenue.toString(),
                  ];
                }).toList(),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfRow(String label, dynamic value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text(value.toString()),
        ],
      ),
    );
  }

  // ================= EXCEL =================
  Uint8List _generateExcel(ReportProduct report) {
    final excel = Excel.createExcel();

    /// ===== SUMMARY SHEET =====
    final summarySheet = excel['Summary'];
    summarySheet.appendRow(['Field', 'Value']);
    summarySheet.appendRow(
        ['Total Produk', report.totalProducts]);
    summarySheet.appendRow(
        ['Total Terjual', report.totalSold]);
    summarySheet.appendRow(
        ['Stok Habis', report.stokHabis]);

    /// ===== TOP PRODUCTS =====
    final productSheet = excel['Produk Terlaris'];
    productSheet.appendRow(
        ['Nama', 'SKU', 'Terjual', 'Pendapatan']);

    for (final p in report.topProducts) {
      productSheet.appendRow([
        p.name,
        p.sku,
        p.sold,
        p.revenue,
      ]);
    }

    return Uint8List.fromList(excel.encode()!);
  }

  // ================= SAVE FILE =================
  Future<void> _saveFile(
      Uint8List bytes, String filename) async {
    if (Platform.isAndroid) {
      final status =
          await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        throw "Izin penyimpanan ditolak";
      }
    }

    Directory dir =
        Directory('/storage/emulated/0/Download');
    if (!await dir.exists()) {
      dir = await getApplicationDocumentsDirectory();
    }

    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Text("✅ $msg"),
      ),
    );
  }
}
