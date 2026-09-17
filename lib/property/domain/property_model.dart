class PropertyModel {
  final String propertyId;
  final String orgId;
  final String name;

  /// Full concatenated address (street + city + state)
  final String address;

  /// NEW — Structured fields (optional for backward compatibility)
  final String? street;
  final String? city;
  final String? state;

  /// Building type: single_family, multi_family, commercial
  final String type;

  /// Optional metadata (NOT source of truth)
  final int? numUnits;

  /// Optional metadata
  final double? sqft;

  /// active | archived | draft | pending_setup
  final String status;

  final int createdAt;
  final String? parcelNumber;

  // ------------------------------------------------------------
  // ARCHIVE FIELDS
  // ------------------------------------------------------------
  final bool isDeleted;       // soft delete flag
  final String? deletedAt;    // ISO timestamp

  PropertyModel({
    required this.propertyId,
    required this.orgId,
    required this.name,
    required this.address,
    this.street,
    this.city,
    this.state,
    required this.type,
    this.numUnits,
    this.sqft,
    this.parcelNumber,
    required this.status,
    required this.createdAt,
    this.isDeleted = false,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "propertyId": propertyId,
      "orgId": orgId,
      "name": name,
      "address": address,

      // NEW structured fields (only saved if present)
      "street": street,
      "city": city,
      "state": state,

      "type": type,
      "numUnits": numUnits,
      "sqft": sqft,
      "status": status,
      "createdAt": createdAt,
      "parcelNumber" : parcelNumber,
      "isDeleted": isDeleted,
      "deletedAt": deletedAt,
    };
  }

  factory PropertyModel.fromMap(String propertyId, Map<String, dynamic> map) {
    return PropertyModel(
      propertyId: propertyId,
      orgId: map["orgId"] ?? "",
      name: map["name"] ?? "",
      address: map["address"] ?? "",

      // NEW structured fields — backward compatible
      street: map["street"],     // may be null for older properties
      city: map["city"],
      state: map["state"],

      type: map["type"] ?? "single_family",
      numUnits: map["numUnits"],
      sqft: (map["sqft"] is num) ? (map["sqft"] as num).toDouble() : null,
      status: map["status"] ?? "active",
      createdAt: map["createdAt"] ?? 0,
      parcelNumber: map["parcelNumber"] ?? "000",
      isDeleted: map["isDeleted"] == true,
      deletedAt: map["deletedAt"],
    );
  }

  double get totalRent => 300.00;

  PropertyModel copyWith({
    String? propertyId,
    String? orgId,
    String? name,
    String? address,
    String? street,
    String? city,
    String? state,
    String? type,
    int? numUnits,
    double? sqft,
    String? status,
    int? createdAt,
    bool? isDeleted,
    String? deletedAt,
    String? parcelNumber,
  }) {
    return PropertyModel(
      propertyId: propertyId ?? this.propertyId,
      orgId: orgId ?? this.orgId,
      name: name ?? this.name,
      address: address ?? this.address,

      // NEW structured fields
      street: street ?? this.street,
      city: city ?? this.city,
      state: state ?? this.state,

      type: type ?? this.type,
      numUnits: numUnits ?? this.numUnits,
      sqft: sqft ?? this.sqft,
      status: status ?? this.status,
      parcelNumber : parcelNumber ?? this.parcelNumber,
      createdAt: createdAt ?? this.createdAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}


class UnitModel {
  final String unitId;
  final String orgId;
  final String propertyId;

  /// residential | commercial | parking | storage | garage
  final String type;

  final String name;

  /// OLD — still supported for backward compatibility
  final String address;

  /// NEW — granular address fields
  final String streetAddress;
  final String city;
  final String state;
  final String description;

  /// Active lease for this unit (null if vacant)
  final String? currentLeaseId;

  // Residential only
  final int? bedrooms;
  final double? bathrooms;

  // Residential + Commercial
  final double? sqft;

  // Parking only
  final String? stallNumber;

  // Storage only
  final String? storageSize;

  // Garage only
  final String? garageType;

  // Appliances
  final bool hasRefrigerator;
  final bool hasStove;
  final bool hasDishwasher;
  final bool hasMicrowave;

  final int createdAt;

  // Archive fields
  final bool isDeleted;
  final String? status;
  final String? deletedAt;

  UnitModel({
    required this.unitId,
    required this.orgId,
    required this.propertyId,
    required this.type,
    required this.name,

    // OLD
    this.address = "",

    // NEW
    this.streetAddress = "",
    this.city = "",
    this.state = "",
    this.description = "",

    this.currentLeaseId,
    this.bedrooms,
    this.bathrooms,
    this.sqft,
    this.stallNumber,
    this.storageSize,
    this.garageType,

    this.hasRefrigerator = false,
    this.hasStove = false,
    this.hasDishwasher = false,
    this.hasMicrowave = false,

    required this.createdAt,
    this.isDeleted = false,
    this.status = "active",
    this.deletedAt,
  });

  UnitModel copyWith({
    String? unitId,
    String? orgId,
    String? propertyId,
    String? type,
    String? name,

    String? address,
    String? streetAddress,
    String? city,
    String? state,
    String? description,

    String? currentLeaseId,
    int? bedrooms,
    double? bathrooms,
    double? sqft,
    String? stallNumber,
    String? storageSize,
    String? garageType,

    bool? hasRefrigerator,
    bool? hasStove,
    bool? hasDishwasher,
    bool? hasMicrowave,

    int? createdAt,
    bool? isDeleted,
    String? status,
    String? deletedAt,
  }) {
    return UnitModel(
      unitId: unitId ?? this.unitId,
      orgId: orgId ?? this.orgId,
      propertyId: propertyId ?? this.propertyId,
      type: type ?? this.type,
      name: name ?? this.name,

      address: address ?? this.address,
      streetAddress: streetAddress ?? this.streetAddress,
      city: city ?? this.city,
      state: state ?? this.state,
      description: description ?? this.description,

      // ⭐ FIXED
      currentLeaseId: currentLeaseId ?? this.currentLeaseId,

      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      sqft: sqft ?? this.sqft,
      stallNumber: stallNumber ?? this.stallNumber,
      storageSize: storageSize ?? this.storageSize,
      garageType: garageType ?? this.garageType,

      hasRefrigerator: hasRefrigerator ?? this.hasRefrigerator,
      hasStove: hasStove ?? this.hasStove,
      hasDishwasher: hasDishwasher ?? this.hasDishwasher,
      hasMicrowave: hasMicrowave ?? this.hasMicrowave,

      createdAt: createdAt ?? this.createdAt,
      isDeleted: isDeleted ?? this.isDeleted,
      status: status ?? this.status,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "unitId": unitId,
      "orgId": orgId,
      "propertyId": propertyId,
      "type": type,
      "name": name,

      // OLD
      "address": address,

      // NEW
      "streetAddress": streetAddress,
      "city": city,
      "state": state,
      "description": description,

      "currentLeaseId": currentLeaseId,
      "bedrooms": bedrooms,
      "bathrooms": bathrooms,
      "sqft": sqft,
      "stallNumber": stallNumber,
      "storageSize": storageSize,
      "garageType": garageType,

      "hasRefrigerator": hasRefrigerator,
      "hasStove": hasStove,
      "hasDishwasher": hasDishwasher,
      "hasMicrowave": hasMicrowave,

      "createdAt": createdAt,
      "isDeleted": isDeleted,
      "status": status,
      "deletedAt": deletedAt,
    };
  }

  factory UnitModel.fromMap(String unitId, Map<String, dynamic> map) {
    return UnitModel(
      unitId: unitId,
      orgId: map["orgId"] ?? "",
      propertyId: map["propertyId"] ?? "",
      type: map["type"] ?? "residential",
      name: map["name"] ?? "",

      // OLD
      address: map["address"] ?? "",

      // NEW — backward compatible
      streetAddress: map["streetAddress"] ?? "",
      city: map["city"] ?? "",
      state: map["state"] ?? "",
      description: map["description"] ?? "",

      currentLeaseId: map["currentLeaseId"],
      bedrooms: map["bedrooms"],
      bathrooms: (map["bathrooms"] is num)
          ? (map["bathrooms"] as num).toDouble()
          : null,
      sqft: (map["sqft"] is num)
          ? (map["sqft"] as num).toDouble()
          : null,
      stallNumber: map["stallNumber"],
      storageSize: map["storageSize"],
      garageType: map["garageType"],

      hasRefrigerator: map["hasRefrigerator"] == true,
      hasStove: map["hasStove"] == true,
      hasDishwasher: map["hasDishwasher"] == true,
      hasMicrowave: map["hasMicrowave"] == true,

      createdAt: map["createdAt"] ?? 0,
      isDeleted: map["isDeleted"] == true,
      status: map["status"] ?? "active",
      deletedAt: map["deletedAt"],
    );
  }
}


class TenantModel {
  final String tenantId;
  final String orgId;
  final String name;
  final String email;
  final String phone;
  final int createdAt;

  final bool isDeleted;
  final String status;
  final String? deletedAt;

  // ⭐ NEW FIELDS
  final String bankName;
  final String accountNumber;
  final String zelleId;
  final String dlImageUrl;

  TenantModel({
    required this.tenantId,
    required this.orgId,
    required this.name,
    required this.email,
    required this.phone,
    required this.createdAt,

    this.isDeleted = false,
    this.status = "active",
    this.deletedAt,

    this.bankName = "",
    this.accountNumber = "",
    this.zelleId = "",
    this.dlImageUrl = "",
  });

  Map<String, dynamic> toMap() {
    return {
      "orgId": orgId,
      "name": name,
      "email": email,
      "phone": phone,
      "createdAt": createdAt,

      "isDeleted": isDeleted,
      "status": status,
      "deletedAt": deletedAt,

      // ⭐ NEW FIELDS
      "bankName": bankName,
      "accountNumber": accountNumber,
      "zelleId": zelleId,
      "dlImageUrl": dlImageUrl,
    };
  }

  factory TenantModel.fromMap(String id, Map<String, dynamic> map) {
    return TenantModel(
      tenantId: id,
      orgId: map["orgId"] ?? "",
      name: map["name"] ?? "",
      email: map["email"] ?? "",
      phone: map["phone"] ?? "",
      createdAt: map["createdAt"] ?? 0,

      isDeleted: map["isDeleted"] == true,
      status: map["status"] ?? "active",
      deletedAt: map["deletedAt"],

      // ⭐ NEW FIELDS
      bankName: map["bankName"] ?? "",
      accountNumber: map["accountNumber"] ?? "",
      zelleId: map["zelleId"] ?? "",
      dlImageUrl: map["dlImageUrl"] ?? "",
    );
  }

  TenantModel copyWith({
    String? tenantId,
    String? orgId,
    String? name,
    String? email,
    String? phone,
    int? createdAt,
    bool? isDeleted,
    String? status,
    String? deletedAt,

    // ⭐ NEW FIELDS
    String? bankName,
    String? accountNumber,
    String? zelleId,
    String? dlImageUrl,
  }) {
    return TenantModel(
      tenantId: tenantId ?? this.tenantId,
      orgId: orgId ?? this.orgId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,

      isDeleted: isDeleted ?? this.isDeleted,
      status: status ?? this.status,
      deletedAt: deletedAt ?? this.deletedAt,

      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      zelleId: zelleId ?? this.zelleId,
      dlImageUrl: dlImageUrl ?? this.dlImageUrl,
    );
  }
}

class LeaseDetailsModel {
  final String leaseId;
  final String orgId;
  final String propertyId;
  final String unitId;

  final List<String> tenantIds;

  /// tenantId → "Lease Holder" or "Occupant"
  final Map<String, String> tenantRoles;

  /// NEW — epoch timestamps instead of strings
  final int startDateEpoch;   // millisecondsSinceEpoch
  final int endDateEpoch;     // millisecondsSinceEpoch

  final double rentAmount;

  /// ⭐ OPTIONAL — rent due day (1–31)
  /// If null → fallback to startDateEpoch day
  final int? rentDueDate;

  // ⭐ NEW FIELDS
  final double securityDeposit;
  final String lateFeeType;
  final double lateFeeAmount;
  final int gracePeriodDays;

  final int createdAt;
  final int updatedAt;

  final String status;

  final bool isDeleted;
  final String? deletedAt;

  // UTILITIES
  final String electricity;
  final String gas;
  final String heat;
  final String water;
  final String trash;
  final String sewer;

  final String? leaseType;  // Yearly || M2M

  LeaseDetailsModel({
    required this.leaseId,
    required this.orgId,
    required this.propertyId,
    required this.unitId,
    required this.tenantIds,

    this.tenantRoles = const {},

    required this.startDateEpoch,
    required this.endDateEpoch,

    required this.rentAmount,

    /// ⭐ OPTIONAL FIELD
    this.rentDueDate,

    this.securityDeposit = 0.0,
    this.lateFeeType = "fixed",
    this.lateFeeAmount = 0.0,
    this.gracePeriodDays = 0,
    required this.createdAt,
    required this.updatedAt,
    this.status = "active",
    this.isDeleted = false,
    this.deletedAt,

    this.electricity = "tenant",
    this.gas = "tenant",
    this.heat = "owner",
    this.water = "owner",
    this.trash = "owner",
    this.sewer = "owner",
    this.leaseType = "Yearly",
  });

  LeaseDetailsModel copyWith({
    String? leaseId,
    String? orgId,
    String? propertyId,
    String? unitId,
    List<String>? tenantIds,
    Map<String, String>? tenantRoles,

    int? startDateEpoch,
    int? endDateEpoch,
    double? rentAmount,

    /// ⭐ OPTIONAL FIELD
    int? rentDueDate,

    double? securityDeposit,
    String? lateFeeType,
    double? lateFeeAmount,
    int? gracePeriodDays,
    int? createdAt,
    int? updatedAt,
    String? status,
    bool? isDeleted,
    String? deletedAt,

    String? electricity,
    String? gas,
    String? heat,
    String? water,
    String? trash,
    String? sewer,
    String? leaseType,
  }) {
    return LeaseDetailsModel(
      leaseId: leaseId ?? this.leaseId,
      orgId: orgId ?? this.orgId,
      propertyId: propertyId ?? this.propertyId,
      unitId: unitId ?? this.unitId,
      tenantIds: tenantIds ?? this.tenantIds,
      tenantRoles: tenantRoles ?? this.tenantRoles,

      startDateEpoch: startDateEpoch ?? this.startDateEpoch,
      endDateEpoch: endDateEpoch ?? this.endDateEpoch,

      rentAmount: rentAmount ?? this.rentAmount,

      /// ⭐ OPTIONAL FIELD
      rentDueDate: rentDueDate ?? this.rentDueDate,

      securityDeposit: securityDeposit ?? this.securityDeposit,
      lateFeeType: lateFeeType ?? this.lateFeeType,
      lateFeeAmount: lateFeeAmount ?? this.lateFeeAmount,
      gracePeriodDays: gracePeriodDays ?? this.gracePeriodDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,

      electricity: electricity ?? this.electricity,
      gas: gas ?? this.gas,
      heat: heat ?? this.heat,
      water: water ?? this.water,
      trash: trash ?? this.trash,
      sewer: sewer ?? this.sewer,
      leaseType: leaseType ?? this.leaseType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "orgId": orgId,
      "propertyId": propertyId,
      "unitId": unitId,
      "tenantIds": tenantIds,
      "tenantRoles": tenantRoles,

      "startDateEpoch": startDateEpoch,
      "endDateEpoch": endDateEpoch,

      "rentAmount": rentAmount,

      /// ⭐ OPTIONAL FIELD
      "rentDueDate": rentDueDate,

      "securityDeposit": securityDeposit,
      "lateFeeType": lateFeeType,
      "lateFeeAmount": lateFeeAmount,
      "gracePeriodDays": gracePeriodDays,

      "createdAt": createdAt,
      "updatedAt": updatedAt,
      "status": status,
      "isDeleted": isDeleted,
      "deletedAt": deletedAt,

      "electricity": electricity,
      "gas": gas,
      "heat": heat,
      "water": water,
      "trash": trash,
      "sewer": sewer,
      "leaseType": leaseType,
    };
  }

  factory LeaseDetailsModel.fromMap(String id, Map<String, dynamic> map) {
    int parseEpoch(dynamic value) {
      if (value is int) return value;
      if (value is String) {
        try {
          return DateTime.parse(value).millisecondsSinceEpoch;
        } catch (_) {
          return DateTime.now().millisecondsSinceEpoch;
        }
      }
      return DateTime.now().millisecondsSinceEpoch;
    }

    final startEpoch = parseEpoch(map["startDateEpoch"] ?? map["startDate"]);

    /// ⭐ Fallback: if rentDueDate is null → use startDateEpoch day
    final fallbackDueDate =
        DateTime.fromMillisecondsSinceEpoch(startEpoch).day;

    return LeaseDetailsModel(
      leaseId: id,
      orgId: map["orgId"] ?? "",
      propertyId: map["propertyId"] ?? "",
      unitId: map["unitId"] ?? "",
      tenantIds: List<String>.from(map["tenantIds"] ?? []),

      tenantRoles: Map<String, String>.from(map["tenantRoles"] ?? {}),

      startDateEpoch: startEpoch,
      endDateEpoch: parseEpoch(map["endDateEpoch"] ?? map["endDate"]),

      rentAmount: (map["rentAmount"] ?? 0).toDouble(),

      /// ⭐ OPTIONAL FIELD WITH FALLBACK
      rentDueDate: map["rentDueDate"] ?? fallbackDueDate,

      securityDeposit: (map["securityDeposit"] ?? 0).toDouble(),
      lateFeeType: map["lateFeeType"] ?? "fixed",
      lateFeeAmount: (map["lateFeeAmount"] ?? 0).toDouble(),
      gracePeriodDays: map["gracePeriodDays"] ?? 0,
      createdAt: map["createdAt"] ?? 0,
      updatedAt: map["updatedAt"] ?? 0,
      status: map["status"] ?? "active",
      isDeleted: map["isDeleted"] == true,
      deletedAt: map["deletedAt"],

      electricity: map["electricity"] ?? "tenant",
      gas: map["gas"] ?? "tenant",
      heat: map["heat"] ?? "owner",
      water: map["water"] ?? "owner",
      trash: map["trash"] ?? "owner",
      sewer: map["sewer"] ?? "owner",
      leaseType: map["leaseType"] ?? "Yearly",
    );
  }
}



class PropertyValuationModel {
  final String valuationId;
  final String propertyId;

  final double? currentValue;
  final double? purchasePrice;
  final String? purchaseDate; // yyyy-mm-dd
  final double? avmValue;
  final double? appraisalValue;

  final int createdAt;
  final int updatedAt;

  PropertyValuationModel({
    required this.valuationId,
    required this.propertyId,
    this.currentValue,
    this.purchasePrice,
    this.purchaseDate,
    this.avmValue,
    this.appraisalValue,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "valuationId": valuationId,
      "propertyId": propertyId,
      "currentValue": currentValue,
      "purchasePrice": purchasePrice,
      "purchaseDate": purchaseDate,
      "avmValue": avmValue,
      "appraisalValue": appraisalValue,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
    };
  }

  factory PropertyValuationModel.fromMap(
      String valuationId, Map<String, dynamic> map) {
    return PropertyValuationModel(
      valuationId: valuationId,
      propertyId: map["propertyId"],
      currentValue: (map["currentValue"] as num?)?.toDouble(),
      purchasePrice: (map["purchasePrice"] as num?)?.toDouble(),
      purchaseDate: map["purchaseDate"],
      avmValue: (map["avmValue"] as num?)?.toDouble(),
      appraisalValue: (map["appraisalValue"] as num?)?.toDouble(),
      createdAt: map["createdAt"] ?? 0,
      updatedAt: map["updatedAt"] ?? 0,
    );
  }

  PropertyValuationModel copyWith({
    double? currentValue,
    double? purchasePrice,
    String? purchaseDate,
    double? avmValue,
    double? appraisalValue,
    int? updatedAt,
  }) {
    return PropertyValuationModel(
      valuationId: valuationId,
      propertyId: propertyId,
      currentValue: currentValue ?? this.currentValue,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      avmValue: avmValue ?? this.avmValue,
      appraisalValue: appraisalValue ?? this.appraisalValue,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
class PropertyTaxModel {
  final String taxId;
  final String propertyId;

  final double? fullYearAmount;
  final String? frequency; // monthly, semi, annual
  final String? dueOn; // yyyy-mm-dd
  final double? installmentAmount;

  final int createdAt;
  final int updatedAt;

  PropertyTaxModel({
    required this.taxId,
    required this.propertyId,
    this.fullYearAmount,
    this.frequency,
    this.dueOn,
    this.installmentAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "taxId": taxId,
      "propertyId": propertyId,
      "fullYearAmount": fullYearAmount,
      "frequency": frequency,
      "dueOn": dueOn,
      "installmentAmount": installmentAmount,

      "createdAt": createdAt,
      "updatedAt": updatedAt,
    };
  }

  factory PropertyTaxModel.fromMap(String taxId, Map<String, dynamic> map) {
    return PropertyTaxModel(
      taxId: taxId,
      propertyId: map["propertyId"],
      fullYearAmount: (map["fullYearAmount"] as num?)?.toDouble(),
      frequency: map["frequency"],
      dueOn: map["dueOn"],
      installmentAmount: (map["installmentAmount"] as num?)?.toDouble(),

      createdAt: map["createdAt"] ?? 0,
      updatedAt: map["updatedAt"] ?? 0,
    );
  }

  PropertyTaxModel copyWith({
    double? fullYearAmount,
    String? frequency,
    String? dueOn,
    double? installmentAmount,
    int? updatedAt,
  }) {
    return PropertyTaxModel(
      taxId: taxId,
      propertyId: propertyId,
      fullYearAmount: fullYearAmount ?? this.fullYearAmount,
      frequency: frequency ?? this.frequency,
      dueOn: dueOn ?? this.dueOn,
      installmentAmount: installmentAmount ?? this.installmentAmount,

      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
class PropertyInsuranceModel {
  final String insuranceId;
  final String propertyId;

  final String? provider;
  final String? dueOn; // yyyy-mm-dd
  final String? frequency; // monthly, annual
  final double? premium;
  final String? policyNumber;

  final int createdAt;
  final int updatedAt;

  PropertyInsuranceModel({
    required this.insuranceId,
    required this.propertyId,
    this.provider,
    this.dueOn,
    this.frequency,
    this.premium,
    this.policyNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "insuranceId": insuranceId,
      "propertyId": propertyId,
      "provider": provider,
      "dueOn": dueOn,
      "frequency": frequency,
      "premium": premium,
      "policyNumber": policyNumber,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
    };
  }

  factory PropertyInsuranceModel.fromMap(
      String insuranceId, Map<String, dynamic> map) {
    return PropertyInsuranceModel(
      insuranceId: insuranceId,
      propertyId: map["propertyId"],
      provider: map["provider"],
      dueOn: map["dueOn"],
      frequency: map["frequency"],
      premium: (map["premium"] as num?)?.toDouble(),
      policyNumber: map["policyNumber"],
      createdAt: map["createdAt"] ?? 0,
      updatedAt: map["updatedAt"] ?? 0,
    );
  }

  PropertyInsuranceModel copyWith({
    String? provider,
    String? dueOn,
    String? frequency,
    double? premium,
    String? policyNumber,
    int? updatedAt,
  }) {
    return PropertyInsuranceModel(
      insuranceId: insuranceId,
      propertyId: propertyId,
      provider: provider ?? this.provider,
      dueOn: dueOn ?? this.dueOn,
      frequency: frequency ?? this.frequency,
      premium: premium ?? this.premium,
      policyNumber: policyNumber ?? this.policyNumber,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class PaymentModel {
  final String paymentId;
  final String orgId;

  final String? propertyId;
  final String? unitId;
  final String? tenantId;

  /// debit = money received
  /// credit = charge (rent, late fee, utility, etc.)
  final String transactionType;

  /// Rent, LateFee, Utility, Deposit, Refund, Adjustment, Other
  final String paymentType;

  final double amount;

  /// BUSINESS DATE — when the charge/payment applies
  final int effectiveDateEpoch;

  /// ACTUAL DATE — when money was actually received (ACH/cash)
  final int actualDateEpoch;

  /// SYSTEM DATE — when the entry was created in the system
  final int recordedAtEpoch;

  /// True if created by rent journal engine
  final bool isSystemGenerated;

  /// Optional note
  final String note;

  /// active | void | pending | archived | deleted
  final String status;

  /// Bitemporal validity window
  final int validFromEpoch;
  final int? validToEpoch;

  /// Soft delete flag
  final bool isDeleted;
  final String? deletedAt;

  PaymentModel({
    required this.paymentId,
    required this.orgId,
    this.propertyId,
    this.unitId,
    this.tenantId,
    required this.transactionType,
    required this.paymentType,
    required this.amount,
    required this.effectiveDateEpoch,
    required this.actualDateEpoch,
    required this.recordedAtEpoch,
    required this.isSystemGenerated,
    this.note = "",
    this.status = "active",
    required this.validFromEpoch,
    this.validToEpoch,
    this.isDeleted = false,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "paymentId": paymentId,
      "orgId": orgId,
      "propertyId": propertyId,
      "unitId": unitId,
      "tenantId": tenantId,
      "transactionType": transactionType,
      "paymentType": paymentType,
      "amount": amount,
      "effectiveDateEpoch": effectiveDateEpoch,
      "actualDateEpoch": actualDateEpoch,
      "recordedAtEpoch": recordedAtEpoch,
      "isSystemGenerated": isSystemGenerated,
      "note": note,
      "status": status,
      "validFromEpoch": validFromEpoch,
      "validToEpoch": validToEpoch,
      "isDeleted": isDeleted,
      "deletedAt": deletedAt,
    };
  }

  factory PaymentModel.fromMap(String id, Map<String, dynamic> map) {
    return PaymentModel(
      paymentId: id,
      orgId: map["orgId"] ?? "",
      propertyId: map["propertyId"],
      unitId: map["unitId"],
      tenantId: map["tenantId"],
      transactionType: map["transactionType"] ?? "debit",
      paymentType: map["paymentType"] ?? "Rent",
      amount: (map["amount"] ?? 0).toDouble(),
      effectiveDateEpoch: map["effectiveDateEpoch"] ?? 0,
      actualDateEpoch: map["actualDateEpoch"] ?? 0,
      recordedAtEpoch: map["recordedAtEpoch"] ?? 0,
      isSystemGenerated: map["isSystemGenerated"] == true,
      note: map["note"] ?? "",
      status: map["status"] ?? "active",
      validFromEpoch: map["validFromEpoch"] ?? 0,
      validToEpoch: map["validToEpoch"],
      isDeleted: map["isDeleted"] == true,
      deletedAt: map["deletedAt"],
    );
  }

  PaymentModel copyWith({
    String? paymentId,
    String? orgId,
    String? propertyId,
    String? unitId,
    String? tenantId,
    String? transactionType,
    String? paymentType,
    double? amount,
    int? effectiveDateEpoch,
    int? actualDateEpoch,
    int? recordedAtEpoch,
    bool? isSystemGenerated,
    String? note,
    String? status,
    int? validFromEpoch,
    int? validToEpoch,
    bool? isDeleted,
    String? deletedAt,
  }) {
    return PaymentModel(
      paymentId: paymentId ?? this.paymentId,
      orgId: orgId ?? this.orgId,
      propertyId: propertyId ?? this.propertyId,
      unitId: unitId ?? this.unitId,
      tenantId: tenantId ?? this.tenantId,
      transactionType: transactionType ?? this.transactionType,
      paymentType: paymentType ?? this.paymentType,
      amount: amount ?? this.amount,
      effectiveDateEpoch: effectiveDateEpoch ?? this.effectiveDateEpoch,
      actualDateEpoch: actualDateEpoch ?? this.actualDateEpoch,
      recordedAtEpoch: recordedAtEpoch ?? this.recordedAtEpoch,
      isSystemGenerated: isSystemGenerated ?? this.isSystemGenerated,
      note: note ?? this.note,
      status: status ?? this.status,
      validFromEpoch: validFromEpoch ?? this.validFromEpoch,
      validToEpoch: validToEpoch ?? this.validToEpoch,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}


class PortfolioModel {
  final String portfolioId;
  final String orgId;

  /// Portfolio name (required)
  final String name;

  /// Multiline description
  final String description;

  /// Optional type (e.g., "residential", "mixed", "commercial")
  final String? type;

  /// Access list: userId → accessLevel (admin, manager, viewer)
  final Map<String, String> access;

  /// Linked bank accounts (Plaid)
  final List<String> bankAccounts;

  /// active | deleted | archived
  final String status;

  final bool isDeleted;
  final String? deletedAt;

  final int createdAt;
  final int updatedAt;

  PortfolioModel({
    required this.portfolioId,
    required this.orgId,
    required this.name,
    required this.description,
    this.type,
    this.access = const {},
    this.bankAccounts = const [],
    this.status = "active",
    this.isDeleted = false,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "portfolioId": portfolioId,
      "orgId": orgId,
      "name": name,
      "description": description,
      "type": type,
      "access": access,
      "bankAccounts": bankAccounts,
      "status": status,
      "isDeleted": isDeleted,
      "deletedAt": deletedAt,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
    };
  }

  factory PortfolioModel.fromMap(String id, Map<String, dynamic> map) {
    return PortfolioModel(
      portfolioId: id,
      orgId: map["orgId"] ?? "",
      name: map["name"] ?? "",
      description: map["description"] ?? "",
      type: map["type"],
      access: Map<String, String>.from(map["access"] ?? {}),
      bankAccounts: List<String>.from(map["bankAccounts"] ?? []),
      status: map["status"] ?? "active",
      isDeleted: map["isDeleted"] == true,
      deletedAt: map["deletedAt"],
      createdAt: map["createdAt"] ?? 0,
      updatedAt: map["updatedAt"] ?? 0,
    );
  }

  PortfolioModel copyWith({
    String? portfolioId,
    String? orgId,
    String? name,
    String? description,
    String? type,
    Map<String, String>? access,
    List<String>? bankAccounts,
    String? status,
    bool? isDeleted,
    String? deletedAt,
    int? createdAt,
    int? updatedAt,
  }) {
    return PortfolioModel(
      portfolioId: portfolioId ?? this.portfolioId,
      orgId: orgId ?? this.orgId,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,

      // ⭐ FIXED
      access: access ?? Map<String, String>.from(this.access),
      bankAccounts: bankAccounts ?? List<String>.from(this.bankAccounts),

      status: status ?? this.status,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,

      createdAt: createdAt ?? this.createdAt,

      // ⭐ Auto-update timestamp
      updatedAt: updatedAt ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

}

class MonthlyLedgerModel {
  final String ledgerId;          // e.g. "unitId_tenantId_2026-09"
  final String orgId;
  final String unitId;
  final String tenantId;

  final int year;
  final int month;

  /// Beginning balance carried from previous month
  final double beginningBalance;

  /// Total charges (Rent, Late Fee, Utility, Past Due, Damage Fee, Other)
  final double charges;

  /// Total payments (money received)
  final double payments;

  /// Total credits (refunds, concessions)
  final double credits;

  /// Ending balance = beginningBalance + charges - payments - credits
  final double endingBalance;

  /// Epoch timestamp when this ledger snapshot was generated
  final int generatedAtEpoch;

  /// Soft delete flags (consistent with other models)
  final bool isDeleted;
  final String? deletedAt;

  MonthlyLedgerModel({
    required this.ledgerId,
    required this.orgId,
    required this.unitId,
    required this.tenantId,
    required this.year,
    required this.month,
    required this.beginningBalance,
    required this.charges,
    required this.payments,
    required this.credits,
    required this.endingBalance,
    required this.generatedAtEpoch,
    this.isDeleted = false,
    this.deletedAt,
  });

  // ------------------------------------------------------------
  // toMap()
  // ------------------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      "ledgerId": ledgerId,
      "orgId": orgId,
      "unitId": unitId,
      "tenantId": tenantId,
      "year": year,
      "month": month,
      "beginningBalance": beginningBalance,
      "charges": charges,
      "payments": payments,
      "credits": credits,
      "endingBalance": endingBalance,
      "generatedAtEpoch": generatedAtEpoch,
      "isDeleted": isDeleted,
      "deletedAt": deletedAt,
    };
  }

  // ------------------------------------------------------------
  // fromMap()
  // ------------------------------------------------------------
  factory MonthlyLedgerModel.fromMap(String ledgerId, Map<String, dynamic> map) {
    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return MonthlyLedgerModel(
      ledgerId: ledgerId,
      orgId: map["orgId"] ?? "",
      unitId: map["unitId"] ?? "",
      tenantId: map["tenantId"] ?? "",
      year: map["year"] ?? 0,
      month: map["month"] ?? 0,
      beginningBalance: parseDouble(map["beginningBalance"]),
      charges: parseDouble(map["charges"]),
      payments: parseDouble(map["payments"]),
      credits: parseDouble(map["credits"]),
      endingBalance: parseDouble(map["endingBalance"]),
      generatedAtEpoch: map["generatedAtEpoch"] ?? 0,
      isDeleted: map["isDeleted"] == true,
      deletedAt: map["deletedAt"],
    );
  }

  // ------------------------------------------------------------
  // copyWith()
  // ------------------------------------------------------------
  MonthlyLedgerModel copyWith({
    String? ledgerId,
    String? orgId,
    String? unitId,
    String? tenantId,
    int? year,
    int? month,
    double? beginningBalance,
    double? charges,
    double? payments,
    double? credits,
    double? endingBalance,
    int? generatedAtEpoch,
    bool? isDeleted,
    String? deletedAt,
  }) {
    return MonthlyLedgerModel(
      ledgerId: ledgerId ?? this.ledgerId,
      orgId: orgId ?? this.orgId,
      unitId: unitId ?? this.unitId,
      tenantId: tenantId ?? this.tenantId,
      year: year ?? this.year,
      month: month ?? this.month,
      beginningBalance: beginningBalance ?? this.beginningBalance,
      charges: charges ?? this.charges,
      payments: payments ?? this.payments,
      credits: credits ?? this.credits,
      endingBalance: endingBalance ?? this.endingBalance,
      generatedAtEpoch: generatedAtEpoch ?? this.generatedAtEpoch,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}


class LinkedBankResult {
  final String accessToken;
  final String itemId;
  final String institutionName;
  final List<BankAccount> accounts;

  LinkedBankResult({
    required this.accessToken,
    required this.itemId,
    required this.institutionName,
    required this.accounts,
  });

  factory LinkedBankResult.fromJson(Map<String, dynamic> json) {
    return LinkedBankResult(
      accessToken: json["access_token"] ?? "",
      itemId: json["item_id"] ?? "",
      institutionName: json["institution_name"] ?? "",
      accounts: (json["accounts"] as List<dynamic>? ?? [])
          .map((a) => BankAccount.fromJson(a))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "access_token": accessToken,
      "item_id": itemId,
      "institution_name": institutionName,
      "accounts": accounts.map((a) => a.toMap()).toList(),
    };
  }
}
class BankAccount {
  final String accountId;     // ⭐ NEW
  final String name;
  final String mask;
  final String type;
  final String subtype;

  BankAccount({
    required this.accountId,
    required this.name,
    required this.mask,
    required this.type,
    required this.subtype,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      accountId: json["account_id"] ?? "",        // ⭐ NEW
      name: json["account_name"] ?? "",
      mask: json["account_mask"] ?? "",
      type: json["account_type"] ?? "",
      subtype: json["account_subtype"] ?? "",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "account_id": accountId,                    // ⭐ NEW
      "account_name": name,
      "account_mask": mask,
      "account_type": type,
      "account_subtype": subtype,
    };
  }
}
class PlaidTransaction {
  final double amount;
  final List<String> category;
  final DateTime date;
  final String merchantName;
  final String name;
  final bool pending;
  final String type;

  PlaidTransaction({
    required this.amount,
    required this.category,
    required this.date,
    required this.merchantName,
    required this.name,
    required this.pending,
    required this.type,
  });

  factory PlaidTransaction.fromMap(Map<String, dynamic> map) {
    return PlaidTransaction(
      amount: (map['amount'] ?? 0).toDouble(),
      category: List<String>.from(map['category'] ?? []),
      date: DateTime.parse(map['date']),
      merchantName: map['merchant_name'] ?? '',
      name: map['name'] ?? '',
      pending: map['pending'] ?? false,
      type: map['type'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'merchant_name': merchantName,
      'name': name,
      'pending': pending,
      'type': type,
    };
  }
}

