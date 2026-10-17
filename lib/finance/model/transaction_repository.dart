import 'package:firebase_database/firebase_database.dart';
import '../../property/domain/property_model.dart';

class TransactionRepository {
  final DatabaseReference db =
  FirebaseDatabase.instance.ref();

  String _path(String orgId) =>
      'orgs/$orgId/financial/transactions';

  // ==========================================================
  // CREATE
  // ==========================================================

  Future<void> saveTransaction({
    required String orgId,
    required ReappTransaction transaction,
  }) async {
    await db
        .child(
      '${_path(orgId)}/${transaction.id}',
    )
        .set(
      transaction.toMap(),
    );
  }

  Future<String> createTransaction({
    required String orgId,
    required double amount,
    required DateTime transactionDate,
    required String category,
    required String type,
    required String plaidTransactionId,
  }) async {
    final ref =
    db.child(_path(orgId)).push();

    final id = ref.key!;

    final transaction =
    ReappTransaction(
      id: id,
      amount: amount,
      transactionDate:
      transactionDate,
      category: category,
      type: type,
      plaidTransactionId:
      plaidTransactionId,
    );

    await ref.set(
      transaction.toMap(),
    );

    return id;
  }

  // ==========================================================
  // READ
  // ==========================================================

  Future<ReappTransaction?> getTransaction({
    required String orgId,
    required String transactionId,
  }) async {
    final snapshot = await db
        .child(
      '${_path(orgId)}/$transactionId',
    )
        .get();

    if (!snapshot.exists) {
      return null;
    }

    return ReappTransaction.fromMap(
      Map<String, dynamic>.from(
        snapshot.value as Map,
      ),
    );
  }

  Future<List<ReappTransaction>>
  getAllTransactions({
    required String orgId,
  }) async {
    final snapshot = await db
        .child(
      _path(orgId),
    )
        .get();

    if (!snapshot.exists) {
      return [];
    }

    final results =
    <ReappTransaction>[];

    for (final child
    in snapshot.children) {
      results.add(
        ReappTransaction.fromMap(
          Map<String, dynamic>.from(
            child.value as Map,
          ),
        ),
      );
    }

    results.sort(
          (a, b) =>
          b.transactionDate.compareTo(
            a.transactionDate,
          ),
    );

    return results;
  }

  Future<List<ReappTransaction>>
  getTransactionsForMonth({
    required String orgId,
    required DateTime month,
  }) async {
    final all =
    await getAllTransactions(
      orgId: orgId,
    );

    return all.where((tx) {
      return tx.transactionDate.year ==
          month.year &&
          tx.transactionDate.month ==
              month.month;
    }).toList();
  }

  Future<List<ReappTransaction>>
  getTransactionsByCategory({
    required String orgId,
    required String category,
    required DateTime month,
  }) async {
    final monthly =
    await getTransactionsForMonth(
      orgId: orgId,
      month: month,
    );

    return monthly.where((tx) {
      return tx.category
          .toLowerCase() ==
          category.toLowerCase();
    }).toList();
  }

  Future<List<ReappTransaction>>
  getTransactionsByType({
    required String orgId,
    required String type,
    required DateTime month,
  }) async {
    final monthly =
    await getTransactionsForMonth(
      orgId: orgId,
      month: month,
    );

    return monthly.where((tx) {
      return tx.type.toLowerCase() ==
          type.toLowerCase();
    }).toList();
  }

  Future<ReappTransaction?>
  getByPlaidTransactionId({
    required String orgId,
    required String plaidTransactionId,
  }) async {
    final transactions =
    await getAllTransactions(
      orgId: orgId,
    );

    try {
      return transactions.firstWhere(
            (tx) =>
        tx.plaidTransactionId ==
            plaidTransactionId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool>
  isPlaidTransactionCategorized({
    required String orgId,
    required String plaidTransactionId,
  }) async {
    final tx =
    await getByPlaidTransactionId(
      orgId: orgId,
      plaidTransactionId:
      plaidTransactionId,
    );

    return tx != null;
  }

  // ==========================================================
  // UPDATE
  // ==========================================================

  Future<void> updateTransaction({
    required String orgId,
    required ReappTransaction transaction,
  }) async {
    await db
        .child(
      '${_path(orgId)}/${transaction.id}',
    )
        .update(
      transaction.toMap(),
    );
  }

  Future<void> updateCategory({
    required String orgId,
    required String transactionId,
    required String category,
  }) async {
    await db
        .child(
      '${_path(orgId)}/$transactionId',
    )
        .update({
      'category': category,
    });
  }

  // ==========================================================
  // DELETE
  // ==========================================================

  Future<void> deleteTransaction({
    required String orgId,
    required String transactionId,
  }) async {
    await db
        .child(
      '${_path(orgId)}/$transactionId',
    )
        .remove();
  }

  // ==========================================================
  // REPORTING
  // ==========================================================

  Future<double> getCategoryTotal({
    required String orgId,
    required String category,
    required DateTime month,
  }) async {
    final txs =
    await getTransactionsByCategory(
      orgId: orgId,
      category: category,
      month: month,
    );

    return txs.fold<double>(
      0,
          (sum, tx) =>
      sum + tx.amount,
    );
  }

  Future<double> getTotalIncome({
    required String orgId,
    required DateTime month,
  }) async {
    final txs =
    await getTransactionsByCategory(
      orgId: orgId,
      category: 'income',
      month: month,
    );

    return txs.fold<double>(
      0,
          (sum, tx) =>
      sum + tx.amount,
    );
  }

  Future<double> getTotalExpenses({
    required String orgId,
    required DateTime month,
  }) async {
    final txs =
    await getTransactionsByCategory(
      orgId: orgId,
      category: 'expense',
      month: month,
    );

    return txs.fold<double>(
      0,
          (sum, tx) =>
      sum + tx.amount,
    );
  }

  Future<double> getTotalDebt({
    required String orgId,
    required DateTime month,
  }) async {
    final txs =
    await getTransactionsByCategory(
      orgId: orgId,
      category: 'debt',
      month: month,
    );

    return txs.fold<double>(
      0,
          (sum, tx) =>
      sum + tx.amount,
    );
  }

  Future<int> getMonthlyTransactionCount({
    required String orgId,
    required DateTime month,
  }) async {
    final txs =
    await getTransactionsForMonth(
      orgId: orgId,
      month: month,
    );

    return txs.length;
  }
}