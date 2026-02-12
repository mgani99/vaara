class TenantModel {
  final String tenantId;     // same as global UserId
  final String orgId;
  final String name;
  final String email;
  final String phone;
  final int createdAt;

  TenantModel({
    required this.tenantId,
    required this.orgId,
    required this.name,
    required this.email,
    required this.phone,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "orgId": orgId,
      "name": name,
      "email": email,
      "phone": phone,
      "createdAt": createdAt,
    };
  }

  factory TenantModel.fromMap(String id, Map<String, dynamic> map) {
    return TenantModel(
      tenantId: id,
      orgId: map["orgId"],
      name: map["name"],
      email: map["email"],
      phone: map["phone"],
      createdAt: map["createdAt"],
    );
  }
}
