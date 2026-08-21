import 'package:my_app/property/model/property_repository.dart';

import 'package:my_app/session/app_data.dart';
import '../domain/property_model.dart';

class PropertyService {
  final PropertyRepository repo;

  final AppSession session;

  PropertyService({
    required this.repo,
    required this.session,
  });

  Future<List<PropertyModel>> getProperties(String orgId) {
    return repo.fetchProperties(orgId);
  }


  Future<PropertyModel?> getPropertyById(String orgId, String propertyId) {
    return repo.getPropertyById(orgId, propertyId);
  }

  Future<void> deleteProperty(String orgId, String propertyId) {
    return repo.deleteProperty(orgId, propertyId);
  }

  Future<void> updateProperty(String orgId, String propertyId, String trim, {required String address}) async {}
  Future<String> createProperty({
    required AppSession session,
    required String name,
    required String address,
    String? city,
    String? state,
    required String type,
    int? numUnits,
    double? sqft,
    double? rent,
  }) async {
    final orgId = session.activeOrgId!;
    final createTime = DateTime.now().millisecondsSinceEpoch;
    final property = PropertyModel(
      propertyId: "",
      orgId: orgId,
      name: name,
      address: address,
      city: city,
      state: state,
      type: type,
      status: "",
      numUnits: numUnits,
      sqft: sqft,
      createdAt: createTime,
    );

    final propertyId = await repo.createProperty(property);
    //final newProperty = property.copyWith(propertyId: propertyId);

   // FIX: write propertyId into the document
    await repo.updatePropertyId(propertyId, orgId);




    return propertyId;
  }

}
