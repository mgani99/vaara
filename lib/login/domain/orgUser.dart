class OrgUser {
  final String orgId;
  final String userId;
  final String role; // landlord | tenant | contractor
  final double ownershipPercent; // NEW (default 100 for landlords)

  OrgUser({
    required this.orgId,
    required this.userId,
    required this.role,
    this.ownershipPercent = 100,
  });

  factory OrgUser.fromMap(Map<String, dynamic> data) {
    return OrgUser(
      orgId: data['orgId'],
      userId: data['userId'],
      role: data['role'],
      ownershipPercent: (data['ownershipPercent'] ?? 100).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orgId': orgId,
      'userId': userId,
      'role': role,
      'ownershipPercent': ownershipPercent,
    };
  }
}
class OrgUserModel {
  final String userId;
  final String role; // landlord, tenant, contractor
  final double ownershipPercent;

  OrgUserModel({
    required this.userId,
    required this.role,
    required this.ownershipPercent,
  });

  Map<String, dynamic> toMap() {
    return {
      "role": role,
      "ownershipPercent": ownershipPercent,
    };
  }
}
