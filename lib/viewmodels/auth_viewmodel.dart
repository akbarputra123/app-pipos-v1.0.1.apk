import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'plan_viewmodel.dart';
class AuthState {
  final bool isLoading;
  final AuthResponse? authResponse;
  final User? userData;
  final int? activeStoreId; 
  final String? errorMessage;
  AuthState({
    this.isLoading = false,
    this.authResponse,
    this.userData,
    this.activeStoreId,
    this.errorMessage,
  });
  AuthState copyWith({
    bool? isLoading,
    AuthResponse? authResponse,
    User? userData,
    int? activeStoreId,
    bool clearAuthResponse = false,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      authResponse:
          clearAuthResponse ? null : authResponse ?? this.authResponse,
      userData: userData ?? this.userData,
      activeStoreId: activeStoreId ?? this.activeStoreId,
      errorMessage: errorMessage,
    );
  }
}
class AuthViewModel extends StateNotifier<AuthState> {
  final Ref ref;
  AuthViewModel(this.ref) : super(AuthState());
  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      clearAuthResponse: true,
    );
    try {
      final res = await AuthService.login(
        identifier: identifier,
        password: password,
      );
      if (res != null && res.success && res.user != null) {
        final storeId = res.user!.storeId;

        final prefs = await SharedPreferences.getInstance();
        if (storeId != null) {
          await prefs.setInt('store_id', storeId);
        }
        state = state.copyWith(
          isLoading: false,
          authResponse: res,
          userData: res.user,
          activeStoreId: storeId,
        );
        await ref.read(planNotifierProvider.notifier).fetchPlan();
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: res?.message ?? 'Login gagal',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
  Future<void> setActiveStore(int storeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('store_id', storeId);

    state = state.copyWith(activeStoreId: storeId);
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    final user = User(
      id: prefs.getInt('user_id') ?? 0,
      ownerId: prefs.getInt('owner_id') ?? 0,
      storeId: prefs.getInt('store_id'),
      role: prefs.getString('role') ?? 'user',
      username: prefs.getString('username') ?? '',
      email: prefs.getString('email') ?? '',
      dbName: prefs.getString('db_name') ?? '',
      plan: prefs.getString('plan') ?? '',
      name: prefs.getString('name'),
    );
    state = state.copyWith(
      userData: user,
      activeStoreId: prefs.getInt('store_id'),
    );
    await ref.read(planNotifierProvider.notifier).fetchPlan();
  }
  Future<void> logout() async {
    try {
      await AuthService.logoutApi(); // 🔥 logout pakai token
    } catch (e) {
      print("❌ Logout API error: $e");
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    ref.invalidate(planNotifierProvider);

    state = AuthState();
  }

  bool get isLoggedIn => state.userData != null;
  bool get hasActiveStore => state.activeStoreId != null;
}

final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AuthState>(
  (ref) => AuthViewModel(ref),
);
