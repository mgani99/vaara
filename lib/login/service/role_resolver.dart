import 'package:my_app/login/model/org_user_repository.dart';


class RoleResolver {
  static const List<String> priority = [
    'landlord',
    'manager',
    'contractor',
    'tenant',
  ];

  final OrgUserRepository orgUserRepo;

  RoleResolver({required this.orgUserRepo});

  Future<String> resolveRole({required String orgId, required String userId}) async {
    final orgUser = await orgUserRepo.getOrgUser(orgId, userId);
    if (orgUser == null) return 'tenant';

    if (orgUser.defaultRole != null && orgUser.roles[orgUser.defaultRole!] == true) {
      return orgUser.defaultRole!;
    }

    for (final r in priority) {
      if (orgUser.roles[r] == true) return r;
    }

    return 'tenant';
  }

  Future<Map<String, String>?> chooseBestOrgAndRole(String userId) async {
    final memberships = await orgUserRepo.getMembershipsForUser(userId);
    if (memberships.isEmpty) return null;

    String? bestOrg;
    String? bestRole;
    int bestRank = priority.length + 1;
    int bestUpdatedAt = 0;

    for (final m in memberships) {
      final role = (m.defaultRole != null && m.roles[m.defaultRole!] == true)
          ? m.defaultRole!
          : priority.firstWhere((r) => m.roles[r] == true, orElse: () => 'tenant');

      final rank = priority.indexOf(role);
      if (rank < bestRank || (rank == bestRank && m.updatedAt > bestUpdatedAt)) {
        bestRank = rank;
        bestOrg = m.orgId;
        bestRole = role;
        bestUpdatedAt = m.updatedAt;
      }
    }

    if (bestOrg == null || bestRole == null) return null;
    return {'orgId': bestOrg, 'role': bestRole};
  }
}
