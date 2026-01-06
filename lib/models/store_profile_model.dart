class StoreProfile {
  final int id;
  final int ownerId;
  final String name;
  final String phone;
  final String address;
  final String receiptTemplate;
  final DateTime createdAt;
  final double taxPercentage;

  StoreProfile({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.phone,
    required this.address,
    required this.receiptTemplate,
    required this.createdAt,
    required this.taxPercentage,
  });

  factory StoreProfile.fromJson(Map<String, dynamic> json) {
    return StoreProfile(
      id: json['id'],
      ownerId: json['owner_id'],
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      receiptTemplate: json['receipt_template'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      taxPercentage:
          double.tryParse(json['tax_percentage']?.toString() ?? '0') ?? 0,
    );
  }
}
