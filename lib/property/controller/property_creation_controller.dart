import 'package:flutter/material.dart';
import 'package:my_app/property/domain/property_type.dart';

import 'package:my_app/property/service/lease_details_service.dart';
import 'package:my_app/property/service/property_service.dart';
import 'package:my_app/property/service/tenant_service.dart';
import 'package:my_app/property/service/unit_service.dart';
import 'package:my_app/session/app_data.dart';

import '../domain/property_model.dart';


class PropertyCreationController extends ChangeNotifier {
  final PropertyService service;
  final UnitService unitService;
  final LeaseDetailsService ldService;
  final TenantService tenantService;

  bool saving = false;


  PropertyCreationController({
  required this.service,
  required this.unitService,
  required this.ldService,
  required this.tenantService,});

  Future<String> createProperty({
    required AppSession session,
    required String name,
    required String address,
    required String type,
    int? numUnits,
    double? sqft,
    String? buildingType,
    double? rent,
    String? tenantName,
    String? tenantEmail,
    String? city,
    String? state
  })
  async {
    saving = true;
    notifyListeners();
    String propId = "";

    try {
        propId = await service.createProperty(
        session: session,
        name: name,
        address: address,
        city: city,
        state: state,
        type: type,
        numUnits: numUnits,
        sqft: sqft,
        rent: rent,
      );
        final orgId = session.activeOrgId!;
        final createdTime = DateTime.now().millisecondsSinceEpoch;

      if (type == mapPropertyType(PropertyType.sfm)) {


        final unit = UnitModel(
          unitId: "", // repo generates this
          orgId: orgId,
          propertyId: propId,
          type: "Apartment",
          name: "$name - Main Unit",
          //bedrooms: bedrooms,
          //bathrooms: bathrooms,
          sqft: sqft,
          //stallNumber: stallNumber,
          //storageSize: storageSize,
          //garageType: garageType,
          createdAt: createdTime,
        );
        final unitModel = await unitService.createUnit(orgId, unit);
        if (rent != null) {
          final lease = LeaseDetailsModel(
              leaseId: '',
              propertyId: propId,
              unitId: unitModel.unitId,
              tenantIds: [],
              startDateEpoch: 0,

              endDateEpoch: 0,
              rentAmount: rent,
              createdAt: createdTime,
              updatedAt: createdTime,
              orgId: orgId


          );
          final newLease = await ldService.createLease(orgId, lease);
          await unitService.repo.updateUnitField(orgId: orgId,
              unitId: unitModel.unitId,
              field: "currentLeaseId",
              value: newLease.leaseId);


          if (tenantName != null && tenantEmail != null) {
            final tenant = TenantModel(tenantId: "",
                orgId: orgId,
                name: tenantName,
                email: tenantEmail,
                phone: "",
                createdAt: createdTime);
            final tenantId = await tenantService.createTenant(tenant);
            ldService.repo.updateLeaseField(orgId: orgId,
                leaseId: newLease.leaseId,
                field: "tenantIds",
                value: [tenantId]);
          }
        }
      }
      else {
        final totalUnits = numUnits ?? 0;

        for (int i = 1; i <= totalUnits; i++) {
          final unit = UnitModel(
            unitId: "",
            orgId: orgId,
            propertyId: propId,
            type: "Apartment",
            name: "$name - Unit $i",
            sqft: sqft,
            createdAt: createdTime,
          );

          final unitModel = await unitService.createUnit(orgId, unit);

          // Optional: auto-create leases for MF/Commercial if rent is provided
          if (rent != null) {
            final lease = LeaseDetailsModel(
              leaseId: '',
              propertyId: propId,
              unitId: unitModel.unitId,
              tenantIds: [],
              startDateEpoch: 0,
              endDateEpoch: 0,
              rentAmount: rent,
              createdAt: createdTime,
              updatedAt: createdTime,
              orgId: orgId,
            );

            final newLease = await ldService.createLease(orgId, lease);

            await unitService.repo.updateUnitField(
              orgId: orgId,
              unitId: unitModel.unitId,
              field: "currentLeaseId",
              value: newLease.leaseId,
            );
          }
        }
      }
    } finally {
      saving = false;
      notifyListeners();
      return propId;
    }
  }
}
