import 'package:flutter/material.dart';
import 'package:my_app/property/view/lease_creation_screen.dart';
import 'package:my_app/property/view/lease_details_screen.dart';
import 'package:my_app/property/view/multi_family_property_creation.dart';
import 'package:my_app/property/view/property_details_page.dart';
import 'package:my_app/property/view/tenant_creation_page.dart';
import 'package:my_app/property/view/unit_metrics_screen.dart';
import 'package:provider/provider.dart';

// Session + Core
import 'package:my_app/session/app_data.dart';
import 'package:my_app/login/model/org_user_repository.dart';
import 'package:my_app/login/model/invitation_repository.dart';
import 'package:my_app/property/model/unit_repository.dart';
import 'package:my_app/property/model/property_repository.dart';
import 'package:my_app/login/service/role_resolver.dart';

// Login + Auth
import 'package:my_app/login/view/splash_screen.dart';
import 'package:my_app/login/view/login_page.dart';
import 'package:my_app/login/view/password_reset_page.dart';
import 'package:my_app/login/view/enrollment_screen.dart';
import 'package:my_app/login/view/verify_email_page.dart';
import 'package:my_app/login/view/role_selection_page.dart';
import 'package:my_app/login/view/role_switcher_page.dart';

// Home
import 'package:my_app/home/view/home_page.dart';

// Onboarding
import 'package:my_app/onboarding/view/landlord_onboarding.dart';
import 'package:my_app/onboarding/view/contractor_onboarding_screen.dart';
import 'package:my_app/onboarding/view/org_switch_screen.dart';
import 'package:my_app/onboarding/controller/org_switch_controller.dart';
import 'package:my_app/onboarding/service/org_switch_service.dart';

// Tenant Invite
import 'package:my_app/login/view/tenant_invite_screen.dart';
import 'package:my_app/login/controller/tenant_invite_controller.dart';
import 'package:my_app/login/service/tenant_invite_service.dart';

// Property Screens
import 'package:my_app/property/view/property_creation_screen.dart';
import 'package:my_app/property/view/property_dashboard.dart';

import 'package:my_app/property/view/unit_details_screen.dart';
import 'package:my_app/property/view/unit_creation_screen.dart';



// Routes
import 'package:my_app/route/route_constants.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {

  // ------------------------------------------------------------
  // AUTH SCREENS
  // ------------------------------------------------------------
    case splashRoute:
      return MaterialPageRoute(builder: (_) => const SplashScreen());

    case logInScreenRoute:
      return MaterialPageRoute(builder: (_) => const LoginScreen());

    case passwordResetRoute:
      return MaterialPageRoute(builder: (_) => const PasswordResetScreen());

    case enrollmentRoute:
      return MaterialPageRoute(builder: (_) => const EnrollmentScreen());

    case verifyEmailRoute:
      final args = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (_) => VerifyEmailScreen(pending: args),
      );

  // ------------------------------------------------------------
  // ONBOARDING
  // ------------------------------------------------------------
    case roleSelectionRoute:
      return MaterialPageRoute(builder: (_) => const RoleSelectionPage());

    case landlordOnboardingRoute:
      return MaterialPageRoute(builder: (_) => const LandlordOnboardingScreen());

    case contractorOnboardingRoute:
      return MaterialPageRoute(builder: (_) => const ContractorOnboardingScreen());

    case orgSwitcherRoute:
      return MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (context) => OrgSwitcherController(
            service: OrgSwitcherService(
              session: context.read<AppSession>(),
              orgUserRepo: context.read<OrgUserRepository>(),
              roleResolver: context.read<RoleResolver>(),
            ),
          ),
          child: const OrgSwitcherScreen(),
        ),
      );

  // ------------------------------------------------------------
  // PROPERTY SCREENS
  // ------------------------------------------------------------
    case propertyCreationRoute:
      return MaterialPageRoute(builder: (_) => const PropertyCreationScreen());

    case multiFamilyPropertyCreationRoute:
      return MaterialPageRoute(
        builder: (_) => const MultiFamilyPropertyCreationScreen(),
      );

    case propertyDashboardRoute:
      return MaterialPageRoute(builder: (_) => const PropertyDashboard());

    case propertyDetailsRoute:
      final args = settings.arguments as Map<String, dynamic>;
      final propertyId = args["propertyId"] as String;
      final readOnly = args["readOnly"] as bool? ?? false;

      return MaterialPageRoute(
        builder: (_) => PropertyDetailsScreen(
          propertyId: propertyId,
          readOnly: readOnly,
        ),
      );


    case unitDetailsRoute:
      final unitId = settings.arguments as String;
      return MaterialPageRoute(
        builder: (_) => UnitDetailsScreen(unitId: unitId),
      );

    case unitCreationRoute:
      final unitId = settings.arguments as String;

      return MaterialPageRoute(
        builder: (_) => UnitCreationScreen(unitId: unitId),
      );


  // ------------------------------------------------------------
  // LEASE SCREENS
  // ------------------------------------------------------------
    case leaseCreationRoute:
      final args = settings.arguments as Map<String, dynamic>;
      final unitId = args["unitId"];
      final propertyId = args["propertyId"];
      final mode = args["mode"];
      final leaseId = args["leaseId"];

      return MaterialPageRoute(
        builder: (_) => LeaseCreationScreen(
          unitId: unitId,
          propertyId: propertyId,
          leaseId: leaseId,
          mode: mode,
        ),
      );



    case tenantCreationRoute:
      final args = settings.arguments as Map<String, dynamic>;
      final tenantId = args["tenantId"];
      final leaseId = args["leaseId"];
      final mode = args["mode"];

      return MaterialPageRoute(
        builder: (_) => TenantCreationPage(tenantId: tenantId,leaseId:leaseId, mode: mode,),

      );



    case leaseDetailsRoute:
      final leaseId = settings.arguments as String;
      return MaterialPageRoute(
        builder: (_) => LeaseDetailsScreen(leaseId: leaseId),
      );


    case unitMetricsRoute:
      final unitId = settings.arguments as String;
      return MaterialPageRoute(
        builder: (_) => UnitMetricsScreen(unitId: unitId),
      );
  // ------------------------------------------------------------
  // TENANT INVITE
  // ------------------------------------------------------------
    case tenantInviteRoute:
      final invite = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (context) => TenantInviteController(
            service: TenantInviteService(
              session: context.read<AppSession>(),
              inviteRepo: context.read<InvitationRepository>(),
              orgUserRepo: context.read<OrgUserRepository>(),
              unitRepo: context.read<UnitRepository>(),
              propertyRepo: context.read<PropertyRepository>(),
              roleResolver: context.read<RoleResolver>(),
            ),
          ),
          child: TenantInviteScreen(invite: invite),
        ),
      );

  // ------------------------------------------------------------
  // HOME
  // ------------------------------------------------------------
    case homeRoute:
      return MaterialPageRoute(builder: (_) => const HomePage());

  // ------------------------------------------------------------
  // DEFAULT FALLBACK
  // ------------------------------------------------------------
    default:
      return MaterialPageRoute(
        builder: (_) => const Scaffold(
          body: Center(child: Text("Route not found")),
        ),
      );
  }
}
