import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:my_app/login/model/user_repository.dart';
import 'package:my_app/login/model/invitation_repository.dart';
import 'package:my_app/login/model/org_user_repository.dart';
import 'package:my_app/login/service/role_resolver.dart';
import 'package:my_app/session/app_data.dart';
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
    final prefsRepo = context.read<UserPreferencesRepository>();

    // ------------------------------------------------------------
    // 1. Firebase user
    // ------------------------------------------------------------
    final firebaseUser = auth.currentUser;
    if (firebaseUser == null) return _goTo(logInScreenRoute);

    await firebaseUser.reload();
    final refreshed = auth.currentUser;
    if (refreshed == null) return _goTo(logInScreenRoute);

    // ------------------------------------------------------------
    // 2. Email verification
    // ------------------------------------------------------------
    if (!refreshed.emailVerified) {
      return _goTo(
        verifyEmailRoute,
        arguments: {"email": refreshed.email},
      );
    }

    // ------------------------------------------------------------
    // 3. Load ReUser
    // ------------------------------------------------------------
    final reUserMap = await userRepo.getUserByFirebaseUid(refreshed.uid);
    if (reUserMap == null) {
      return _goTo(
        enrollmentRoute,
        arguments: {
          "email": refreshed.email,
          "firebaseUid": refreshed.uid,
        },
      );
    }

    final reUser = reUserMap;
    session.setUser(reUser);

    // ------------------------------------------------------------
    // 4. Invitations
    // ------------------------------------------------------------
    final invites = await inviteRepo.getInvitationsForEmail(reUser.email);
    if (invites.isNotEmpty) {
      return _goTo(tenantInviteRoute, arguments: invites.first);
    }

    // ------------------------------------------------------------
    // 5. Load all orgs for dropdown
    // ------------------------------------------------------------
    final orgs = await orgUserRepo.getOrgsForUser(reUser.userId.toString());
    session.setOrganizations(orgs);

    if (orgs.isEmpty) {
      return _goTo(roleSelectionRoute);
    }

    // ------------------------------------------------------------
    // 6. Resolve active org + role
    // ------------------------------------------------------------
    final prefs = await prefsRepo.getPreferences(reUser.userId.toString());

    if (prefs?.defaultOrgId != null) {
      final orgId = prefs!.defaultOrgId!;
      final orgUser = await orgUserRepo.getOrgUser(orgId, reUser.userId.toString());
      final orgName = await orgUserRepo.getOrgName(orgId);

      if (orgUser != null) {
        final role = await roleResolver.resolveRole(
          userId: reUser.userId.toString(),
          orgId: orgId,
        );
        //session.loadOrgScopedData();
        session.setActiveOrg(orgId);
        session.setActiveOrgName(orgName);
        session.setActiveRole(role);

        return _goTo(homeRoute);
      }
    }

    // Fallback: choose best org + role
    final best = await roleResolver.chooseBestOrgAndRole(
      reUser.userId.toString(),
    );

    if (best != null) {
      final orgId = best['orgId']!;
      final role = best['role']!;
      final orgName = await orgUserRepo.getOrgName(orgId);
      //session.loadOrgScopedData();
      session.setActiveOrg(orgId);
      session.setActiveOrgName(orgName);
      session.setActiveRole(role);

      await prefsRepo.setDefaultOrg(reUser.userId.toString(), orgId);

      return _goTo(homeRoute);
    }

    return _goTo(roleSelectionRoute);
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
