import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/log_model.dart';
import '../services/log_service.dart';

/// ===============================
/// STATE
/// ===============================
class LogState {
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  final List<LogItem> items;
  final int page;
  final int limit;
  final int total;
  final int pages;

  const LogState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.items = const [],
    this.page = 1,
    this.limit = 10,
    this.total = 0,
    this.pages = 0,
  });

  LogState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    List<LogItem>? items,
    int? page,
    int? limit,
    int? total,
    int? pages,
  }) {
    return LogState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      items: items ?? this.items,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      pages: pages ?? this.pages,
    );
  }
}

/// ===============================
/// VIEWMODEL
/// ===============================
class LogViewModel extends StateNotifier<LogState> {
  LogViewModel(this._service) : super(const LogState()) {
    log('🟢 LogViewModel initialized');
  }

  final LogService _service;

  /// ===============================
  /// FETCH FIRST PAGE
  /// ===============================
  Future<void> fetchLogs({int limit = 10}) async {
    const source = 'fetchLogs';
    log('━━━━━━━━━━━━━━━━━━━━━━━━');
    log('🧠 VM START : $source');

    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
        page: 1,
        limit: limit,
        items: [],
      );

      final response = await _service.getActivityLogs(
        page: 1,
        limit: limit,
      );

      if (response == null) {
        throw Exception('Response null');
      }

      state = state.copyWith(
        isLoading: false,
        items: response.data.items,
        total: response.data.total,
        page: response.data.page,
        limit: response.data.limit,
        pages: response.data.pages,
      );

      log(
        '✅ VM SUCCESS : total=${response.data.total}, '
        'items=${response.data.items.length}',
      );
    } catch (e) {
      log('❌ VM ERROR : $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    } finally {
      log('🟢 VM DONE : $source');
      log('━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }

  /// ===============================
  /// LOAD MORE (PAGINATION)
  /// ===============================
  Future<void> loadMore() async {
    if (state.isLoadingMore) return;
    if (state.page >= state.pages) {
      log('ℹ️ No more pages');
      return;
    }

    const source = 'loadMoreLogs';
    log('━━━━━━━━━━━━━━━━━━━━━━━━');
    log('🧠 VM START : $source');

    try {
      state = state.copyWith(isLoadingMore: true, error: null);

      final nextPage = state.page + 1;

      final response = await _service.getActivityLogs(
        page: nextPage,
        limit: state.limit,
      );

      if (response == null) {
        throw Exception('Response null');
      }

      state = state.copyWith(
        isLoadingMore: false,
        page: response.data.page,
        items: [
          ...state.items,
          ...response.data.items,
        ],
      );

      log(
        '✅ VM LOAD MORE : page=${response.data.page}, '
        'totalItems=${state.items.length}',
      );
    } catch (e) {
      log('❌ VM LOAD MORE ERROR : $e');
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    } finally {
      log('🟢 VM DONE : $source');
      log('━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }

  /// ===============================
  /// REFRESH
  /// ===============================
  Future<void> refresh() async {
    log('🔄 VM REFRESH');
    await fetchLogs(limit: state.limit);
  }

  /// ===============================
  /// CLEAR ERROR
  /// ===============================
  void clearError() {
    log('🧹 VM clearError');
    state = state.copyWith(error: null);
  }
}

/// ===============================
/// PROVIDER
/// ===============================
final logServiceProvider = Provider<LogService>((ref) {
  log('🔌 LogService provider created');
  return LogService();
});

final logViewModelProvider =
    StateNotifierProvider<LogViewModel, LogState>((ref) {
  log('📦 LogViewModel provider created');
  return LogViewModel(ref.read(logServiceProvider));
});
