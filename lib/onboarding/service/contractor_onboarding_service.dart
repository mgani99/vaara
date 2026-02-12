import 'package:my_app/property/model/contractor_repository.dart';
import 'package:my_app/session/app_data.dart';
import 'package:my_app/login/model/org_user_repository.dart';
import 'package:my_app/login/service/role_resolver.dart';
import 'package:my_app/session/user_role.dart';

class ContractorOnboardingService {
  final AppSession session;
  final OrgUserRepository orgUserRepo;
  final ContractorRepository contractorRepo;
  final RoleResolver roleResolver;

  ContractorOnboardingService({
    required this.session,
    required this.orgUserRepo,
    required this.contractorRepo,
    required this.roleResolver,
  });

  Future<void> completeOnboarding({
    required String businessName,
    required String serviceType,
    required String phone,
    String? notes,
  }) async {
    final orgId = session.activeOrgId!;
    final userId = int.parse(session.userId!);

    // 1. Add contractor to org
    await orgUserRepo.addUserToOrg(
      orgId: orgId,
      userId: userId,
      role: "contractor",
    );

    // 2. Create contractor profile
    await contractorRepo.createContractorProfile(
      orgId: orgId,
      userId: userId,
      businessName: businessName,
      serviceType: serviceType,
      phone: phone,
      notes: notes,
    );

    // 3. Resolve and update session role
    final resolvedRole = await roleResolver.resolveRole(
      userId: session.userId!,
      orgId: orgId,
    );

    session.setActiveRole(resolvedRole);
  }
}
