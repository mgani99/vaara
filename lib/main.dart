import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:my_app/model/property.dart';
import 'package:my_app/payments/repository/payment_repository.dart';
import 'package:my_app/payments/service/payment_service.dart';
import 'package:my_app/portfolio/controller/add_portfolio_controller.dart';
import 'package:my_app/portfolio/model/portfolio_repository.dart';
import 'package:my_app/portfolio/service/add_portfolio_service.dart';
import 'package:my_app/property/controller/property_creation_controller.dart';
import 'package:my_app/property/model/property_archive_restore_service.dart';
import 'package:my_app/property/service/property_service.dart';
import 'package:my_app/property/service/unit_service.dart';
import 'package:provider/provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:my_app/firebase_options.dart';

import 'package:my_app/theme/app_theme.dart';
import 'package:my_app/route/router.dart' as router;
import 'package:my_app/route/route_constants.dart';

// SESSION
import 'package:my_app/session/app_data.dart';


// LOGIN + AUTH
import 'package:my_app/login/controller/login_controller.dart';
import 'package:my_app/login/controller/enroll_controller.dart';
import 'package:my_app/login/controller/passord_reset_controller.dart';
import 'package:my_app/login/controller/verify_email_controller.dart';
import 'package:my_app/login/service/auth_service.dart';
import 'package:my_app/login/service/role_resolver.dart';
import 'package:my_app/login/model/user_repository.dart';
import 'package:my_app/login/model/org_user_repository.dart';
import 'package:my_app/login/model/invitation_repository.dart';

// PROFILE
import 'package:my_app/profile/model/profile_repository.dart';
import 'package:my_app/profile/service/profile_service.dart';
import 'package:my_app/profile/controller/profile_controller.dart';

// ONBOARDING
import 'package:my_app/onboarding/service/address_lookup_service.dart';
import 'package:my_app/onboarding/service/landlord_onboarding_service.dart';
import 'package:my_app/onboarding/service/contractor_onboarding_service.dart';

// PROPERTY DOMAIN
import 'package:my_app/property/model/property_repository.dart';
import 'package:my_app/property/model/unit_repository.dart';
import 'package:my_app/property/model/tenant_repository.dart';
import 'package:my_app/property/model/lease_details_repository.dart';
import 'package:my_app/property/model/balance_repository.dart';
import 'package:my_app/property/model/contractor_repository.dart';

import 'package:my_app/property/service/tenant_service.dart';
import 'package:my_app/property/service/lease_details_service.dart';
import 'package:my_app/property/service/balanace_service.dart';


// NAVBAR
import 'home/controller/navbar_controller.dart';
import 'services/storage_upload_service.dart';

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

    return MultiProvider(
      providers: [
        // ------------------------------------------------------------
        // CORE REPOSITORIES
        // ------------------------------------------------------------
        Provider(create: (_) => UserRepository()),
        Provider(create: (_) => OrgUserRepository()),
        Provider(create: (_) => InvitationRepository()),
        Provider(create: (_) => ContractorRepository()),
        Provider(create: (_) => UserPreferencesRepository()),

        // PROPERTY REPOSITORIES
        Provider(create: (_) => PropertyRepository()),
        Provider(create: (_) => UnitRepository()),
        Provider(create: (_) => TenantRepository()),
        Provider(create: (_) => LeaseDetailsRepository()),
        Provider(create: (_) => PaymentRepository()),
        Provider(create: (_) => BalanceRepository()),
        Provider(create: (_) => PropertyArchiveService(db)),
        Provider(create: (_) => PortfolioRepository()),



        // PROFILE REPOSITORY
        Provider(create: (_) => ProfileRepository(db: db)),

        // ------------------------------------------------------------
        // HELPERS
        // ------------------------------------------------------------
        Provider(
          create: (context) => RoleResolver(
            orgUserRepo: context.read<OrgUserRepository>(),
          ),
        ),
        Provider(create: (_) => AddressLookupService()),

        // ------------------------------------------------------------
        // SESSION (depends on RoleResolver + OrgUserRepo + UserPreferencesRepo)
        // ------------------------------------------------------------
        ChangeNotifierProvider(
          create: (context) => AppSession(
            roleResolver: context.read<RoleResolver>(),
            orgUserRepo: context.read<OrgUserRepository>(),
            prefsRepo: context.read<UserPreferencesRepository>(),
            propertyRepo: context.read<PropertyRepository>(),
            unitRepo: context.read<UnitRepository>(),
            leaseRepo: context.read<LeaseDetailsRepository>(),
            tenantRepo: context.read<TenantRepository>(),
            paymentRepo: context.read<PaymentRepository>(),



          ),
        ),
// ------------------------------------------------------------
// SERVICES
// ------------------------------------------------------------

// MUST come before TenantService
        Provider(create: (_) => StorageUploadService()),

        Provider(
          create: (context) => AuthService(
            auth: FirebaseAuth.instance,
            userRepo: context.read<UserRepository>(),
            orgUserRepo: context.read<OrgUserRepository>(),
            contractorRepo: context.read<ContractorRepository>(),
            roleResolver: context.read<RoleResolver>(),
            prefsRepo: context.read<UserPreferencesRepository>(),
            session: context.read<AppSession>(),
          ),
        ),

        Provider(
          create: (context) => TenantService(
            repo: context.read<TenantRepository>(),
            inviteRepo: context.read<InvitationRepository>(),
            storage: context.read<StorageUploadService>(),   // now valid
          ),
        ),

        Provider(
          create: (context) => PaymentService(
            paymentRepo: context.read<PaymentRepository>(),
            balanceRepo: context.read<BalanceRepository>(),
          ),
        ),

        Provider(
          create: (context) => PropertyArchiveService(
            FirebaseDatabase.instance.ref(),
          ),
        ),

        Provider(
          create: (context) => BalanceService(
            repo: context.read<BalanceRepository>(),
          ),
        ),

        Provider(
          create: (context) => ProfileService(
            repo: context.read<ProfileRepository>(),
          ),
        ),

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

// ------------------------------------------------------------
// PROPERTY SERVICES
// ------------------------------------------------------------
        Provider(
          create: (context) => PropertyService(
            repo: context.read<PropertyRepository>(),
            session: context.read<AppSession>(),
          ),
        ),

        Provider(
          create: (context) => UnitService(
            repo: context.read<UnitRepository>(),
            session: context.read<AppSession>(),
          ),
        ),

        Provider(
          create: (context) => LeaseDetailsService(
            repo: context.read<LeaseDetailsRepository>(),
            session: context.read<AppSession>(),
          ),
        ),

// ------------------------------------------------------------
// CONTROLLERS
// ------------------------------------------------------------
        ChangeNotifierProvider(
          create: (context) => PropertyCreationController(
            service: context.read<PropertyService>(),
            ldService: context.read<LeaseDetailsService>(),
            unitService: context.read<UnitService>(),
            tenantService: context.read<TenantService>(),   // FIXED
          ),
        ),


        // ------------------------------------------------------------
        // CONTROLLERS
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
            prefsRepo: context.read<UserPreferencesRepository>(),
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

        ChangeNotifierProvider(
          create: (context) => ProfileController(
            profileService: context.read<ProfileService>(),
            orgUserRepo: context.read<OrgUserRepository>(),
            authService: context.read<AuthService>(),
          ),
        ),

        ChangeNotifierProvider(
          create: (_) => NavBarController(),
        ),

        ChangeNotifierProvider(
          create: (context) => AddPortfolioController(
            portfolioService: PortfolioService(
              orgUserRepo: context.read<OrgUserRepository>(),
            ),
            session: context.read<AppSession>(),
          ),
        ),

      ],

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
