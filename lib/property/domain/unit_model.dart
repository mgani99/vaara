class UnitModel {
  final String unitId;
  final String orgId;
  final String propertyId;
  final String name;
  final int bedrooms;
  final int bathrooms;
  final double rentAmount;
  final int createdAt;

  UnitModel({
    required this.unitId,
    required this.orgId,
    required this.propertyId,
    required this.name,
    required this.bedrooms,
    required this.bathrooms,
    required this.rentAmount,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "orgId": orgId,
      "propertyId": propertyId,
      "name": name,
      "bedrooms": bedrooms,
      "bathrooms": bathrooms,
      "rentAmount": rentAmount,
      "createdAt": createdAt,
    };
  }

  factory UnitModel.fromMap(String id, Map<String, dynamic> map) {
    return UnitModel(
      unitId: id,
      orgId: map["orgId"],
      propertyId: map["propertyId"],
      name: map["name"],
      bedrooms: map["bedrooms"] ?? 0,
      bathrooms: map["bathrooms"] ?? 0,
      rentAmount: (map["rentAmount"] ?? 0).toDouble(),
      createdAt: map["createdAt"] ?? 0,
    );
  }
}
