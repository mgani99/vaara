import 'package:firebase_database/firebase_database.dart';
import 'package:my_app/login/domain/orgUser.dart';

class OrgUserRepository {
  final DatabaseReference db;

  OrgUserRepository() : db = FirebaseDatabase.instance.ref();

  // ------------------------------------------------------------
  // INTERNAL HELPERS
  // ------------------------------------------------------------
  DatabaseReference _orgUserRef(String orgId, int userId) =>
      db.child("OrgUsers/$orgId/$userId");

  DatabaseReference _userOrgsRef(int userId) =>
      db.child("UserOrgs/$userId");

  // ------------------------------------------------------------
  // APPLY INVITATION (tenant, manager, contractor, etc.)
  // ------------------------------------------------------------
  Future<void> applyInvitation({
    required String orgId,
    required int userId,
    required String role,
  }) async {
    await addUserToOrg(
      orgId: orgId,
      userId: userId,
      role: role,
    );
  }

  // ------------------------------------------------------------
  // CREATE DEFAULT ORG
  // ------------------------------------------------------------
  Future<String> createDefaultOrg({
    required int ownerUserId,
    required String orgName,
  }) async {
    final orgRef = db.child("Orgs").push();
    final orgId = orgRef.key!;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Create org metadata
    await orgRef.set({
      "orgId": orgId,
      "name": orgName,
      "ownerUserId": ownerUserId,
      "createdAt": now,
      "updatedAt": now,
    });

    // Add owner to org
    await addUserToOrg(
      orgId: orgId,
      userId: ownerUserId,
      role: "landlord",
    );

    return orgId;
  }

  Future<String?> getOrgName(String orgId) async {
    final snap = await db.child("Orgs/$orgId").get();
    return snap.child("name").value as String?;
  }

  // ------------------------------------------------------------
  // ADD USER TO ORG
  // ------------------------------------------------------------
  Future<void> addUserToOrg({
    required String orgId,
    required int userId,
    required String role,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // orgUsers/<orgId>/<userId>
    await _orgUserRef(orgId, userId).set({
      "userId": userId,
      "role": role,
      "createdAt": now,
      "updatedAt": now,
    });

    // userOrgs/<userId>/<orgId>
    await _userOrgsRef(userId).child(orgId).set(true);
  }

  // ------------------------------------------------------------
  // ROLE CHECK HELPERS
  // ------------------------------------------------------------
  Future<bool> isOrgOwner(int userId, String orgId) async {
    final snap = await _orgUserRef(orgId, userId).child("role").get();
    return snap.value == "landlord";
  }

  Future<bool> isManager(int userId, String orgId) async {
    final snap = await _orgUserRef(orgId, userId).child("role").get();
    return snap.value == "manager";
  }

  Future<bool> isTenant(int userId, String orgId) async {
    final snap = await _orgUserRef(orgId, userId).child("role").get();
    return snap.value == "tenant";
  }

  // ------------------------------------------------------------
  // GET ALL ORGS FOR A USER
  // ------------------------------------------------------------
  Future<List<String>> getUserOrgs(int userId) async {
    final snap = await _userOrgsRef(userId).get();
    if (!snap.exists) return [];

    final value = snap.value;
    if (value is Map) {
      return value.keys.cast<String>().toList();
    }

    return [];
  }

  Future<void> addTenantToOrg({
    required String orgId,
    required String userId,
  }) async {
    await db.child("Orgs/$orgId/Users/$userId").set({
      "role": "tenant",
      "joinedAt": ServerValue.timestamp,
    });
  }
  Future<List<OrgUser>> getOrgUsersForUser({
    required String orgId,
    required int userId,
  }) async {
    final snap = await _orgUserRef(orgId, userId).get();
    if (!snap.exists) return [];

    final data = snap.value as Map<dynamic, dynamic>;

    // Today: one role per user per org
    // Future: support multiple roles by storing a list under OrgUsers/{orgId}/{userId}/roles
    return [
      OrgUser(
        orgId: orgId,
        userId: data["userId"].toString(),
        role: data["role"],
        ownershipPercent: (data["ownershipPercent"] ?? 100).toDouble(),
        isDefaultRole: data["isDefaultRole"] ?? false,
      )
    ];
  }
  Future<void> updateOrgUser(OrgUser orgUser) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await _orgUserRef(orgUser.orgId, int.parse(orgUser.userId)).update({
      "userId": orgUser.userId,
      "role": orgUser.role,
      "ownershipPercent": orgUser.ownershipPercent,
      "isDefaultRole": orgUser.isDefaultRole,
      "updatedAt": now,
    });
  }




}

