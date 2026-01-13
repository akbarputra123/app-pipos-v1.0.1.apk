import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../viewmodels/backup_data_viewmodel.dart';

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
    final theme = Theme.of(context);

    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: theme, // ✅ ikut theme aktif
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        isStart ? startDate = date : endDate = date;
      });
    }
  }

  /// ================= MAP DATA =================
  List<String> _mapSelectedDataList() {
    const map = {
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
    final theme = Theme.of(context);
    final state = ref.watch(backupDataViewModelProvider);

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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.iconTheme.color),
        title: Text(
          'Export Data',
          style: theme.textTheme.titleMedium,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// ================= HEADER =================
          Column(
            children: [
              Icon(Icons.cloud_upload,
                  color: theme.colorScheme.primary, size: 56),
              const SizedBox(height: 12),
              Text(
                'Export Data',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pilih data yang ingin diekspor dan format file',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          _stepTitle('1', 'Pilih Data'),

          _dataCard(0, Icons.people, 'Data Karyawan',
              'Export seluruh data karyawan'),
          _dataCard(
              1, Icons.inventory, 'Data Produk', 'Export katalog produk'),
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
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : const Icon(Icons.cloud_upload),
            label: const Text('Export / Backup Data'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
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

  /// ================= DATA CARD =================
  Widget _dataCard(
      int index, IconData icon, String title, String subtitle) {
    final theme = Theme.of(context);
    final checked = selectedIndexes.contains(index);
    final expanded = expandedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: checked
            ? theme.colorScheme.primary.withOpacity(0.12)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              checked ? theme.colorScheme.primary : theme.dividerColor,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 12),
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () =>
                      setState(() => expandedIndex = expanded ? -1 : index),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(subtitle,
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
              Checkbox(
                value: checked,
                activeColor: theme.colorScheme.primary,
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
            Divider(color: theme.dividerColor),
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
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            Text(value, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _formatCard(String title, String value) {
    final theme = Theme.of(context);
    final selected = selectedFormat == value;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => selectedFormat = value),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withOpacity(0.15)
                : theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.dividerColor,
            ),
          ),
          child: Column(
            children: [
              Icon(Icons.insert_drive_file,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.iconTheme.color),
              const SizedBox(height: 8),
              Text(title, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepTitle(String number, String title) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: theme.colorScheme.primary,
            child: Text(number,
                style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Text(title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              )),
        ],
      ),
    );
  }

  /// ================= SAVE FILE =================
  Future<void> _onFileReady(Uint8List bytes) async {
    try {
      if (Platform.isAndroid) {
        final status =
            await Permission.manageExternalStorage.request();
        if (!status.isGranted) throw "Izin storage ditolak";
      }

      final now = DateTime.now();
      final filename =
          'backup_${now.millisecondsSinceEpoch}.$selectedFormat';

      final dir = Directory('/storage/emulated/0/Download');
      final path =
          (await dir.exists()) ? dir.path : (await getExternalStorageDirectory())!.path;

      final file = File('$path/$filename');
      await file.writeAsBytes(bytes, flush: true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup tersimpan: $filename')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}
