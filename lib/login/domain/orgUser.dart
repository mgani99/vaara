class OrgUser {
  final String orgId;
  final String userId;
  final String role;
  final double ownershipPercent;
  final bool isDefaultRole; // NEW

  OrgUser({
    required this.orgId,
    required this.userId,
    required this.role,
    this.ownershipPercent = 100,
    this.isDefaultRole = false,
  });

  factory OrgUser.fromMap(Map<String, dynamic> data) {
    return OrgUser(
      orgId: data['orgId'],
      userId: data['userId'],
      role: data['role'],
      ownershipPercent: (data['ownershipPercent'] ?? 100).toDouble(),
      isDefaultRole: data['isDefaultRole'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orgId': orgId,
      'userId': userId,
      'role': role,
      'ownershipPercent': ownershipPercent,
      'isDefaultRole': isDefaultRole,
    };
  }

  OrgUser copyWith({
    String? role,
    double? ownershipPercent,
    bool? isDefaultRole,
  }) {
    return OrgUser(
      orgId: orgId,
      userId: userId,
      role: role ?? this.role,
      ownershipPercent: ownershipPercent ?? this.ownershipPercent,
      isDefaultRole: isDefaultRole ?? this.isDefaultRole,
    );
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
