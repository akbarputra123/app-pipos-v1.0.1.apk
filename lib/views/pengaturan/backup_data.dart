import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../config/theme.dart';
import '../../viewmodels/backup_data_viewmodel.dart';

class BackupDataScreen extends ConsumerStatefulWidget {
  const BackupDataScreen({super.key});

  @override
  ConsumerState<BackupDataScreen> createState() => _BackupDataScreenState();
}

class _BackupDataScreenState extends ConsumerState<BackupDataScreen> {
  final DateFormat _fmt = DateFormat('dd/MM/yyyy');
  final DateFormat _apiFmt = DateFormat('yyyy-MM-dd');

  DateTime? startDate;
  DateTime? endDate;

  final Set<int> selectedIndexes = {};
  int expandedIndex = -1;

  String selectedFormat = 'csv';

  /// ================= PICK DATE =================
  Future<void> _pickDate({required bool isStart}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (_, child) =>
          Theme(data: ThemeData.dark(), child: child!),
    );

    if (date != null) {
      setState(() {
        isStart ? startDate = date : endDate = date;
      });
    }
  }

  /// ================= MAP DATA (LIST) =================
  List<String> _mapSelectedDataList() {
    final map = {
      0: 'karyawan',
      1: 'produk',
      2: 'transaksi',
      3: 'transaction_items',
    };

    return selectedIndexes.map((i) => map[i]!).toList();
  }

  /// ================= EXPORT =================
  Future<void> _export() async {
    await ref.read(backupDataViewModelProvider.notifier).exportData(
      dataList: _mapSelectedDataList(),
      type: selectedFormat,
      startDate: startDate != null ? _apiFmt.format(startDate!) : null,
      endDate: endDate != null ? _apiFmt.format(endDate!) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(backupDataViewModelProvider);

    /// ✅ LISTENER RESMI & AMAN
    ref.listen<BackupDataState>(
      backupDataViewModelProvider,
      (prev, next) {
        if (prev?.fileBytes == null && next.fileBytes != null) {
          _onFileReady(next.fileBytes!);
          ref.read(backupDataViewModelProvider.notifier).clear();
        }

        if (prev?.errorMessage == null && next.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.errorMessage!)),
          );
        }
      },
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('Export Data'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// ================= HEADER =================
          Column(
            children: const [
              Icon(Icons.cloud_upload, color: Colors.red, size: 56),
              SizedBox(height: 12),
              Text(
                'Export Data',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Pilih data yang ingin diekspor dan format file',
                style: TextStyle(color: Colors.white54),
              ),
            ],
          ),

          const SizedBox(height: 24),

          _stepTitle('1', 'Pilih Data'),

          _dataCard(0, Icons.people, 'Data Karyawan',
              'Export seluruh data karyawan'),
          _dataCard(1, Icons.inventory, 'Data Produk',
              'Export katalog produk'),
          _dataCard(2, Icons.receipt_long, 'Data Transaksi',
              'Export riwayat transaksi'),
          _dataCard(3, Icons.list_alt, 'Item Transaksi',
              'Export detail item transaksi'),

          const SizedBox(height: 28),

          _stepTitle('2', 'Format File'),

          Row(
            children: [
              _formatCard('CSV', 'csv'),
              const SizedBox(width: 12),
              _formatCard('JSON', 'json'),
              const SizedBox(width: 12),
              _formatCard('Excel', 'xlsx'),
            ],
          ),

          const SizedBox(height: 32),

          _stepTitle('3', 'Export'),

          ElevatedButton.icon(
            onPressed: selectedIndexes.isEmpty || state.isLoading
                ? null
                : _export,
            icon: state.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.cloud_upload),
            label: const Text('Export / Backup Data'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              disabledBackgroundColor: Colors.red.withOpacity(0.4),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ================= SAVE FILE =================
  Future<void> _onFileReady(Uint8List bytes) async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.manageExternalStorage.request();
        if (status.isDenied || status.isPermanentlyDenied) {
          throw "Izin storage ditolak";
        }
      }

      final now = DateTime.now();
      final isZip = selectedIndexes.length > 1;

      final filename = isZip
          ? 'backup_${now.millisecondsSinceEpoch}.zip'
          : 'backup_${_mapSelectedDataList().first}_${now.millisecondsSinceEpoch}.$selectedFormat';

      Directory downloadsDirectory = Directory('/storage/emulated/0/Download');
      if (!await downloadsDirectory.exists()) {
        downloadsDirectory = (await getExternalStorageDirectory())!;
      }

      final filePath = '${downloadsDirectory.path}/$filename';
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup tersimpan di Download/$filename')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  /// ================= DATA CARD =================
  Widget _dataCard(
      int index, IconData icon, String title, String subtitle) {
    final checked = selectedIndexes.contains(index);
    final expanded = expandedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: checked
            ? Colors.red.withOpacity(0.12)
            : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: checked ? Colors.red : Colors.transparent),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 12),
              Icon(icon, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() {
                    expandedIndex = expanded ? -1 : index;
                  }),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(subtitle,
                            style: const TextStyle(
                                color: Colors.white54)),
                      ],
                    ),
                  ),
                ),
              ),
              Checkbox(
                value: checked,
                activeColor: Colors.red,
                onChanged: (v) {
                  setState(() {
                    v == true
                        ? selectedIndexes.add(index)
                        : selectedIndexes.remove(index);
                  });
                },
              ),
            ],
          ),

          if (expanded && checked) ...[
            const Divider(color: Colors.white24),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: _dateBox(
                      'Tanggal Mulai',
                      startDate != null
                          ? _fmt.format(startDate!)
                          : 'dd/mm/yyyy',
                      () => _pickDate(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dateBox(
                      'Tanggal Akhir',
                      endDate != null
                          ? _fmt.format(endDate!)
                          : 'dd/mm/yyyy',
                      () => _pickDate(isStart: false),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dateBox(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    color: Colors.white, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _formatCard(String title, String value) {
    final selected = selectedFormat == value;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => selectedFormat = value),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: selected
                ? Colors.red.withOpacity(0.15)
                : const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: selected ? Colors.red : Colors.transparent),
          ),
          child: Column(
            children: [
              Icon(Icons.insert_drive_file,
                  color: selected ? Colors.red : Colors.white54),
              const SizedBox(height: 8),
              Text(title,
                  style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepTitle(String number, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.red,
            child: Text(number,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
