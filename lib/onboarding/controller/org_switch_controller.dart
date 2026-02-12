import 'package:flutter/foundation.dart';
import 'package:my_app/onboarding/service/org_switch_service.dart';

abstract class OrgSwitcherState {
  const OrgSwitcherState();
}

class OrgSwitcherLoading extends OrgSwitcherState {
  const OrgSwitcherLoading();
}

class OrgSwitcherLoaded extends OrgSwitcherState {
  final List<String> orgIds;
  const OrgSwitcherLoaded(this.orgIds);
}

class OrgSwitcherError extends OrgSwitcherState {
  final String message;
  const OrgSwitcherError(this.message);
}

class OrgSwitcherController extends ChangeNotifier {
  final OrgSwitcherService service;

  OrgSwitcherController({required this.service});

  OrgSwitcherState state = const OrgSwitcherLoading();

  Future<void> load() async {
    state = const OrgSwitcherLoading();
    notifyListeners();

    try {
      final orgIds = await service.loadUserOrgs(); // List<String>
      state = OrgSwitcherLoaded(orgIds);
      notifyListeners();
    } catch (e) {
      state = OrgSwitcherError(e.toString());
      notifyListeners();
    }
  }

  Future<void> selectOrg(String orgId) async {
    await service.switchOrg(orgId);
  }
}

