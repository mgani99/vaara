import 'package:flutter/foundation.dart';
import 'package:my_app/login/service/tenant_invite_service.dart';

class TenantInviteController extends ChangeNotifier {
  final TenantInviteService service;

  TenantInviteState state = TenantInviteIdle();

  String? orgName;
  String? propertyName;
  String? unitName;

  TenantInviteController({required this.service});

  Future<void> loadInviteDetails(Map<String, dynamic> invite) async {
    state = TenantInviteLoading();
    notifyListeners();

    try {
      final orgId = invite["orgId"];
      final propertyId = invite["metadata"]["propertyId"];
      final unitId = invite["metadata"]["unitId"];

      orgName = await service.getOrgName(orgId);
      propertyName = await service.getPropertyName(orgId, propertyId);
      unitName = await service.getUnitName(orgId, unitId);

      state = TenantInviteLoaded();
      notifyListeners();
    } catch (e) {
      state = TenantInviteError(e.toString());
      notifyListeners();
    }
  }

  Future<void> accept(Map<String, dynamic> invite) async {
    state = TenantInviteLoading();
    notifyListeners();

    try {
      await service.acceptInvitation(
        inviteId: invite["inviteId"],
        orgId: invite["orgId"],
        propertyId: invite["metadata"]["propertyId"],
        unitId: invite["metadata"]["unitId"],
        roleFromInvite: invite["role"], // <-- FIXED
      );

      state = TenantInviteAccepted();
      notifyListeners();
    } catch (e) {
      state = TenantInviteError(e.toString());
      notifyListeners();
    }
  }

  Future<void> decline(String inviteId) async {
    await service.inviteRepo.deleteInvitation(inviteId);
    state = TenantInviteDeclined();
    notifyListeners();
  }
}

sealed class TenantInviteState {
  const TenantInviteState();
}

class TenantInviteIdle extends TenantInviteState {}
class TenantInviteLoading extends TenantInviteState {}
class TenantInviteLoaded extends TenantInviteState {}
class TenantInviteAccepted extends TenantInviteState {}
class TenantInviteDeclined extends TenantInviteState {}

class TenantInviteError extends TenantInviteState {
  final String message;
  const TenantInviteError(this.message);
}
