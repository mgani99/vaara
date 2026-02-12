class PaymentModel {
  final String paymentId;
  final String orgId;
  final String propertyId;
  final String unitId;
  final String tenantId;
  final double amount;
  final String paymentMethod;     // cash, zelle, venmo, etc.
  final String transactionType;   // rent, deposit, fee, refund
  final String note;
  final int timestamp;            // epoch
  final String period;            // MMYYYY

  PaymentModel({
    required this.paymentId,
    required this.orgId,
    required this.propertyId,
    required this.unitId,
    required this.tenantId,
    required this.amount,
    required this.paymentMethod,
    required this.transactionType,
    required this.note,
    required this.timestamp,
    required this.period,
  });

  Map<String, dynamic> toMap() {
    return {
      "orgId": orgId,
      "propertyId": propertyId,
      "unitId": unitId,
      "tenantId": tenantId,
      "amount": amount,
      "paymentMethod": paymentMethod,
      "transactionType": transactionType,
      "note": note,
      "timestamp": timestamp,
      "period": period,
    };
  }

  factory PaymentModel.fromMap(String id, Map<String, dynamic> map) {
    return PaymentModel(
      paymentId: id,
      orgId: map["orgId"],
      propertyId: map["propertyId"],
      unitId: map["unitId"],
      tenantId: map["tenantId"],
      amount: (map["amount"] ?? 0).toDouble(),
      paymentMethod: map["paymentMethod"],
      transactionType: map["transactionType"],
      note: map["note"] ?? "",
      timestamp: map["timestamp"],
      period: map["period"],
    );
  }
}
