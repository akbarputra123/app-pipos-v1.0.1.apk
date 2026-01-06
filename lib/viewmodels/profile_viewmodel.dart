import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/store_profile_model.dart';
import '../services/store_profile_service.dart';

/// ============================
/// STATE STORE PROFILE
/// ============================
class ProfileState {
  final bool isLoading;
  final StoreProfile? store;
  final String? error;

  ProfileState({
    this.isLoading = false,
    this.store,
    this.error,
  });

  ProfileState copyWith({
    bool? isLoading,
    StoreProfile? store,
    String? error,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      store: store ?? this.store,
      error: error ?? this.error,
    );
  }
}

/// ============================
/// STORE PROFILE VIEWMODEL
/// ============================
class ProfileViewModel extends StateNotifier<ProfileState> {
  ProfileViewModel() : super(ProfileState());

  /// ============================
  /// GET STORE PROFILE
  /// ============================
  Future<void> fetchProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final store = await ProfileService.getStoreProfile();
      if (store != null) {
        state = state.copyWith(
          isLoading: false,
          store: store,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: "Profil toko tidak ditemukan",
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: "Terjadi kesalahan: $e",
      );
    }
  }

  /// ============================
  /// GET TAX / PPN
  /// ============================
  Future<double> fetchTaxPercentage() async {
    try {
      return await ProfileService.getTaxPercentage();
    } catch (e) {
      print("🔥 fetchTaxPercentage error: $e");
      return 0.0;
    }
  }

  /// ============================
  /// UPDATE STORE PROFILE
  /// ============================
  Future<void> updateProfile(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedStore = await ProfileService.updateProfile(data);
      if (updatedStore != null) {
        state = state.copyWith(
          isLoading: false,
          store: updatedStore,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: "Gagal memperbarui profil toko",
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: "Terjadi kesalahan: $e",
      );
    }
  }

  /// ============================
  /// UPDATE TAX / PPN
  /// ============================
  Future<bool> updateTaxPercentage(double tax) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final success = await ProfileService.updateTaxPercentage(tax);

      if (success) {
        await fetchProfile(); // refresh store
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: "Gagal memperbarui PPN",
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: "Terjadi kesalahan saat update PPN",
      );
      return false;
    }
  }

  /// ============================
  /// DELETE STORE PROFILE
  /// ============================
  Future<void> deleteProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await ProfileService.deleteProfile();
      if (success) {
        state = state.copyWith(
          isLoading: false,
          store: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: "Gagal menghapus profil toko",
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: "Terjadi kesalahan: $e",
      );
    }
  }
}

/// ============================
/// PROVIDER
/// ============================
final profileViewModelProvider =
    StateNotifierProvider<ProfileViewModel, ProfileState>(
  (ref) => ProfileViewModel(),
);
