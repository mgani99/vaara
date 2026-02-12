class LeaseDetailsModel {
  final String leaseId;
  final String orgId;
  final String propertyId;
  final String unitId;
  final List<String> tenantIds;   // userIds
  final String startDate;         // ISO string
  final String endDate;           // ISO string
  final double rentAmount;
  final int createdAt;

  LeaseDetailsModel({
    required this.leaseId,
    required this.orgId,
    required this.propertyId,
    required this.unitId,
    required this.tenantIds,
    required this.startDate,
    required this.endDate,
    required this.rentAmount,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "orgId": orgId,
      "propertyId": propertyId,
      "unitId": unitId,
      "tenantIds": tenantIds,
      "startDate": startDate,
      "endDate": endDate,
      "rentAmount": rentAmount,
      "createdAt": createdAt,
    };
  }

  factory LeaseDetailsModel.fromMap(String id, Map<String, dynamic> map) {
    return LeaseDetailsModel(
      leaseId: id,
      orgId: map["orgId"],
      propertyId: map["propertyId"],
      unitId: map["unitId"],
      tenantIds: List<String>.from(map["tenantIds"] ?? []),
      startDate: map["startDate"],
      endDate: map["endDate"],
      rentAmount: (map["rentAmount"] ?? 0).toDouble(),
      createdAt: map["createdAt"],
    );
  }
}
