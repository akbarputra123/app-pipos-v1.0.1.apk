class OwnerProfile {
  final int id;
  final String businessName;
  final String email;
  final String phone;
  final String address;
  final DateTime createdAt;

  OwnerProfile({
    required this.id,
    required this.businessName,
    required this.email,
    required this.phone,
    required this.address,
    required this.createdAt,
  });

  factory OwnerProfile.fromJson(Map<String, dynamic> json) {
    return OwnerProfile(
      id: json['id'],
      businessName: json['business_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
