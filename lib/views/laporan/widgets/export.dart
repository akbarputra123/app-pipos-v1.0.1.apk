import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../models/laporan_model.dart';

import '../../../viewmodels/laporan_viewmodel.dart';

class ExportReportBar extends ConsumerWidget {
  const ExportReportBar({super.key});

  String _formatRupiah(num value) {
  final str = value.toStringAsFixed(0);
  final buffer = StringBuffer();
  int count = 0;

  for (int i = str.length - 1; i >= 0; i--) {
    buffer.write(str[i]);
    count++;
    if (count % 3 == 0 && i != 0) {
      buffer.write('.');
    }
  }

  return 'Rp ${buffer.toString().split('').reversed.join()}';
}


String _formatDate(DateTime date) {
  return "${date.day.toString().padLeft(2, '0')}-"
         "${date.month.toString().padLeft(2, '0')}-"
         "${date.year} "
         "${date.hour.toString().padLeft(2, '0')}:"
         "${date.minute.toString().padLeft(2, '0')}";
}


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(laporanViewModelProvider).summary;

    // Kalau data belum ada → tombol tetap tampil tapi disable
    final enabled = summary != null;

    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _exportButton(
            context: context,
            enabled: enabled,
            icon: Icons.picture_as_pdf,
            text: "PDF",
            color: const Color(0xFF8B1E1E),
            onPressed: () async {
              final bytes = await _generatePdf(summary!);
              await _saveFile(bytes, 'laporan_summary.pdf');
              _toast(context, "PDF berhasil disimpan");
            },
          ),
          const SizedBox(width: 6),
          _exportButton(
            context: context,
            enabled: enabled,
            icon: Icons.table_chart,
            text: "Excel",
            color: const Color(0xFF1F6E43),
            onPressed: () async {
              final bytes = _generateExcel(summary!);
              await _saveFile(bytes, 'laporan_summary.xlsx');
              _toast(context, "Excel berhasil disimpan");
            },
          ),
        ],
      ),
    );
  }

  // ================= BUTTON =================
  Widget _exportButton({
    required BuildContext context,
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

Future<Uint8List> _generatePdf(ReportSummary summary) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            /// ================= HEADER =================
            pw.Text(
              'LAPORAN KEUANGAN',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Ringkasan Performa Keuangan',
              style: pw.TextStyle(
                fontSize: 11,
                color: PdfColors.grey700,
              ),
            ),

            pw.SizedBox(height: 12),
            pw.Divider(),

            pw.SizedBox(height: 16),

            /// ================= TABLE =================
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColors.grey400,
                width: 0.8,
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(3),
                1: pw.FlexColumnWidth(2),
              },
              children: [
                _tableHeader("Keterangan", "Nilai"),

                _tableRow(
                  "Total Transaksi",
                  summary.totalTransaksi.toString(),
                ),
                _tableRow(
                  "Pendapatan",
                  _formatRupiah(summary.totalPendapatan),
                ),
                _tableRow(
                  "Diskon",
                  _formatRupiah(summary.totalDiskon),
                ),
                _tableRow(
                  "Net Revenue",
                  _formatRupiah(summary.netRevenue),
                ),
                _tableRow(
                  "Total HPP",
                  _formatRupiah(summary.totalHpp),
                ),
                _tableRow(
                  "Gross Profit",
                  _formatRupiah(summary.grossProfit),
                ),
                _tableRow(
                  "Operational Cost",
                  _formatRupiah(summary.operationalCost),
                ),
                _tableRow(
                  "Net Profit",
                  _formatRupiah(summary.netProfit),
                ),
                _tableRow(
                  "Margin",
                  summary.margin,
                ),
              ],
            ),

            pw.Spacer(),

            /// ================= FOOTER =================
            pw.Divider(),
            pw.SizedBox(height: 6),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                "Generated by POS System • ${_formatDate(DateTime.now())}",
                style: pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}


  // ================= EXCEL =================
  Uint8List _generateExcel(ReportSummary summary) {
    final excel = Excel.createExcel();
    final sheet = excel['Summary'];

    sheet.appendRow(['Field', 'Value']);
    sheet.appendRow(['Total Transaksi', summary.totalTransaksi]);
    sheet.appendRow(['Pendapatan', summary.totalPendapatan]);
    sheet.appendRow(['Diskon', summary.totalDiskon]);
    sheet.appendRow(['Net Revenue', summary.netRevenue]);
    sheet.appendRow(['Gross Profit', summary.grossProfit]);
    sheet.appendRow(['Net Profit', summary.netProfit]);
    sheet.appendRow(['Margin', summary.margin]);

    return Uint8List.fromList(excel.encode()!);
  }

  // ================= SAVE FILE =================
  Future<void> _saveFile(Uint8List bytes, String filename) async {
    if (Platform.isAndroid) {
      final status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        throw "Izin penyimpanan ditolak";
      }
    }

    Directory dir = Directory('/storage/emulated/0/Download');
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

  pw.Widget _summaryBox({
  required String title,
  required List<pw.Widget> rows,
}) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey400),
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 13,
          ),
        ),
        pw.SizedBox(height: 8),
        ...rows,
      ],
    ),
  );
}
pw.TableRow _tableHeader(String col1, String col2) {
  return pw.TableRow(
    decoration: const pw.BoxDecoration(
      color: PdfColors.grey300,
    ),
    children: [
      pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(
          col1,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(
          col2,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.right,
        ),
      ),
    ],
  );
}

pw.TableRow _tableRow(String label, String value) {
  return pw.TableRow(
    children: [
      pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(label),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(
          value,
          textAlign: pw.TextAlign.right,
        ),
      ),
    ],
  );
}


}
