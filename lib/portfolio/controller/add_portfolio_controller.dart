import 'package:flutter/material.dart';
import 'package:my_app/portfolio/service/add_portfolio_service.dart';
import 'package:my_app/session/app_data.dart';

class AddPortfolioController extends ChangeNotifier {
  final PortfolioService portfolioService;
  final AppSession session;

  AddPortfolioController({
    required this.portfolioService,
    required this.session,
  });

  final TextEditingController nameController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;

  Future<bool> submit() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      errorMessage = "Portfolio name is required";
      notifyListeners();
      return false;
    }

    try {
      isLoading = true;
      notifyListeners();

      final userId = session.user!.userId.toString();

      final newPortfolioId = await portfolioService.createPortfolio(
        ownerUserId: userId,
        portfolioName: name,
      );

      // Refresh org list in session
      final updated = await session.orgUserRepo.getOrgsForUser(userId);
      session.setOrganizations(updated);

      // Set new portfolio as active
      session.setActiveOrg(newPortfolioId);
      session.setActiveOrgName(name);

      session.clearOrgScopedData();

      await session.loadOrgScopedData();
      return true;
    } catch (e) {
      errorMessage = "Failed to create portfolio";
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
