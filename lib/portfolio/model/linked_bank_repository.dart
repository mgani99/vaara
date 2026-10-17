import 'package:firebase_database/firebase_database.dart';
import 'package:my_app/property/domain/property_model.dart';

import '../../finance/view/financial_dashboard_page.dart';

class LinkedBankRepository {
  final DatabaseReference db = FirebaseDatabase.instance.ref();

  // ------------------------------------------------------------
  // SAVE LINKED BANK RESULT (institution + accounts)
  // ------------------------------------------------------------
  Future<void> saveLinkedBankResult({
    required String orgId,
    required String userId,
    required LinkedBankResult result,
  }) async {
    final instPath = "orgs/$orgId/BankLink/$userId/${result.institutionName}";
    final instRef = db.child(instPath);

    // Save institution-level metadata
    await instRef.update({
      "access_token": result.accessToken,
      "item_id": result.itemId,
      "institution_name": result.institutionName,
      "linked_at": DateTime.now().millisecondsSinceEpoch,
      "status": "connected",
    });

    // Save accounts under /accounts/{mask}
    final accountsRef = instRef.child("accounts");

    for (final acct in result.accounts) {
      await accountsRef.child(acct.accountId).set(acct.toMap());
    }
  }

  Future<List<PlaidTransaction>> getMonthlyTransactionsForOrg({
    required String orgId,
    required DateTime month,
  }) async {
    final allTransactions = <PlaidTransaction>[];


    final bankData = await getAllOrgBanks(orgId);

    final monthPrefix =
        '${month.year}${month.month.toString().padLeft(2, '0')}';

    for (final institutionEntry in bankData.entries) {
      final institutionName = institutionEntry.key;

      for (final account in institutionEntry.value) {
        final userId = await findUserIdForAccount(
          orgId: orgId,
          institutionName: institutionName,
          acctId: account.accountId,
        );

        if (userId == null) continue;


        final snapshot = await FirebaseDatabase.instance
            .ref(
          '/orgs/$orgId/'
              'BankLink/$userId/'
              '$institutionName/'
              'accounts/${account.accountId}/daily_transactions/',
        )
            .get();

        if (!snapshot.exists) continue;

        final txDays =
        Map<String, dynamic>.from(snapshot.value as Map);

        for (final dayEntry in txDays.entries) {

          if (!dayEntry.key.startsWith(monthPrefix)) {
            continue;
          }

          final txMap =
          Map<String, dynamic>.from(dayEntry.value);

          for (final tx in txMap.values) {
            final txData = Map<String, dynamic>.from(tx);

            if (txData['type'] == 'removed') {
              continue;
            }

            if (txData['amount'] == null) {
              continue;
            }

            allTransactions.add(
              PlaidTransaction.fromMap(txData),
            );
          }
        }
      }
    }

    allTransactions.sort(
          (a, b) => b.date.compareTo(a.date),
    );

    return allTransactions;
  }

  // ------------------------------------------------------------
  // SAVE DAILY BALANCE FOR AN ACCOUNT
  // ------------------------------------------------------------
  Future<void> saveDailyBalance({
    required String orgId,
    required String institutionName,
    required String userId,
    required String acctId,
    required double balance,
  }) async {
    final today = DateTime.now();
    final dateKey =
        "${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}";

    await db.child(
      "orgs/$orgId/BankLink/$userId/$institutionName/accounts/$acctId/daily_balance/$dateKey",
    ).set(balance);
  }

  // ------------------------------------------------------------
  // FIND USER WHO OWNS THIS ACCOUNT (BY MASK)
  // ------------------------------------------------------------
  Future<String?> findUserIdForAccount({
    required String orgId,
    required String institutionName,
    required String acctId,
  }) async {
    final snap = await db.child("orgs/$orgId/BankLink").get();
    if (!snap.exists) return null;

    for (final userNode in snap.children) {
      final userId = userNode.key!;
      final instNode = userNode.child(institutionName);

      if (!instNode.exists) continue;

      final accountsNode = instNode.child("accounts");
      if (!accountsNode.exists) continue;

      for (final acctNode in accountsNode.children) {
        if (acctNode.key == acctId) {
          return userId; // FOUND THE OWNER
        }
      }
    }

    return null;
  }

  // ------------------------------------------------------------
  // DELETE A SINGLE ACCOUNT (but keep balances + transactions)
  // ------------------------------------------------------------
  Future<void> deleteAccount({
    required String orgId,
    required String userId,
    required String institutionName,
    required String acctId,
  }) async {
    await db.child(
      "orgs/$orgId/BankLink/$userId/$institutionName/accounts/$acctId",
    ).remove();
  }

  Future<void> disconnectBank({
    required String orgId,
    required String userId,
    required String institutionName,
  }) async {
    await db.child("orgs/$orgId/BankLink/$userId/$institutionName").update({
      "access_token": null,
      "cursor" : null,
      "item_id": null,
      "status": "disconnected",
      "disconnectedAt": DateTime.now().toIso8601String(),
    });
  }

  // ------------------------------------------------------------
  // CHECK IF USER HAS LINKED A SPECIFIC BANK
  // ------------------------------------------------------------
  Future<bool> isBankLinked({
    required String orgId,
    required String userId,
    required String institutionName,
  }) async {
    final snap = await db
        .child("orgs/$orgId/BankLink/$userId/$institutionName")
        .get();

    return snap.exists;
  }

  // ------------------------------------------------------------
  // GET DAILY BALANCE FOR AN ACCOUNT
  // ------------------------------------------------------------
  Future<double?> getDailyBalance({
    required String orgId,
    required String userId,
    required String institutionName,
    required String mask,
    required acct_id,
    required String dateKey, // YYYYMMDD
  }) async {
    final snap = await db.child(
      "orgs/$orgId/BankLink/$userId/$institutionName/accounts/$acct_id/daily_balance/$dateKey",
    ).get();

    if (!snap.exists) return null;

    if (snap.value is num) {
      return (snap.value as num).toDouble();
    }

    if (snap.value is Map) {
      final map = Map<String, dynamic>.from(snap.value as Map);
      if (map["current"] is num) {
        return (map["current"] as num).toDouble();
      }
    }

    return null;
  }

  // ------------------------------------------------------------
  // GET ALL INSTITUTIONS LINKED BY USER
  // ------------------------------------------------------------
  Future<List<String>> getLinkedInstitutions({
    required String orgId,
    required String userId,
  }) async {
    final snap = await db.child("orgs/$orgId/BankLink/$userId").get();
    if (!snap.exists) return [];

    return snap.children.map((c) => c.key ?? "").toList();
  }

  // ------------------------------------------------------------
  // GET ALL ACCOUNTS FOR AN INSTITUTION
  // ------------------------------------------------------------
  Future<List<BankAccount>> getAccounts({
    required String orgId,
    required String userId,
    required String institutionName,
  }) async {
    final snap = await db
        .child("orgs/$orgId/BankLink/$userId/$institutionName/accounts")
        .get();

    if (!snap.exists) return [];

    return snap.children.map((c) {
      final data = Map<String, dynamic>.from(c.value as Map);

      return BankAccount.fromJson({
        "account_id": data["account_id"] ?? "",   // ⭐ NEW
        "account_name": data["account_name"],
        "account_mask": data["account_mask"],
        "account_type": data["account_type"],
        "account_subtype": data["account_subtype"],
      });
    }).toList();
  }

  // ------------------------------------------------------------
  // GET SINGLE ACCOUNT BY MASK
  // ------------------------------------------------------------
  Future<BankAccount?> getAccount({
    required String orgId,
    required String userId,
    required String institutionName,
    required String mask,
  }) async {
    final snap = await db.child(
      "orgs/$orgId/BankLink/$userId/$institutionName/accounts/$mask",
    ).get();

    if (!snap.exists) return null;

    final data = Map<String, dynamic>.from(snap.value as Map);

    return BankAccount.fromJson({
      "account_id": data["account_id"] ?? "",     // ⭐ NEW
      "account_name": data["account_name"],
      "account_mask": data["account_mask"],
      "account_type": data["account_type"],
      "account_subtype": data["account_subtype"],
    });
  }

  // ------------------------------------------------------------
  // DELETE LINKED BANK (FULL DELETE)
  // ------------------------------------------------------------
  Future<void> deleteLinkedBank({
    required String orgId,
    required String userId,
    required String institutionName,
  }) async {
    await db.child("orgs/$orgId/BankLink/$userId/$institutionName").remove();
  }

  // ------------------------------------------------------------
  // GET ALL BANKS FOR ORG (MERGED ACROSS USERS)
  // ------------------------------------------------------------
  Future<Map<String, List<BankAccount>>> getAllOrgBanks(String orgId) async {
    final snap = await db.child("orgs/$orgId/BankLink").get();
    if (!snap.exists) return {};

    final result = <String, List<BankAccount>>{};

    for (final userNode in snap.children) {
      final userId = userNode.key ?? "";

      for (final instNode in userNode.children) {
        final institutionName = instNode.key ?? "";

        final status = instNode.child("status").value;
        if (status == "disconnected") continue;

        final accountsSnap = instNode.child("accounts");

        final accounts = accountsSnap.children.map((c) {
          final data = Map<String, dynamic>.from(c.value as Map);

          return BankAccount.fromJson({
            "account_id": data["account_id"] ?? "",   // ⭐ NEW
            "account_name": data["account_name"],
            "account_mask": data["account_mask"],
            "account_type": data["account_type"],
            "account_subtype": data["account_subtype"],
          });
        }).toList();

        if (result.containsKey(institutionName)) {
          result[institutionName]!.addAll(accounts);
        } else {
          result[institutionName] = accounts;
        }
      }
    }

    return result;
  }

  Future<List<PlaidTransaction>> getDailyTransactions({
    required String orgId,
    required String userId,
    required String institutionName,
    required String accountId,
    required String dayKey, // yyyymmdd
  }) async {
    final path =
        "orgs/$orgId/BankLink/$userId/$institutionName/accounts/$accountId/daily_transactions/$dayKey";

    final snapshot = await db.child(path).get();

    if (!snapshot.exists) return [];

    final map = Map<String, dynamic>.from(snapshot.value as Map);

    final List<PlaidTransaction> txList = [];

    map.forEach((txId, txData) {
      final txMap = Map<String, dynamic>.from(txData);
      txList.add(PlaidTransaction.fromMap(txMap));
    });

    return txList;
  }
  Future<FinancialDashboardSummary> buildFinancialDashboardSummary({
    required String orgId,
    required DateTime month,
  }) async {
    final transactions = await getMonthlyTransactionsForOrg(
      orgId: orgId,
      month: month,
    );


    double incomeCategorized = 0;
    double incomeUncategorized = 0;
    int incomeUncategorizedCount = 0;

    double expenseCategorized = 0;
    double expenseUncategorized = 0;
    int expenseUncategorizedCount = 0;

    double debtCategorized = 0;
    double debtUncategorized = 0;
    int debtUncategorizedCount = 0;

    final uncategorizedTransactions = <PlaidTransaction>[];


    for (final tx in transactions) {
      print(
          '${tx.name} '
              'amount=${tx.amount} '
              'date=${tx.date} '
              'category=${tx.category}'
      );
      final amount = tx.amount.abs();

      final hasCategory =
          tx.category.isNotEmpty &&
              tx.category.any((c) => c.trim().isNotEmpty);

      final isDebt = _isDebtTransaction(tx);

      if (isDebt) {
        if (hasCategory) {
          debtCategorized += amount;
        } else {
          debtUncategorized += amount;
          debtUncategorizedCount++;
          uncategorizedTransactions.add(tx);
        }
        continue;
      }

      final isIncome = tx.amount < 0;

      if (isIncome) {
        if (hasCategory) {
          incomeCategorized += amount;
        } else {
          incomeUncategorized += amount;
          incomeUncategorizedCount++;
          uncategorizedTransactions.add(tx);
        }
      } else {
        if (hasCategory) {
          expenseCategorized += amount;
        } else {
          expenseUncategorized += amount;
          expenseUncategorizedCount++;
          uncategorizedTransactions.add(tx);
        }
      }
    }

    return FinancialDashboardSummary(
      incomeCategorized: incomeCategorized,
      incomeUncategorized: incomeUncategorized,
      incomeUncategorizedCount: incomeUncategorizedCount,

      expenseCategorized: expenseCategorized,
      expenseUncategorized: expenseUncategorized,
      expenseUncategorizedCount: expenseUncategorizedCount,

      debtCategorized: debtCategorized,
      debtUncategorized: debtUncategorized,
      debtUncategorizedCount: debtUncategorizedCount,

      uncategorizedTransactions: uncategorizedTransactions,
    );
  }
  bool _isDebtTransaction(PlaidTransaction tx) {
    final categoryText =
    tx.category.join(' ').toLowerCase();

    return categoryText.contains('loan') ||
        categoryText.contains('mortgage') ||
        categoryText.contains('debt') ||
        categoryText.contains('credit');
  }
}
