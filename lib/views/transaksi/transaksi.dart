import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../viewmodels/transaksi_viewmodel.dart';
import '../../config/theme.dart';
import 'detail_transaksi.dart';

class TransaksiScreen extends ConsumerStatefulWidget {
  const TransaksiScreen({super.key});

  @override
  ConsumerState<TransaksiScreen> createState() => _TransaksiScreenState();
}

class _TransaksiScreenState extends ConsumerState<TransaksiScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> selectedIds = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(transaksiViewModelProvider.notifier).getTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(transaksiViewModelProvider);
    final vm = ref.read(transaksiViewModelProvider.notifier);

    final currency = NumberFormat.currency(
      locale: "id_ID",
      symbol: "Rp ",
      decimalDigits: 0,
    );

    final keyword = _searchController.text.toLowerCase();
    final filteredTransactions =
        state.transactions
            ?.where(
              (tx) =>
                  (tx.transactionId ?? "").toLowerCase().contains(keyword),
            )
            .toList() ??
        [];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          /// SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: theme.textTheme.bodyMedium,
              cursorColor: theme.colorScheme.primary,
              decoration: InputDecoration(
                hintText: "Cari transaksi...",
                hintStyle:
                    theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                prefixIcon:
                    Icon(Icons.search, color: theme.iconTheme.color),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close,
                            color: theme.iconTheme.color),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          /// TOP ACTION BAR (TIDAK DIUBAH)
          if (selectedIds.isNotEmpty)
            Container(
              color: Colors.red.shade700,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
              child: Row(
                children: [
                  Text(
                    "${selectedIds.length} dari ${filteredTransactions.length} dipilih",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),

                  TextButton(
                    style: _actionButtonStyle(
                      bg: Colors.white,
                      textColor: Colors.red,
                    ),
                    onPressed: () async {
                      for (final id in selectedIds) {
                        await vm.deleteTransaction(id);
                      }
                      selectedIds.clear();
                      vm.getTransactions();
                      _showSnackBar(
                        context,
                        "Transaksi terpilih berhasil dihapus",
                        true,
                      );
                      setState(() {});
                    },
                    child: const Text("Hapus Terpilih",
                        style: TextStyle(fontSize: 10)),
                  ),

                  const SizedBox(width: 8),

                  TextButton(
                    style: _actionButtonStyle(
                      bg: Colors.white,
                      textColor: Colors.red,
                    ),
                    onPressed: () async {
                      final confirm = await _confirmDialog(
                        context,
                        "Hapus SEMUA transaksi?",
                      );
                      if (!confirm) return;

                      for (final tx in filteredTransactions) {
                        await vm.deleteTransaction(tx.transactionId!);
                      }
                      selectedIds.clear();
                      vm.getTransactions();
                      _showSnackBar(
                        context,
                        "Semua transaksi berhasil dihapus",
                        true,
                      );
                      setState(() {});
                    },
                    child: const Text("Hapus Semua",
                        style: TextStyle(fontSize: 10)),
                  ),

                  const SizedBox(width: 8),

                  OutlinedButton(
                    onPressed: () {
                      selectedIds.clear();
                      setState(() {});
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                    ),
                    child: const Text(
                      "Batal",
                      style:
                          TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          /// LIST TRANSAKSI
          Expanded(
            child: state.isLoading
                ? _buildShimmer(theme)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final tx = filteredTransactions[index];
                      final isSelected =
                          selectedIds.contains(tx.transactionId);

                      return GestureDetector(
                        onTap: () {
                          if (selectedIds.isNotEmpty) {
                            setState(() {
                              isSelected
                                  ? selectedIds.remove(tx.transactionId)
                                  : selectedIds.add(tx.transactionId!);
                            });
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DetailTransaksiPage(transaksi: tx),
                            ),
                          );
                        },
                        onLongPress: () {
                          setState(() {
                            selectedIds.add(tx.transactionId!);
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.primary.withOpacity(0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isSelected,
                                activeColor: AppColors.primary,
                                onChanged: (val) {
                                  setState(() {
                                    val == true
                                        ? selectedIds
                                            .add(tx.transactionId!)
                                        : selectedIds
                                            .remove(tx.transactionId);
                                  });
                                },
                              ),

                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.receipt_long,
                                  color: Colors.redAccent,
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.transactionId ?? "-",
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                              fontWeight:
                                                  FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat(
                                              'dd/MM/yyyy, HH.mm.ss')
                                          .format(DateTime.parse(
                                              tx.createdAt!)),
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.payments,
                                            size: 14,
                                            color:
                                                theme.iconTheme.color),
                                        const SizedBox(width: 4),
                                        Text("cash",
                                            style:
                                                theme.textTheme.bodySmall),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    currency.format(tx.total ?? 0),
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Text(
                                        "${tx.items.length} item",
                                        style:
                                            theme.textTheme.bodySmall,
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.redAccent,
                                          size: 20,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints:
                                            const BoxConstraints(),
                                        onPressed: () async {
                                          final confirm =
                                              await _confirmDialog(
                                            context,
                                            "Hapus transaksi ${tx.transactionId}?",
                                          );
                                          if (!confirm) return;

                                          await vm.deleteTransaction(
                                              tx.transactionId!);
                                          selectedIds.remove(
                                              tx.transactionId);
                                          vm.getTransactions();
                                          _showSnackBar(
                                            context,
                                            "Transaksi berhasil dihapus",
                                            true,
                                          );
                                          setState(() {});
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _actionButtonStyle({
    required Color bg,
    required Color textColor,
  }) {
    return TextButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: textColor,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    );
  }

  Widget _buildShimmer(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: theme.cardColor,
        highlightColor: theme.dividerColor.withOpacity(0.3),
        child: Container(
          height: 80,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDialog(BuildContext context, String text) async {
  final theme = Theme.of(context);

  return await showDialog<bool>(
        context: context,
        barrierDismissible: false, // ⬅️ WAJIB (tidak bisa tap luar)
        builder: (_) => Dialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.redAccent,
                  size: 40,
                ),
                const SizedBox(height: 12),

                Text(
                  "Konfirmasi",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    /// BATAL
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: theme.dividerColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          "Batal",
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    /// HAPUS
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          "Hapus",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ) ??
      false;
}


  void _showSnackBar(
      BuildContext context, String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
