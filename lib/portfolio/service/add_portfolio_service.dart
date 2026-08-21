import 'package:my_app/login/model/org_user_repository.dart';

class PortfolioService {
  final OrgUserRepository orgUserRepo;

  PortfolioService({required this.orgUserRepo});

  Future<String> createPortfolio({
    required String ownerUserId,
    required String portfolioName,
  }) async {
    return await orgUserRepo.createDefaultOrg(
      ownerUserId: int.parse(ownerUserId),
      orgName: portfolioName,
    );
  }
}
