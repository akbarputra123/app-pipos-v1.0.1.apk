class AuthResponse {
  final bool success;
  final String message;
  final String? token;
  final User? user;

  AuthResponse({
    required this.success,
    required this.message,
    this.token,
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] == true,
      message: json['message'] ?? '',
      token: json['token'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }
}


class User {
  final int id;
  final int ownerId;
  final int? storeId;
  final String role;
  final String username;
  final String email;
  final String dbName;
  final String plan;

  // OPTIONAL
  final String? name;
  final String? businessName;
  final String? storeName;

  User({
    required this.id,
    required this.ownerId,
    this.storeId,
    required this.role,
    required this.username,
    required this.email,
    required this.dbName,
    required this.plan,
    this.name,
    this.businessName,
    this.storeName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      ownerId: json['owner_id'],
      storeId: json['store_id'],
      role: json['role'],
      username: json['username'],
      email: json['email'],
      dbName: json['db_name'],
      plan: json['plan'],
      name: json['name'], // boleh null
      businessName: json['business_name'],
      storeName: json['store_name'],
    );
  }
}

