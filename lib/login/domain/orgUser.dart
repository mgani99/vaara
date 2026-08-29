
// lib/domain/org_user.dart
class RoleMeta {
  final int addedAt;
  final int? removedAt;
  final int? updatedAt;

  RoleMeta({required this.addedAt, this.removedAt, this.updatedAt});

  factory RoleMeta.fromMap(Map<String, dynamic> m) {
    return RoleMeta(
      addedAt: m['addedAt'] ?? 0,
      removedAt: m['removedAt'],
      updatedAt: m['updatedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'addedAt': addedAt,
      if (removedAt != null) 'removedAt': removedAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }
}

class OrgUser {
  final String orgId;
  final String userId;
  final Map<String, bool> roles;
  final Map<String, RoleMeta> roleMeta;
  final String? defaultRole;
  final double ownershipPercent;
  final bool isActive;
  final int createdAt;
  final int updatedAt;

  OrgUser({
    required this.orgId,
    required this.userId,
    required this.roles,
    this.roleMeta = const {},
    this.defaultRole,
    this.ownershipPercent = 0.0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  // ⭐ FIXED: Correct signature (orgId + userId + map)
  factory OrgUser.fromMap(String orgId, String userId, Map<String, dynamic> map) {
    // -----------------------------
    // ROLES
    // -----------------------------
    final roles = <String, bool>{};
    if (map['roles'] is Map) {
      (map['roles'] as Map).forEach((k, v) {
        roles[k.toString()] = v == true;
      });
    } else if (map['role'] != null) {
      // legacy single-role support
      roles[map['role'].toString()] = true;
    }

    // -----------------------------
    // ROLE META
    // -----------------------------
    final rm = <String, RoleMeta>{};
    if (map['roleMeta'] is Map) {
      (map['roleMeta'] as Map).forEach((k, v) {
        rm[k.toString()] = RoleMeta.fromMap(Map<String, dynamic>.from(v));
      });
    }

    // -----------------------------
    // OWNERSHIP PERCENT (SAFE)
    // -----------------------------
    final rawPercent = map['ownershipPercent'];
    double percent;

    if (rawPercent is double) {
      percent = rawPercent;
    } else if (rawPercent is int) {
      percent = rawPercent.toDouble();
    } else if (rawPercent is String) {
      percent = double.tryParse(rawPercent) ?? 0.0;
    } else {
      percent = 0.0;
    }

    return OrgUser(
      orgId: orgId,
      userId: userId,
      roles: roles,
      roleMeta: rm,
      defaultRole: map['defaultRole'],
      ownershipPercent: percent,
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] ?? 0,
      updatedAt: map['updatedAt'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roles': roles,
      'roleMeta': roleMeta.map((k, v) => MapEntry(k, v.toMap())),
      'defaultRole': defaultRole,
      'ownershipPercent': ownershipPercent,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  OrgUser copyWith({
    Map<String, bool>? roles,
    Map<String, RoleMeta>? roleMeta,
    String? defaultRole,
    double? ownershipPercent,
    bool? isActive,
    int? updatedAt,
  }) {
    return OrgUser(
      orgId: orgId,
      userId: userId,
      roles: roles ?? Map.from(this.roles),
      roleMeta: roleMeta ?? Map.from(this.roleMeta),
      defaultRole: defaultRole ?? this.defaultRole,
      ownershipPercent: ownershipPercent ?? this.ownershipPercent,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}

