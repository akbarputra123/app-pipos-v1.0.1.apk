// =======================================================
// VIEWMODEL BACKUP DATA (RIVERPOD)
// =======================================================

import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/backup_data_service.dart';

/// =======================================================
/// STATE
/// =======================================================
class BackupDataState {
  final bool isLoading;
  final Uint8List? fileBytes;
  final String? errorMessage;

  const BackupDataState({
    this.isLoading = false,
    this.fileBytes,
    this.errorMessage,
  });

  BackupDataState copyWith({
    bool? isLoading,
    Uint8List? fileBytes,
    String? errorMessage,
  }) {
    return BackupDataState(
      isLoading: isLoading ?? this.isLoading,
      fileBytes: fileBytes,
      errorMessage: errorMessage,
    );
  }
}

/// =======================================================
/// VIEWMODEL
/// =======================================================
class BackupDataViewModel extends StateNotifier<BackupDataState> {
  final BackupDataService _service;

  BackupDataViewModel(this._service) : super(const BackupDataState());

  /// =======================================================
  /// EXPORT DATA (SINGLE / MULTI -> ZIP)
  /// =======================================================
  Future<void> exportData({
    required List<String> dataList, // 🔥 FIX: LIST
    required String type,
    String? startDate,
    String? endDate,
  }) async {
    try {
      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
        fileBytes: null,
      );

      final Uint8List bytes = await _service.exportData(
        dataList: dataList, // 🔥 kirim list ke backend
        type: type,
        startDate: startDate,
        endDate: endDate,
      );

      state = state.copyWith(
        isLoading: false,
        fileBytes: bytes,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// =======================================================
  /// RESET STATE (SETELAH DOWNLOAD)
  /// =======================================================
  void clear() {
    state = const BackupDataState();
  }
}

/// =======================================================
/// PROVIDERS
/// =======================================================
final backupDataServiceProvider = Provider<BackupDataService>((ref) {
  return BackupDataService();
});

final backupDataViewModelProvider =
    StateNotifierProvider<BackupDataViewModel, BackupDataState>((ref) {
  final service = ref.read(backupDataServiceProvider);
  return BackupDataViewModel(service);
});
