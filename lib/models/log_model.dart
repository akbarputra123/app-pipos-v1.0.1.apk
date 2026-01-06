// lib/models/log_model.dart

class LogResponse {
  final bool success;
  final String message;
  final DateTime timestamp;
  final LogData data;

  LogResponse({
    required this.success,
    required this.message,
    required this.timestamp,
    required this.data,
  });

  factory LogResponse.fromJson(Map<String, dynamic> json) {
    return LogResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      timestamp: DateTime.parse(
        json['timestamp'] ??
            DateTime.now().toIso8601String(),
      ),
      data: LogData.fromJson(json['data'] ?? {}),
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

/// ======================================================
/// DATA PAGINATION
/// ======================================================
class LogData {
  final List<LogItem> items;
  final int total;
  final int page;
  final int limit;
  final int pages;

  LogData({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.pages,
  });

  factory LogData.fromJson(Map<String, dynamic> json) {
    return LogData(
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => LogItem.fromJson(e))
          .toList(),
      total: _toInt(json['total']),
      page: _toInt(json['page']),
      limit: _toInt(json['limit']),
      pages: _toInt(json['pages']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((e) => e.toJson()).toList(),
      'total': total,
      'page': page,
      'limit': limit,
      'pages': pages,
    };
  }
}

/// ======================================================
/// LOG ITEM (SIAP DIPERLUAS)
/// ======================================================
/// NOTE:
/// Saat ini backend kirim `items: []`,
/// jadi field dibuat fleksibel & aman
class LogItem {
  final String? id;
  final String? action;
  final String? description;
  final String? user;
  final DateTime? createdAt;

  LogItem({
    this.id,
    this.action,
    this.description,
    this.user,
    this.createdAt,
  });

  factory LogItem.fromJson(Map<String, dynamic> json) {
  DateTime? parsedDate;

  final rawDate =
      json['created_at'] ??
      json['createdAt'] ??
      json['timestamp'] ??
      json['time'];

  if (rawDate != null) {
    parsedDate = DateTime.tryParse(rawDate.toString())?.toLocal();
  }

  return LogItem(
    id: json['id']?.toString(),
    action: json['action']?.toString(),
    description: json['description']?.toString(),
    user: json['user']?.toString(),
    createdAt: parsedDate,
  );
}


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'description': description,
      'user': user,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

/// ======================================================
/// HELPER PARSER
/// ======================================================
int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
