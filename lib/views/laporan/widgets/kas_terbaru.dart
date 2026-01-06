import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../viewmodels/transaksi_viewmodel.dart';

/// ======================================================
/// KAS TERBARU (SUMBER: TRANSAKSI)
/// ======================================================
class KasTerbaru extends ConsumerStatefulWidget {
  const KasTerbaru({super.key});

  @override
  ConsumerState<KasTerbaru> createState() => _KasTerbaruState();
}

class _KasTerbaruState extends ConsumerState<KasTerbaru> {
  bool _hasFetched = false;

  @override
  void initState() {
    super.initState();

    /// 🔥 FETCH SEKALI SAAT WIDGET MUNCUL
    Future.microtask(() {
      if (_hasFetched) return;
      log('🚀 KasTerbaru → getTransactions()');
      ref.read(transaksiViewModelProvider.notifier).getTransactions();
      _hasFetched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transaksiViewModelProvider);
    final transactions = state.transactions ?? [];

    log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    log('🔁 KasTerbaru BUILD');
    log('⏳ isLoading : ${state.isLoading}');
    log('📦 transaksi: ${transactions.length}');
    log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ===== HEADER =====
          Row(
            children: const [
              Icon(Icons.circle, color: Colors.redAccent, size: 10),
              SizedBox(width: 8),
              Text(
                'Kas Masuk Terbaru',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: Colors.white10),
          const SizedBox(height: 10),

          /// ===== LOADING =====
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )

          /// ===== ERROR =====
          else if (state.errorMessage != null)
            Text(
              state.errorMessage!,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
              ),
            )

          /// ===== EMPTY =====
          else if (transactions.isEmpty)
            const Text(
              'Belum ada transaksi',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 12,
              ),
            )

          /// ===== DATA =====
          else ...[
            const _TableHeader(),
            const SizedBox(height: 6),

            ...transactions.take(5).map((trx) {
              return _KasRow(
                tanggal: _formatDate(trx.createdAt),
                keterangan:
                    'Transaksi (${trx.paymentMethod.toUpperCase()})',
                jumlah: _rupiah(trx.total ?? 0),
              );
            }),
          ],
        ],
      ),
    );
  }
}

/// ======================================================
/// TABLE HEADER
/// ======================================================
class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          flex: 2,
          child: _HeaderText('TANGGAL'),
        ),
        Expanded(
          flex: 3,
          child: _HeaderText('KETERANGAN'),
        ),
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.centerRight,
            child: _HeaderText('JUMLAH'),
          ),
        ),
      ],
    );
  }
}

class _HeaderText extends StatelessWidget {
  final String text;
  const _HeaderText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// ======================================================
/// TABLE ROW
/// ======================================================
class _KasRow extends StatelessWidget {
  final String tanggal;
  final String keterangan;
  final String jumlah;

  const _KasRow({
    required this.tanggal,
    required this.keterangan,
    required this.jumlah,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(color: Colors.white10),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                tanggal,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                keterangan,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F3D2B),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    jumlah,
                    style: const TextStyle(
                      color: Color(0xFF4ADE80),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// ======================================================
/// FORMATTER
/// ======================================================
String _formatDate(String? iso) {
  if (iso == null || iso.isEmpty) return '-';
  try {
    final d = DateTime.parse(iso);
    return DateFormat('dd MMM yyyy', 'id_ID').format(d);
  } catch (e) {
    log('❌ Date parse error: $iso');
    return iso;
  }
}

String _rupiah(double value) {
  return NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(value);
}
