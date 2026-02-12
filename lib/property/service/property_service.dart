

import 'package:my_app/property/model/property_repository.dart';

import '../domain/property_model.dart';

class PropertyService {
  final PropertyRepository repo = PropertyRepository();

  Future<List<PropertyModel>> getProperties(String orgId) {
    return repo.fetchProperties(orgId);
  }

  Future<String> createProperty(PropertyModel property) {
    return repo.createProperty(property);
  }
}
