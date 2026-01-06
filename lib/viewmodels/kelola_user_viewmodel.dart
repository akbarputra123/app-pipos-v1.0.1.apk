import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kelola_user.dart';
import '../services/kelola_user_service.dart';

/// =====================
/// STATE
/// =====================
class KelolaUserState {
  final bool isLoading;
  final List<KelolaUser> users;
  final String? errorMessage;

  KelolaUserState({
    this.isLoading = false,
    this.users = const [],
    this.errorMessage,
  });

  KelolaUserState copyWith({
    bool? isLoading,
    List<KelolaUser>? users,
    String? errorMessage,
  }) {
    return KelolaUserState(
      isLoading: isLoading ?? this.isLoading,
      users: users ?? this.users,
      errorMessage: errorMessage,
    );
  }
}

/// =====================
/// VIEWMODEL
/// =====================
class KelolaUserViewModel extends StateNotifier<KelolaUserState> {
  KelolaUserViewModel() : super(KelolaUserState());

  bool _hasFetched = false;

  /// reset state
  void reset() {
    _hasFetched = false;
    state = KelolaUserState();
  }

  /// fetch users
  Future<void> getUsers({bool force = false}) async {
    // kalau sudah pernah fetch dan tidak paksa, skip
    if (_hasFetched && !force) return;

    _hasFetched = true;
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final data = await KelolaUserService.getUsers();
      state = state.copyWith(isLoading: false, users: data);
    } catch (e) {
      _hasFetched = false; // penting biar bisa coba lagi
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// =====================
  /// CREATE
  /// =====================
  Future<bool> createUser(KelolaUser user) async {
    try {
      final success = await KelolaUserService.createUser(user);
      if (success) {
        await getUsers(force: true);
      }
      return success;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  /// =====================
  /// UPDATE
  /// =====================
  Future<bool> updateUser(KelolaUser user) async {
    try {
      final success = await KelolaUserService.updateUser(user);
      if (success) {
        await getUsers(force: true);
      }
      return success;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  /// =====================
  /// DELETE
  /// =====================
 Future<bool> deleteUser(int userId) async {
  try {
    final success = await KelolaUserService.deleteUser(userId);
    print('Delete user $userId success: $success'); // debug
    if (success) {
      await getUsers(force: true);
    }
    return success;
  } catch (e) {
    print('Delete user error: $e'); // debug
    state = state.copyWith(errorMessage: e.toString());
    return false;
  }
}

}

/// =====================
/// PROVIDER
/// =====================
final kelolaUserViewModelProvider =
    StateNotifierProvider<KelolaUserViewModel, KelolaUserState>(
        (ref) => KelolaUserViewModel());
