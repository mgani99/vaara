import 'package:firebase_database/firebase_database.dart';

import '../../property/domain/property_model.dart';


class PortfolioRepository {
  final _db = FirebaseDatabase.instance.ref();

  // ------------------------------------------------------------
  // Fetch all portfolios (filters deleted)
  // ------------------------------------------------------------
  Future<List<PortfolioModel>> fetchPortfolios(String orgId) async {
    final snapshot = await _db.child("orgs/$orgId/Portfolios").get();
    if (!snapshot.exists) return [];

    return snapshot.children
        .map((child) {
      final map = Map<String, dynamic>.from(child.value as Map);
      return PortfolioModel.fromMap(child.key!, map);
    })
        .where((p) =>
    p.isDeleted != true &&
        p.status != "deleted" &&
        p.status != "archived")
        .toList();
  }

  // ------------------------------------------------------------
  // Get portfolio by ID
  // ------------------------------------------------------------
  Future<PortfolioModel?> getPortfolio(String orgId) async {
    final snapshot =
    await _db.child("orgs/$orgId").get();

    if (!snapshot.exists) {
      print("snapshot doesn't exist");
      return null;
    }

    final map = Map<String, dynamic>.from(snapshot.value as Map);
    final model = PortfolioModel.fromMap(orgId, map);


    print(model);
    if (model.isDeleted == true) return null;
    if (model.status == "deleted") return null;
    if (model.status == "archived") return null;

    return model;
  }

  // ------------------------------------------------------------
  // Create portfolio
  // ------------------------------------------------------------
  Future<String> createPortfolio(PortfolioModel model) async {
    final ref = _db.child("orgs/${model.orgId}/Portfolios").push();
    await ref.set(model.toMap());
    return ref.key!;
  }

  // ------------------------------------------------------------
  // Update portfolio
  // ------------------------------------------------------------
  Future<void> updatePortfolio(String orgId, PortfolioModel model) async {
    await _db
        .child("orgs/$orgId")
        .update(model.toMap());
  }

  // ------------------------------------------------------------
  // Soft delete portfolio
  // ------------------------------------------------------------
  Future<void> deletePortfolio(String orgId, String portfolioId) async {
    final ref = _db.child("orgs/$orgId/Portfolios/$portfolioId");

    await ref.update({
      "status": "deleted",
      "isDeleted": true,
      "deletedAt": DateTime.now().toIso8601String(),
    });
  }

  // ------------------------------------------------------------
  // Add bank account (Plaid)
  // ------------------------------------------------------------
  Future<void> addBankAccount(
      String orgId, String portfolioId, String accountName) async {
    final snapshot =
    await _db.child("orgs/$orgId/Portfolios/$portfolioId/bankAccounts").get();

    List<String> accounts = [];
    if (snapshot.exists) {
      accounts = List<String>.from(snapshot.value as List);
    }

    accounts.add(accountName);

    await _db
        .child("orgs/$orgId/Portfolios/$portfolioId/bankAccounts")
        .set(accounts);
  }

  // ------------------------------------------------------------
  // Update access list
  // ------------------------------------------------------------
  Future<void> updateAccess(
      String orgId, String portfolioId, Map<String, String> access) async {
    await _db
        .child("orgs/$orgId/Portfolios/$portfolioId/access")
        .set(access);
  }
}
