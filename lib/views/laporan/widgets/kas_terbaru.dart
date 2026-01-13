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

    Future.microtask(() {
      if (_hasFetched) return;
      ref.read(transaksiViewModelProvider.notifier).getTransactions();
      _hasFetched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(transaksiViewModelProvider);
    final transactions = state.transactions ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor, // ✅ theme aware
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ===== HEADER =====
          Row(
            children: [
              Icon(
                Icons.circle,
                color: theme.colorScheme.primary,
                size: 10,
              ),
              const SizedBox(width: 8),
              Text(
                'Kas Masuk Terbaru',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(color: theme.dividerColor),
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
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            )

          /// ===== EMPTY =====
          else if (transactions.isEmpty)
            Text(
              'Belum ada transaksi',
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    theme.textTheme.bodySmall?.color?.withOpacity(0.5),
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
    final theme = Theme.of(context);

    return Row(
      children: [
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
    final theme = Theme.of(context);

    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
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
    final theme = Theme.of(context);

    return Column(
      children: [
        Divider(color: theme.dividerColor),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                tanggal,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color:
                      theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                keterangan,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    jumlah,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
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
