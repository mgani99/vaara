import 'package:flutter/material.dart';
import 'package:my_app/onboarding/model/co_owner_invite.dart';
import 'package:my_app/onboarding/service/co_owner_service.dart';
import 'package:my_app/session/app_data.dart';

class OnboardingAddCoOwnersController extends ChangeNotifier {
  final CoOwnerService _service = CoOwnerService();

  bool sending = false;
  final List<CoOwnerInvite> pendingInvites = [];

  Future<void> addCoOwner({
    required AppSession session,
    required String email,
    required double percent,
  }) async {
    sending = true;
    notifyListeners();

    final invite = CoOwnerInvite(
      orgId: session.activeOrgId!,
      invitedEmail: email,
      ownershipPercent: percent,
      invitedBy: session.userId!,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await _service.sendInvite(invite);

    pendingInvites.add(invite);

    sending = false;
    notifyListeners();
  }
}
