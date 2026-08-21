import 'package:firebase_database/firebase_database.dart';
import '../domain/property_model.dart' show PropertyModel, PropertyValuationModel, PropertyTaxModel, PropertyInsuranceModel;

class PropertyRepository {
  final _db = FirebaseDatabase.instance.ref();

  // ------------------------------------------------------------
  // Fetch all properties (filters out archived/deleted)
  // ------------------------------------------------------------
  Future<List<PropertyModel>> fetchProperties(String orgId) async {
    final snapshot = await _db.child("orgs/$orgId/Properties").get();
    if (!snapshot.exists) return [];

    return snapshot.children
        .map((child) {
      final map = Map<String, dynamic>.from(child.value as Map);
      return PropertyModel.fromMap(child.key!, map);
    })
        .where((p) =>
    p.isDeleted != true &&               // ⭐ new archive flag
        p.status != "archived" &&            // ⭐ new status
        p.status != "deleted")               // ⭐ backward compatibility
        .toList();
  }

  // ------------------------------------------------------------
  // Create property
  // ------------------------------------------------------------
  Future<String> createProperty(PropertyModel property) async {
    final ref = _db.child("orgs/${property.orgId}/Properties").push();
    await ref.set(property.toMap());
    return ref.key!;
  }

  // ------------------------------------------------------------
  // Get property by ID (filters archived)
  // ------------------------------------------------------------
  Future<PropertyModel?> getPropertyById(String orgId, String propertyId) async {
    final snapshot =
    await _db.child("orgs/$orgId/Properties/$propertyId").get();

    if (!snapshot.exists) return null;

    final map = Map<String, dynamic>.from(snapshot.value as Map);
    final model = PropertyModel.fromMap(propertyId, map);

    if (model.isDeleted == true) return null;     // ⭐ new
    if (model.status == "archived") return null;  // ⭐ new
    if (model.status == "deleted") return null;   // ⭐ backward compatibility

    return model;
  }

  Future<void> updatePropertyId(String propertyId, String orgId) async {
    await _db.child("orgs/$orgId/Properties/$propertyId").update({
      "propertyId": propertyId,
    });
  }

  // ------------------------------------------------------------
  // Soft delete / archive property
  // ------------------------------------------------------------
  Future<void> deleteProperty(String orgId, String propertyId) async {
    final ref = _db.child("orgs/$orgId/Properties/$propertyId");

    await ref.update({
      "status": "archived",                         // ⭐ new preferred status
      "isDeleted": true,                            // ⭐ new archive flag
      "deletedAt": DateTime.now().toIso8601String(),
    });
  }

  // ------------------------------------------------------------
  // Optional: Get property name only
  // ------------------------------------------------------------
  Future<String?> getPropertyName(String orgId, String propertyId) async {
    final snapshot =
    await _db.child("orgs/$orgId/Properties/$propertyId/name").get();

    if (!snapshot.exists) return null;
    return snapshot.value as String?;
  }

  // ------------------------------------------------------------
  // NEW: Get all properties for org (filters archived)
  // ------------------------------------------------------------
  Future<List<PropertyModel>> getPropertiesForOrg(String orgId) async {
    try {
      final snapshot = await _db.child("orgs/$orgId/Properties").get();
      if (!snapshot.exists) return [];

      return snapshot.children
          .map((child) {
        final map = Map<String, dynamic>.from(child.value as Map);
        return PropertyModel.fromMap(child.key!, map);
      })
          .where((p) =>
      p.isDeleted != true &&               // ⭐ new archive flag
          p.status != "archived" &&            // ⭐ new status
          p.status != "deleted")               // ⭐ backward compatibility
          .toList();
    } catch (e) {
      print("🔥 Error loading properties for org $orgId: $e");
      return [];
    }
  }

  Future<PropertyValuationModel?> getValuation(String orgId, String propertyId) async {
    final snapshot = await _db.child("orgs/$orgId/PropertyValuations/$propertyId").get();
    if (!snapshot.exists) return null;

    final map = Map<String, dynamic>.from(snapshot.value as Map);
    return PropertyValuationModel.fromMap(propertyId, map);
  }

  Future<void> updateValuation(String orgId, PropertyValuationModel model) async {
    await _db.child("orgs/$orgId/PropertyValuations/${model.valuationId}")
        .update(model.toMap());
  }
  Future<PropertyTaxModel?> getTax(String orgId, String propertyId) async {
    final snapshot = await _db.child("orgs/$orgId/PropertyTaxes/$propertyId").get();
    if (!snapshot.exists) return null;

    final map = Map<String, dynamic>.from(snapshot.value as Map);
    return PropertyTaxModel.fromMap(propertyId, map);
  }

  Future<void> updateTax(String orgId, PropertyTaxModel model) async {
    await _db.child("orgs/$orgId/PropertyTaxes/${model.taxId}")
        .update(model.toMap());
  }
  Future<PropertyInsuranceModel?> getInsurance(String orgId, String propertyId) async {
    final snapshot = await _db.child("orgs/$orgId/PropertyInsurance/$propertyId").get();
    if (!snapshot.exists) return null;

    final map = Map<String, dynamic>.from(snapshot.value as Map);
    return PropertyInsuranceModel.fromMap(propertyId, map);
  }

  Future<void> updateInsurance(String orgId, PropertyInsuranceModel model) async {
    await _db.child("orgs/$orgId/PropertyInsurance/${model.insuranceId}")
        .update(model.toMap());
  }

  Future<void> updateProperty(PropertyModel updatedProperty) async {
    final ref = _db.child("orgs/${updatedProperty.orgId}/Properties/${updatedProperty.propertyId}");

    await ref.update(updatedProperty.toMap());
  }




}
