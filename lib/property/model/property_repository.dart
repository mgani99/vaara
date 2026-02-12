import 'package:firebase_database/firebase_database.dart';

import '../domain/property_model.dart';

class PropertyRepository {
  final _db = FirebaseDatabase.instance.ref();

  Future<List<PropertyModel>> fetchProperties(String orgId) async {
    final snapshot = await _db.child("Orgs/$orgId/Properties").get();
    if (!snapshot.exists) return [];

    return snapshot.children.map((child) {
      final map = Map<String, dynamic>.from(child.value as Map);
      return PropertyModel.fromMap(child.key!, map);
    }).toList();
  }

  Future<String> createProperty(PropertyModel property) async {
    final ref = _db.child("Orgs/${property.orgId}/Properties").push();
    await ref.set(property.toMap());
    return ref.key!;
  }

  // ------------------------------------------------------------
  // NEW: Get Property Name
  // ------------------------------------------------------------
  Future<String?> getPropertyName(String orgId, String propertyId) async {
    final snapshot =
    await _db.child("Orgs/$orgId/Properties/$propertyId/name").get();

    if (!snapshot.exists) return null;
    return snapshot.value as String?;
  }
}
