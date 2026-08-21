import 'package:my_app/login/model/invitation_repository.dart';
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

  String get _orgId {
    final id = session.activeOrgId;
    if (id == null) {
      throw Exception("No active organization selected.");
    }
    return id;
  }

  int get _now => DateTime.now().millisecondsSinceEpoch;

  // STEP 1: Create Property
  Future<String> createProperty({
    required String name,
    required String address,
    required String type,
  }) async {
    final property = PropertyModel(
      propertyId: "",
      orgId: _orgId,
      name: name.trim(),
      address: address.trim(),
      type: type,
      createdAt: _now, status: '',
    );

    return propertyRepo.createProperty(property);
  }

  // Reusable outside onboarding
  Future<String> addProperty(PropertyModel property) {
    return propertyRepo.createProperty(property);
  }

  // STEP 2: Create Unit (physical space only — no rent, no tenant)
  Future<String> createUnit({
    required String propertyId,
    required String name,
    required int bedrooms,
    required double bathrooms,
    required String type, // unit, studio, parking, garage
  }) async {
    final unit = UnitModel(
      unitId: "",
      orgId: _orgId,
      propertyId: propertyId,
      name: name.trim(),
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      type: type,
      createdAt: _now,
      //updatedAt: _now,
      currentLeaseId: null,
      //status: "active",
    );

    return unitRepo.createUnit(unit);
  }

  // Reusable outside onboarding
  Future<String> addUnit(UnitModel unit) {
    return unitRepo.createUnit(unit);
  }

  // STEP 3: Invite Tenant
  Future<String> inviteTenant({
    required String email,
    required String propertyId,
    required String unitId,
  }) async {
    return inviteRepo.createInvitation(
      orgId: _orgId,
      email: email.trim(),
      role: "tenant",
      metadata: {
        "propertyId": propertyId,
        "unitId": unitId,
      },
    );
  }

  // STEP 4: Invite Co‑Owner / Manager
  Future<String> inviteCoOwner({
    required String email,
    String role = "manager",
  }) async {
    return inviteRepo.createInvitation(
      orgId: _orgId,
      email: email.trim(),
      role: role,
      metadata: null,
    );
  }
}
