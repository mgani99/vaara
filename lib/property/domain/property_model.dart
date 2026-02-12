class PropertyModel {
  final String propertyId;
  final String orgId;
  final String name;
  final String address;
  final String type; // single_family, multi_family, commercial
  final int createdAt;

  PropertyModel({
    required this.propertyId,
    required this.orgId,
    required this.name,
    required this.address,
    required this.type,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "orgId": orgId,
      "name": name,
      "address": address,
      "type": type,
      "createdAt": createdAt,
    };
  }

  factory PropertyModel.fromMap(String id, Map<String, dynamic> map) {
    return PropertyModel(
      propertyId: id,
      orgId: map["orgId"],
      name: map["name"],
      address: map["address"],
      type: map["type"],
      createdAt: map["createdAt"],
    );
  }
}
