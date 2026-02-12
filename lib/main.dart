import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:my_app/property/model/balance_repository.dart';
import 'package:my_app/property/model/contractor_repository.dart';
import 'package:my_app/property/model/lease_details_repository.dart';
import 'package:my_app/property/model/payment_repository.dart';
import 'package:my_app/property/model/property_repository.dart';
import 'package:my_app/property/model/tenant_repository.dart';
import 'package:my_app/property/model/unit_repository.dart';
import 'package:my_app/property/service/balanace_service.dart';
import 'package:my_app/property/service/lease_details_service.dart';
import 'package:my_app/property/service/payment_service.dart';
import 'package:my_app/property/service/tenant_service.dart';
import 'package:provider/provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:my_app/firebase_options.dart';
import 'package:my_app/theme/app_theme.dart';
import 'package:my_app/route/router.dart' as router;
import 'package:my_app/route/route_constants.dart';

// ------------------------------------------------------------
// SESSION
// ------------------------------------------------------------
import 'package:my_app/session/app_data.dart';

// ------------------------------------------------------------
// LOGIN + AUTH
// ------------------------------------------------------------
import 'package:my_app/login/controller/login_controller.dart';
import 'package:my_app/login/controller/enroll_controller.dart';
import 'package:my_app/login/controller/passord_reset_controller.dart';
import 'package:my_app/login/controller/verify_email_controller.dart';
import 'package:my_app/login/service/auth_service.dart';
import 'package:my_app/login/service/role_resolver.dart';
import 'package:my_app/login/model/user_repository.dart';
import 'package:my_app/login/model/org_user_repository.dart';
import 'package:my_app/login/model/invitation_repository.dart';

// ------------------------------------------------------------
// ONBOARDING SERVICES
// ------------------------------------------------------------
import 'package:my_app/onboarding/service/address_lookup_service.dart';
import 'package:my_app/onboarding/service/landlord_onboarding_service.dart';
import 'package:my_app/onboarding/service/contractor_onboarding_service.dart';

// ------------------------------------------------------------
// PROPERTY + UNIT (NEW CLEAN ARCHITECTURE)
// ------------------------------------------------------------


class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseDatabase.instance.ref();

    FlutterError.onError = (FlutterErrorDetails details) {
      print("🔥 FlutterError: ${details.exception}");
      print("🔥 Stack trace: ${details.stack}");
    };

    return MultiProvider(
      providers: [
        // ------------------------------------------------------------
        // SESSION (must be first)
        // ------------------------------------------------------------
        ChangeNotifierProvider(create: (_) => AppSession()),

        // ------------------------------------------------------------
        // ONBOARDING HELPERS
        // ------------------------------------------------------------
        Provider(create: (_) => AddressLookupService()),

        // ------------------------------------------------------------
        // CORE REPOSITORIES
        // ------------------------------------------------------------
        Provider(create: (_) => UserRepository()),
        Provider(create: (_) => OrgUserRepository()),
        Provider(create: (_) => InvitationRepository()),

        // NEW CLEAN ARCHITECTURE REPOS
        Provider(create: (_) => PropertyRepository()),
        Provider(create: (_) => UnitRepository()),


        // ------------------------------------------------------------
        // ROLE RESOLVER
        // ------------------------------------------------------------
// ------------------------------------------------------------
// ROLE RESOLVER
// ------------------------------------------------------------
        Provider(
          create: (_) => RoleResolver(),
        ),

        // ------------------------------------------------------------
        // AUTH SERVICE
        // ------------------------------------------------------------
        Provider(
          create: (context) => AuthService(
            auth: FirebaseAuth.instance,
            userRepo: context.read<UserRepository>(),
            orgUserRepo: context.read<OrgUserRepository>(),
            session: context.read<AppSession>(),
            roleResolver: context.read<RoleResolver>(), contractorRepo: context.read<ContractorRepository>(),
          ),
        ),

// ------------------------------------------------------------
// DOMAIN REPOSITORIES
// ------------------------------------------------------------
        Provider(create: (_) => PropertyRepository()),
        Provider(create: (_) => UnitRepository()),
        Provider(create: (_) => TenantRepository()),
        Provider(create: (_) => LeaseDetailsRepository()),
        Provider(create: (_) => PaymentRepository()),
        Provider(create: (_) => BalanceRepository()),

// ------------------------------------------------------------
// DOMAIN SERVICES
// ------------------------------------------------------------
        Provider(
          create: (context) => TenantService(
            repo: context.read<TenantRepository>(),
          ),
        ),

        Provider(
          create: (context) => LeaseDetailsService(
            repo: context.read<LeaseDetailsRepository>(),
          ),
        ),

        Provider(
          create: (context) => PaymentService(
            paymentRepo: context.read<PaymentRepository>(),
            balanceRepo: context.read<BalanceRepository>(),
          ),
        ),

        Provider(
          create: (context) => BalanceService(
            repo: context.read<BalanceRepository>(),
          ),
        ),

        // ------------------------------------------------------------
        // LOGIN CONTROLLERS
        // ------------------------------------------------------------
        ChangeNotifierProvider(
          create: (context) => LoginController(
            auth: FirebaseAuth.instance,
            userRepo: context.read<UserRepository>(),
            session: context.read<AppSession>(),
          ),
        ),

        ChangeNotifierProvider(
          create: (context) => EnrollmentController(
            userRepo: context.read<UserRepository>(),
            orgUserRepo: context.read<OrgUserRepository>(),
            roleResolver: context.read<RoleResolver>(),
            session: context.read<AppSession>(),
          ),
        ),

        ChangeNotifierProvider(
          create: (_) => VerifyEmailController(
            auth: FirebaseAuth.instance,
          ),
        ),

        ChangeNotifierProvider(
          create: (_) => PasswordResetController(
            FirebaseAuth.instance,
          ),
        ),

        // ------------------------------------------------------------
        // ONBOARDING SERVICES (NEW CLEAN ARCHITECTURE)
        // ------------------------------------------------------------
        Provider(
          create: (context) => LandlordOnboardingService(
            session: context.read<AppSession>(),
            propertyRepo: context.read<PropertyRepository>(),
            unitRepo: context.read<UnitRepository>(),
            inviteRepo: context.read<InvitationRepository>(),
          ),
        ),

        Provider(
          create: (context) => ContractorOnboardingService(
            session: context.read<AppSession>(),
            orgUserRepo: context.read<OrgUserRepository>(),
            roleResolver: context.read<RoleResolver>(),
            contractorRepo: context.read<ContractorRepository>(),
          ),
        ),
      ],

      // ------------------------------------------------------------
      // APP ROOT
      // ------------------------------------------------------------
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Rental.AI',
        theme: AppTheme.lightTheme(context),
        scrollBehavior: MyCustomScrollBehavior(),
        initialRoute: splashRoute,
        onGenerateRoute: router.generateRoute,
      ),
    );
  }
}



