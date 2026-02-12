import 'package:firebase_database/firebase_database.dart';
import 'package:my_app/session/user_role.dart';

class RoleResolver {
  final DatabaseReference _orgUsersRef =
  FirebaseDatabase.instance.ref("OrgUsers");

  // Role priority (highest → lowest)
  static const List<UserRole> _priority = [
    UserRole.landlord,
    UserRole.manager,
    UserRole.contractor,
    UserRole.tenant,
  ];

  /// Resolve the user's highest-priority role for a given org.
  /// This method NEVER returns null.
  Future<UserRole> resolveRole({
    required String userId,
    required String orgId,
  }) async {
    final snapshot = await _orgUsersRef.child(orgId).child(userId).get();

    if (!snapshot.exists) {
      // Fallback: if user has no org record, default to tenant
      return UserRole.tenant;
    }

    final data = Map<String, dynamic>.from(snapshot.value as Map);

    // Case 1: Single role stored as "role": "tenant"
    if (data.containsKey("role")) {
      final roleString = data["role"]?.toString().toLowerCase();
      final parsed = _parseRole(roleString);
      return parsed ?? UserRole.tenant;
    }

    // Case 2: Multi-role structure:
    // roles: { "tenant": true, "contractor": true }
    if (data.containsKey("roles")) {
      final rolesMap = Map<String, dynamic>.from(data["roles"]);
      final userRoles = rolesMap.entries
          .where((e) => e.value == true)
          .map((e) => _parseRole(e.key))
          .where((r) => r != null)
          .cast<UserRole>()
          .toList();

      if (userRoles.isEmpty) return UserRole.tenant;

      // Pick highest priority
      for (final role in _priority) {
        if (userRoles.contains(role)) return role;
      }
    }

    // Fallback
    return UserRole.tenant;
  }

  /// Convert string → UserRole enum
  UserRole? _parseRole(String? role) {
    if (role == null) return null;

    switch (role) {
      case "landlord":
        return UserRole.landlord;
      case "manager":
        return UserRole.manager;
      case "contractor":
        return UserRole.contractor;
      case "tenant":
        return UserRole.tenant;
      default:
        return null;
    }
  }
}
