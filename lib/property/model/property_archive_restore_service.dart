import 'package:firebase_database/firebase_database.dart';

class PropertyArchiveService {
  final DatabaseReference _db;

  PropertyArchiveService(this._db);

  // ------------------------------------------------------------
  // ARCHIVE PROPERTY + ALL ASSOCIATED DATA
  // ------------------------------------------------------------
  Future<void> archivePropertyCascade(String orgId, String propertyId) async {
    final propRef = _db.child("orgs/$orgId/Properties/$propertyId");

    // 1. Archive property
    await propRef.update({
      "status": "archived",
      "isDeleted": true,
      "deletedAt": DateTime.now().toIso8601String(),
    });

    // 2. Archive units
    final unitsSnap = await _db.child("orgs/$orgId/Units").get();
    for (final child in unitsSnap.children) {
      final map = Map<String, dynamic>.from(child.value as Map);
      if (map["propertyId"] == propertyId) {
        await child.ref.update({
          "status": "archived",
          "isDeleted": true,
          "deletedAt": DateTime.now().toIso8601String(),
        });
      }
    }

    // 3. Archive leases
    final leasesSnap = await _db.child("orgs/$orgId/LeaseDetails").get();
    for (final child in leasesSnap.children) {
      final map = Map<String, dynamic>.from(child.value as Map);
      if (map["propertyId"] == propertyId) {
        await child.ref.update({
          "status": "archived",
          "isDeleted": true,
          "deletedAt": DateTime.now().toIso8601String(),
        });
      }
    }

    // 4. Archive tenants referenced by leases
    final tenantsSnap = await _db.child("orgs/$orgId/Tenants").get();
    for (final child in tenantsSnap.children) {
      final map = Map<String, dynamic>.from(child.value as Map);
      if (map["propertyId"] == propertyId) {
        await child.ref.update({
          "status": "archived",
          "isDeleted": true,
          "deletedAt": DateTime.now().toIso8601String(),
        });
      }
    }
  }

  // ------------------------------------------------------------
  // RESTORE PROPERTY + ALL ASSOCIATED DATA
  // ------------------------------------------------------------
  Future<void> restorePropertyCascade(String orgId, String propertyId) async {
    final propRef = _db.child("orgs/$orgId/Properties/$propertyId");

    // 1. Restore property
    await propRef.update({
      "status": "active",
      "isDeleted": false,
      "deletedAt": null,
    });

    // 2. Restore units
    final unitsSnap = await _db.child("orgs/$orgId/Units").get();
    for (final child in unitsSnap.children) {
      final map = Map<String, dynamic>.from(child.value as Map);
      if (map["propertyId"] == propertyId) {
        await child.ref.update({
          "status": "active",
          "isDeleted": false,
          "deletedAt": null,
        });
      }
    }

    // 3. Restore leases
    final leasesSnap = await _db.child("orgs/$orgId/LeaseDetails").get();
    for (final child in leasesSnap.children) {
      final map = Map<String, dynamic>.from(child.value as Map);
      if (map["propertyId"] == propertyId) {
        await child.ref.update({
          "status": "active",
          "isDeleted": false,
          "deletedAt": null,
        });
      }
    }

    // 4. Restore tenants
    final tenantsSnap = await _db.child("orgs/$orgId/Tenants").get();
    for (final child in tenantsSnap.children) {
      final map = Map<String, dynamic>.from(child.value as Map);
      if (map["propertyId"] == propertyId) {
        await child.ref.update({
          "status": "active",
          "isDeleted": false,
          "deletedAt": null,
        });
      }
    }
  }
}
