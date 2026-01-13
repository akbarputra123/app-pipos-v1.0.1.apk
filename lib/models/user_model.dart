import 'store_profile_model.dart';

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

  // OPTIONAL (lama)
  final String? name;
  final String? businessName;
  final String? storeName;

  // 🔥 TAMBAHAN BARU (UNTUK OWNER)
  final List<StoreProfile> stores;

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
    this.stores = const [], // 🔥 DEFAULT AMAN
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
      name: json['name'],
      businessName: json['business_name'],
      storeName: json['store_name'],
stores: json['stores'] != null
    ? (json['stores'] as List)
        .map(
          (e) => StoreProfile.fromJson({
            'id': e['id'],
            'owner_id': json['owner_id'], // 🔥 ambil dari user
            'name': e['name'] ?? '',
            'phone': '',
            'address': '',
            'receipt_template': '',
            'created_at': DateTime.now().toIso8601String(),
            'tax_percentage': 0,
          }),
        )
        .toList()
    : const [],

     
    );
  }
}


