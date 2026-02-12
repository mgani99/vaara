class BalanceModel {
  final String unitId;
  final String propertyId;
  final String orgId;
  final double totalPaid;
  final double totalDue;
  final String period; // MMYYYY

  BalanceModel({
    required this.unitId,
    required this.propertyId,
    required this.orgId,
    required this.totalPaid,
    required this.totalDue,
    required this.period,
  });

  Map<String, dynamic> toMap() {
    return {
      "unitId": unitId,
      "propertyId": propertyId,
      "orgId": orgId,
      "totalPaid": totalPaid,
      "totalDue": totalDue,
      "period": period,
    };
  }

  factory BalanceModel.fromMap(Map<String, dynamic> map) {
    return BalanceModel(
      unitId: map["unitId"],
      propertyId: map["propertyId"],
      orgId: map["orgId"],
      totalPaid: (map["totalPaid"] ?? 0).toDouble(),
      totalDue: (map["totalDue"] ?? 0).toDouble(),
      period: map["period"],
    );
  }
}
