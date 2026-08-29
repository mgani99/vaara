// lib/login/model/org_user_repository.dart

import 'package:firebase_database/firebase_database.dart';
import 'package:my_app/login/domain/orgUser.dart';

import '../domain/re_user.dart';


class OrgUserRepository {
  final DatabaseReference _ref = FirebaseDatabase.instance.ref('orgUsers');
  final DatabaseReference _orgRef = FirebaseDatabase.instance.ref('orgs');
  final DatabaseReference _userOrgsRef = FirebaseDatabase.instance.ref('userOrgs');

  Future<OrgUser?> getOrgUser(String orgId, String userId) async {
    final snap = await _ref.child(orgId).child(userId).get();
    if (!snap.exists) return null;
    final map = Map<String, dynamic>.from(snap.value as Map);
    return OrgUser.fromMap(orgId, userId, map);
  }

  Future<void> addOrgUser({
    required String orgId,
    required String userId,
    required String role, // landlord | tenant | contractor | property_manager
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // 1. Check if user already exists in this org
    final existingSnap = await _ref.child(orgId).child(userId).get();

    if (existingSnap.exists) {
      // User already exists → just add role
      await addRole(orgId, userId, role);
      await setDefaultRole(orgId, userId, role);
      await _userOrgsRef.child(userId).child(orgId).set(true);
      return;
    }

    // 2. Build new OrgUser model
    final orgUser = OrgUser(
      orgId: orgId,
      userId: userId,
      roles: {role: true},
      roleMeta: {
        role: RoleMeta(
          addedAt: now,
          updatedAt: now,
        )
      },
      defaultRole: role,
      ownershipPercent: 0,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    // 3. Write to orgUsers/{orgId}/{userId}
    await _ref.child(orgId).child(userId).set(orgUser.toMap());

    // 4. Reverse lookup: userOrgs/{userId}/{orgId} = true
    await _userOrgsRef.child(userId).child(orgId).set(true);
  }

  Future<List<OrgUser>> getUsersForOrg(String orgId) async {
    final snapshot = await _ref.child(orgId).get();
    if (!snapshot.exists) return [];

    final List<OrgUser> users = [];

    for (final child in snapshot.children) {
      final userId = child.key;

      if (userId == null) continue;
      if (child.value is! Map) continue;

      final map = Map<String, dynamic>.from(child.value as Map);

      users.add(
        OrgUser.fromMap(orgId, userId, map),
      );
    }

    return users;
  }


  Future<List<Map<String, dynamic>>> getOrgsForUser(String userId) async {
    final userOrgsSnap = await _userOrgsRef.child(userId).get();
    if (!userOrgsSnap.exists) return [];

    final List<Map<String, dynamic>> orgs = [];

    for (final orgEntry in userOrgsSnap.children) {
      final orgId = orgEntry.key!;
      final orgSnap = await _orgRef.child(orgId).get();

      if (orgSnap.exists && orgSnap.value is Map) {
        final data = Map<String, dynamic>.from(orgSnap.value as Map);
        orgs.add(data);
      }
    }

    return orgs;
  }

  Future<List<OrgUser>> getMembershipsForUser(String userId) async {
    final snap = await _ref.get();
    if (!snap.exists) return [];
    final List<OrgUser> out = [];
    for (final orgSnap in snap.children) {
      final orgId = orgSnap.key!;
      final child = orgSnap.child(userId);
      if (child.exists) {
        final map = Map<String, dynamic>.from(child.value as Map);
        out.add(OrgUser.fromMap(orgId, userId, map));
      }
    }
    return out;
  }

  Future<void> updateOrgUser(OrgUser orgUser) async {
    final path = _ref.child(orgUser.orgId).child(orgUser.userId);
    await path.update(orgUser.toMap());
  }

  Future<void> setDefaultRole(String orgId, String userId, String role) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final updates = <String, dynamic>{
      'defaultRole': role,
      'updatedAt': now,
      'roleMeta/$role/updatedAt': now,
    };
    await _ref.child(orgId).child(userId).update(updates);
  }

  Future<void> addRole(String orgId, String userId, String role) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final updates = <String, dynamic>{
      'roles/$role': true,
      'roleMeta/$role/addedAt': now,
      'updatedAt': now,
    };
    await _ref.child(orgId).child(userId).update(updates);
  }

  Future<void> removeRole(String orgId, String userId, String role) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final updates = <String, dynamic>{
      'roles/$role': null,
      'roleMeta/$role/removedAt': now,
      'updatedAt': now,
    };
    await _ref.child(orgId).child(userId).update(updates);
  }

  Future<void> appendHistoryEvent(String orgId, String userId, Map<String, dynamic> event) async {
    final ref = _ref.child(orgId).child(userId).child('history').push();
    await ref.set(event);
  }

  // ---------------------------------------------------------------------------
  // NEW: Create a new Org with a unique name (username + unique integer)
  // ---------------------------------------------------------------------------
  Future<String> createDefaultOrg({
    required int ownerUserId,
    required String orgName, // e.g. "mohammed"
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // 1. Generate unique org name
    final base = orgName.toLowerCase().replaceAll(" ", "-");
    int counter = 1;
    String finalName = "$base-$counter";

    // Check uniqueness
    final orgsSnap = await _orgRef.get();
    if (orgsSnap.exists) {
      final existingNames = <String>{};
      for (final child in orgsSnap.children) {
        final data = child.value as Map?;
        if (data != null && data['name'] != null) {
          existingNames.add(data['name']);
        }
      }

      while (existingNames.contains(finalName)) {
        counter++;
        finalName = "$base-$counter";
      }
    }

    // 2. Create org record
    final orgRef = _orgRef.push();
    final orgId = orgRef.key!;

    await orgRef.set({
      "orgId": orgId,
      "name": finalName,
      "createdAt": now,
      "updatedAt": now,
      "ownerUserId": ownerUserId,
    });

    // 3. Create OrgUser membership for owner
    await _ref.child(orgId).child(ownerUserId.toString()).set({
      "roles": {"landlord": true},
      "roleMeta": {
        "landlord": {"addedAt": now}
      },
      "defaultRole": "landlord",
      "ownershipPercent": 100,
      "isActive": true,
      "createdAt": now,
      "updatedAt": now,
    });

    // 4. Reverse lookup: user → org
    await _userOrgsRef.child(ownerUserId.toString()).child(orgId).set(true);

    return orgId;
  }
  Future<void> createUserOrgs(int userId, String orgId) async{
    await _userOrgsRef.child(userId.toString()).child(orgId).set(true);
  }
  Future<String?> getOrgName(String orgId) async {
    final snap = await _orgRef.child(orgId).child("name").get();
    if (!snap.exists) return null; return snap.value as String;
  }

  Future<ReUser?> getUserProfile(String userId) async {
    final snap = await FirebaseDatabase.instance
        .ref("users")
        .child(userId)
        .get();

    if (!snap.exists) return null;

    final map = Map<String, dynamic>.from(snap.value as Map);
    return ReUser.fromMap(map);
  }

}
