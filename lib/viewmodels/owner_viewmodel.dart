import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/owner_profile_model.dart';
import '../services/owner_profile_service.dart';

/// ============================
/// STATE OWNER PROFILE
/// ============================
class OwnerState {
  final bool isLoading;
  final OwnerProfile? owner;
  final String? error;

  OwnerState({
    this.isLoading = false,
    this.owner,
    this.error,
  });

 OwnerState copyWith({
  bool? isLoading,
  OwnerProfile? owner,
  String? error,
}) {
  return OwnerState(
    isLoading: isLoading ?? this.isLoading,
    owner: owner,
    error: error,
  );
}

}

/// ============================
/// OWNER VIEWMODEL
/// ============================
class OwnerViewModel extends StateNotifier<OwnerState> {
  OwnerViewModel() : super(OwnerState());

  /// ============================
  /// GET OWNER PROFILE
  /// ============================
  Future<void> fetchOwnerProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final owner = await OwnerProfileService.getOwnerProfile();

      if (owner != null) {
        state = state.copyWith(
          isLoading: false,
          owner: owner,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: "Profil owner tidak ditemukan",
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: "Terjadi kesalahan: $e",
      );
    }
  }

Future<bool> updateOwnerProfile(Map<String, dynamic> data) async {
  state = state.copyWith(isLoading: true, error: null);

  try {
    // 1️⃣ UPDATE (anggap sukses jika tidak throw)
    await OwnerProfileService.updateOwnerProfile(data);

    // 2️⃣ FETCH ULANG DATA
    final owner = await OwnerProfileService.getOwnerProfile();

    if (owner != null) {
      state = state.copyWith(
        isLoading: false,
        owner: owner,
        error: null,
      );
      return true;
    }

    // fetch gagal
    state = state.copyWith(
      isLoading: false,
      error: "Gagal memuat data owner terbaru",
    );
    return false;
  } catch (e) {
    state = state.copyWith(
      isLoading: false,
      error: "Terjadi kesalahan: $e",
    );
    return false;
  }
}


  /// ============================
  /// RESET (OPSIONAL)
  /// ============================
  void reset() {
    state = OwnerState();
  }
}

/// ============================
/// PROVIDER
/// ============================
final ownerViewModelProvider =
    StateNotifierProvider<OwnerViewModel, OwnerState>(
  (ref) => OwnerViewModel(),
);
