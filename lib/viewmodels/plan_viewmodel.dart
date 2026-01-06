// plan_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/plan_model.dart';
import '../services/plan_service.dart';
import '../services/auth_service.dart';

/// StateNotifier untuk meng-handle state PlanModel
class PlanNotifier extends StateNotifier<AsyncValue<PlanModel?>> {
  final PlanService _planService;

  PlanNotifier(this._planService) : super(const AsyncValue.loading()) {
    fetchPlan(); // otomatis fetch saat init
  }

  /// Fetch plan dari API, pakai token dari AuthService jika tidak diberikan
  Future<void> fetchPlan({String? token}) async {
    try {
      state = const AsyncValue.loading();
      final usedToken = token ?? await AuthService.getToken();
      final plan = await _planService.fetchPlan(token: usedToken);
      if (plan != null) {
        state = AsyncValue.data(plan);
      } else {
        state = AsyncValue.error('Failed to load plan', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Provider untuk PlanService
final planServiceProvider = Provider<PlanService>((ref) {
  return PlanService();
});

/// Provider untuk PlanNotifier
final planNotifierProvider =
    StateNotifierProvider<PlanNotifier, AsyncValue<PlanModel?>>((ref) {
  final service = ref.read(planServiceProvider);
  return PlanNotifier(service);
});
