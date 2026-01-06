// plan_model.dart

class PlanModel {
  final bool success;
  final String message;
  final DateTime timestamp;
  final PlanData data;

  PlanModel({
    required this.success,
    required this.message,
    required this.timestamp,
    required this.data,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      data: PlanData.fromJson(json['data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'data': data.toJson(),
    };
  }
}

class PlanData {
  final String plan;
  final String status;
  final DateTime startDate;
  final DateTime endDate;

  PlanData({
    required this.plan,
    required this.status,
    required this.startDate,
    required this.endDate,
  });

  factory PlanData.fromJson(Map<String, dynamic> json) {
    return PlanData(
      plan: json['plan'] ?? '',
      status: json['status'] ?? '',
      startDate: DateTime.parse(json['start_date'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['end_date'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plan': plan,
      'status': status,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
    };
  }
}
