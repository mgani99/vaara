import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:my_app/login/model/user_repository.dart';
import 'package:my_app/login/model/invitation_repository.dart';
import 'package:my_app/login/model/org_user_repository.dart';
import 'package:my_app/login/service/role_resolver.dart';
import 'package:my_app/session/app_data.dart';
import 'package:my_app/session/user_role.dart';
import 'package:my_app/route/route_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final auth = FirebaseAuth.instance;
    final session = context.read<AppSession>();
    final userRepo = context.read<UserRepository>();
    final inviteRepo = context.read<InvitationRepository>();
    final orgUserRepo = context.read<OrgUserRepository>();
    final roleResolver = context.read<RoleResolver>();

    // 1. Firebase user
    final firebaseUser = auth.currentUser;
    if (firebaseUser == null) {
      return _goTo(logInScreenRoute);
    }

    await firebaseUser.reload();
    final refreshed = auth.currentUser;
    if (refreshed == null) {
      return _goTo(logInScreenRoute);
    }

    // 2. Email verification
    if (!refreshed.emailVerified) {
      return _goTo(verifyEmailRoute, arguments: {
        "email": refreshed.email,
      });
    }

    // 3. Load ReUser
    final reUser = await userRepo.getByFirebaseUid(refreshed.uid);
    if (reUser == null) {
      return _goTo(enrollmentRoute, arguments: {
        "email": refreshed.email,
        "firebaseUid": refreshed.uid,
      });
    }

    session.setUser(id: reUser.userId.toString(), name: reUser.firstName, email: reUser.email);

    // 4. Invitations
    final invites = await inviteRepo.getInvitationsForEmail(reUser.email);
    if (invites.isNotEmpty) {
      return _goTo(tenantInviteRoute, arguments: invites.first);
    }

    // 5. Org memberships
    final orgIds = await orgUserRepo.getUserOrgs(reUser.userId);
    if (orgIds.isEmpty) {
      return _goTo(roleSelectionRoute);
    }

    session.setOrgMemberships(orgIds);

    // 6. Set active org + role
    final activeOrg = orgIds.first;
    session.setActiveOrg(activeOrg);

    final resolvedRole = await roleResolver.resolveRole(
      userId: session.userId!,
      orgId: activeOrg,
    );

    session.setActiveRole(resolvedRole);

    // 7. Go to home
    return _goTo(homeRoute);
  }

  void _goTo(String route, {Object? arguments}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        route,
            (route) => false,
        arguments: arguments,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
