
import 'package:my_app/login/model/invitation_repository.dart';
import 'package:my_app/property/domain/unit_model.dart';
import 'package:my_app/property/model/property_repository.dart';
import 'package:my_app/property/model/unit_repository.dart';
import 'package:my_app/session/app_data.dart';

import '../../property/domain/property_model.dart';

class LandlordOnboardingService {
  final AppSession session;
  final PropertyRepository propertyRepo;
  final UnitRepository unitRepo;
  final InvitationRepository inviteRepo;

  LandlordOnboardingService({
    required this.session,
    required this.propertyRepo,
    required this.unitRepo,
    required this.inviteRepo,
  });

  // ------------------------------------------------------------
  // STEP 1: Create Property
  // ------------------------------------------------------------
  Future<String> createProperty({
    required String name,
    required String address,
    required String type,
  }) async {
    final orgId = session.activeOrgId!;
    final now = DateTime.now().millisecondsSinceEpoch;

    final property = PropertyModel(
      propertyId: "",
      orgId: orgId,
      name: name,
      address: address,
      type: type,
      createdAt: now,
    );

    return propertyRepo.createProperty(property);
  }

  // ------------------------------------------------------------
  // STEP 2: Create Unit
  // ------------------------------------------------------------
  Future<String> createUnit({
    required String propertyId,
    required String name,
    required double rent,
  }) async {
    final orgId = session.activeOrgId!;
    final now = DateTime.now().millisecondsSinceEpoch;

    final unit = UnitModel(
      unitId: "",
      orgId: orgId,
      propertyId: propertyId,
      name: name,
      bedrooms: 0,
      bathrooms: 0,
      rentAmount: rent,
      createdAt: now,
    );

    return unitRepo.createUnit(unit);
  }

  // ------------------------------------------------------------
  // STEP 3: Invite Tenant
  // ------------------------------------------------------------
  Future<String> inviteTenant({
    required String email,
    required String propertyId,
    required String unitId,
  }) async {
    final orgId = session.activeOrgId!;

    return inviteRepo.createInvitation(
      orgId: orgId,
      email: email,
      role: "tenant",
      metadata: {
        "propertyId": propertyId,
        "unitId": unitId,
      },
    );
  }

  // ------------------------------------------------------------
  // STEP 4: Invite Co‑Owner / Manager
  // ------------------------------------------------------------
  Future<String> inviteCoOwner({
    required String email,
    String role = "manager", // or "landlord"
  }) async {
    final orgId = session.activeOrgId!;

    return inviteRepo.createInvitation(
      orgId: orgId,
      email: email,
      role: role,
      metadata: null,
    );
  }
}
