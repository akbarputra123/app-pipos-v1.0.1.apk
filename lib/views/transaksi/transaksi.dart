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
    final state = ref.watch(transaksiViewModelProvider);
    final vm = ref.read(transaksiViewModelProvider.notifier);

    final currency = NumberFormat.currency(
      locale: "id_ID",
      symbol: "Rp ",
      decimalDigits: 0,
    );

    /// 🔍 SEARCH FILTER BY TRANSACTION ID
    final keyword = _searchController.text.toLowerCase();
    final filteredTransactions =
        state.transactions
            ?.where(
              (tx) => (tx.transactionId ?? "").toLowerCase().contains(keyword),
            )
            .toList() ??
        [];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: SizedBox(
        child: Column(
          children: [
            /// SEARCH BAR
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Cari transaksi...",
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),

            /// TOP ACTION BAR
            if (selectedIds.isNotEmpty)
              Container(
                color: Colors.red.shade700,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 15,
                ),
                child: Row(
                  children: [
                    Text(
                      "${selectedIds.length} dari ${filteredTransactions.length} dipilih",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),

                    /// HAPUS TERPILIH
                    TextButton(
                      style: _actionButtonStyle(
                        bg: Colors.white,
                        textColor: Colors.red,
                      ),
                      onPressed: () async {
                        try {
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
                        } catch (e) {
                          _showSnackBar(
                            context,
                            "Gagal menghapus transaksi terpilih",
                            false,
                          );
                        }
                      },
                      child: const Text(
                        "Hapus Terpilih",
                        style: TextStyle(fontSize: 11),
                      ),
                    ),

                    const SizedBox(width: 8),

                    /// HAPUS SEMUA
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

                        try {
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
                        } catch (e) {
                          _showSnackBar(
                            context,
                            "Gagal menghapus semua transaksi",
                            false,
                          );
                        }
                      },
                      child: const Text(
                        "Hapus Semua",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),

                    const SizedBox(width: 8),

                    /// BATAL
                    OutlinedButton(
                      onPressed: () {
                        selectedIds.clear();
                        setState(() {});
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        "Batal",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            /// LIST TRANSAKSI
            Expanded(
              child: state.isLoading
                  ? _buildShimmer()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredTransactions.length,
                      itemBuilder: (context, index) {
                        final tx = filteredTransactions[index];
                        final isSelected = selectedIds.contains(
                          tx.transactionId,
                        );

                        return GestureDetector(
                          onTap: () {
                            // JIKA SEDANG MODE SELECT → toggle checkbox
                            if (selectedIds.isNotEmpty) {
                              setState(() {
                                if (isSelected) {
                                  selectedIds.remove(tx.transactionId);
                                } else {
                                  selectedIds.add(tx.transactionId!);
                                }
                              });
                              return;
                            }

                            // JIKA TIDAK MODE SELECT → BUKA DETAIL
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
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Checkbox
                                Checkbox(
                                  value: isSelected,
                                  activeColor: Colors.blue,
                                  onChanged: (val) {
                                    setState(() {
                                      val == true
                                          ? selectedIds.add(tx.transactionId!)
                                          : selectedIds.remove(
                                              tx.transactionId,
                                            );
                                    });
                                  },
                                ),

                                // ICON RECEIPT
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

                                // INFO TRANSAKSI
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.transactionId ?? "-",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat(
                                          'dd/MM/yyyy, HH.mm.ss',
                                        ).format(DateTime.parse(tx.createdAt!)),
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: const [
                                          Icon(
                                            Icons.payments,
                                            size: 14,
                                            color: Colors.white54,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            "cash",
                                            style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // TOTAL + ITEM + HAPUS
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
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
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // ICON HAPUS
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.redAccent,
                                            size: 20,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () async {
                                            final confirm = await _confirmDialog(
                                              context,
                                              "Hapus transaksi ${tx.transactionId}?",
                                            );
                                            if (!confirm) return;

                                            try {
                                              await vm.deleteTransaction(
                                                tx.transactionId!,
                                              );
                                              selectedIds.remove(
                                                tx.transactionId,
                                              );
                                              vm.getTransactions();

                                              _showSnackBar(
                                                context,
                                                "Transaksi berhasil dihapus",
                                                true,
                                              );
                                              setState(() {});
                                            } catch (e) {
                                              _showSnackBar(
                                                context,
                                                "Gagal menghapus transaksi",
                                                false,
                                              );
                                            }
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
      ),
    );
  }

  /// BUTTON STYLE
  ButtonStyle _actionButtonStyle({
    required Color bg,
    required Color textColor,
  }) {
    return TextButton.styleFrom(
      backgroundColor: bg,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      foregroundColor: textColor,
    );
  }

  /// SHIMMER
  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: AppColors.card,
        highlightColor: Colors.white24,
        child: Container(
          height: 80,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDialog(BuildContext context, String text) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: AppColors.card,
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
                  const Text(
                    "Konfirmasi",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Batal
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        child: const Text(
                          "Batal",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),

                      // Hapus
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        child: const Text(
                          "Hapus",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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

  /// SNACKBAR (HIJAU & MERAH)
  void _showSnackBar(BuildContext context, String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
