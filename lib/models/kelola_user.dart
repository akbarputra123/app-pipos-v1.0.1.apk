class KelolaUserResponse {
  final bool success;
  final List<KelolaUser> data;

  KelolaUserResponse({required this.success, required this.data});

  factory KelolaUserResponse.fromJson(Map<String, dynamic> json) {
    return KelolaUserResponse(
      success: json['success'] ?? false,
      data: json['data'] != null
          ? List<KelolaUser>.from(
              (json['data'] as List).map((x) => KelolaUser.fromJson(x)))
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'data': data.map((x) => x.toJson()).toList(),
      };
}

class KelolaUser {
  final int id;
  final int ownerId;
  final int storeId;
  final String name;
  final String? email;
  final String username;
  final String password;
  final String role;
  final int isActive;
  final DateTime createdAt;

  KelolaUser({
    required this.id,
    required this.ownerId,
    required this.storeId,
    required this.name,
    this.email,
    required this.username,
    required this.password,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  factory KelolaUser.fromJson(Map<String, dynamic> json) {
    return KelolaUser(
      id: json['id'],
      ownerId: json['owner_id'],
      storeId: json['store_id'],
      name: json['name'],
      email: json['email'],
      username: json['username'],
      password: json['password'],
      role: json['role'],
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_id': ownerId,
        'store_id': storeId,
        'name': name,
        'email': email,
        'username': username,
        'password': password,
        'role': role,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
      };
}
