import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';


// =====================
// STATE LOGIN
// =====================
class AuthState {
  final bool isLoading;
  final AuthResponse? authResponse;
  final User? userData; // ⬅️ tambahan
  final String? errorMessage;

  AuthState({
    this.isLoading = false,
    this.authResponse,
    this.userData,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    AuthResponse? authResponse,
    User? userData,
    bool clearAuthResponse = false,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      authResponse:
          clearAuthResponse ? null : authResponse ?? this.authResponse,
      userData: userData ?? this.userData,
      errorMessage: errorMessage,
    );
  }
}

// =====================
// VIEWMODEL
// =====================
class AuthViewModel extends StateNotifier<AuthState> {
  AuthViewModel() : super(AuthState());

  /// =====================
  /// LOGIN
  /// =====================
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

      if (res != null && res.success == true) {
        state = state.copyWith(
          isLoading: false,
          authResponse: res,
          userData: res.user, // langsung simpan user
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          clearAuthResponse: true,
          errorMessage: res?.message ?? 'Login gagal',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        clearAuthResponse: true,
        errorMessage: e.toString(),
      );
    }
  }

  /// =====================
  /// LOGOUT
  /// =====================
  Future<void> logout() async {
    await AuthService.logout();
    state = AuthState(); // reset semua state
  }

  /// =====================
  /// LOAD USER DARI SharedPreferences
  /// =====================
  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    final username = prefs.getString('username') ?? 'Unknown';
    final email = prefs.getString('email') ?? 'unknown@email.com';
    final userId = prefs.getInt('user_id') ?? 0;
    final ownerId = prefs.getInt('owner_id') ?? 0;
    final storeId = prefs.getInt('store_id');
    final role = prefs.getString('role') ?? 'user';
    final dbName = prefs.getString('db_name') ?? '';
    final plan = prefs.getString('plan') ?? '';
    final name = prefs.getString('name');

    final user = User(
      id: userId,
      ownerId: ownerId,
      storeId: storeId,
      role: role,
      username: username,
      email: email,
      dbName: dbName,
      plan: plan,
      name: name,
    );

    state = state.copyWith(userData: user);
  }
}

// =====================
// PROVIDER
// =====================
final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AuthState>((ref) => AuthViewModel());
