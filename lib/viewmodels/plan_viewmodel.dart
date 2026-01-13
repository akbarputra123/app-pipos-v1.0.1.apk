// plan_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/plan_model.dart';
import '../services/plan_service.dart';
import '../services/auth_service.dart';
class PlanNotifier extends StateNotifier<AsyncValue<PlanModel?>> {
  final PlanService _planService;
  PlanNotifier(this._planService)
      : super(const AsyncValue.loading());
  Future<void> fetchPlan({String? token}) async {
    try {
      state = const AsyncValue.loading();
      final usedToken = token ?? await AuthService.getToken();
      if (usedToken == null || usedToken.isEmpty) {
        state = const AsyncValue.data(null);
        return;
      }
      final plan = await _planService.fetchPlan(token: usedToken);
      state = AsyncValue.data(plan);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
final planServiceProvider = Provider<PlanService>((ref) {
  return PlanService();
});
final planNotifierProvider =
    StateNotifierProvider<PlanNotifier, AsyncValue<PlanModel?>>((ref) {
  final service = ref.read(planServiceProvider);
  return PlanNotifier(service);
});