import 'package:firebase_database/firebase_database.dart';

import '../property/domain/property_model.dart';

class RentJournalService {
  final FirebaseDatabase db;

  RentJournalService(this.db);

  Future<void> runDailyRentJournal(String orgId) async {
    final today = DateTime.now();
    final leases = await _getActiveLeases(orgId);

    for (final lease in leases) {
      final dueDay = lease.rentDueDate!;
      final rentAmount = lease.rentAmount;

      // If lease has no due day, skip
      if (dueDay < 1 || dueDay > 31) continue;

      // Determine the first possible rent date this month
      final firstPossibleDate = DateTime(today.year, today.month, dueDay);

      // If due date is in the future (later this month), skip
      if (today.day < dueDay) continue;

      // ⭐ BACKFILL LOOP ⭐
      // Loop from the due date up to today (inclusive)
      for (int day = dueDay; day <= today.day; day++) {
        final effectiveDate = DateTime(today.year, today.month, day);

        // Fetch existing rent entries for this unit + month
        final existing = await _getRentEntries(
          orgId,
          lease.unitId,
          effectiveDate,
          includeDeleted: true,
        );

        // Respect deleted / void entries
        if (existing.any((e) => e.isDeleted || e.status == "void")) {
          continue;
        }

        // Respect manual entries
        if (existing.any((e) => !e.isSystemGenerated)) {
          continue;
        }

        // Idempotency: if rent exists for this day, skip
        if (existing.isNotEmpty) continue;

        // Create rent charge for this missed day
        final payment = PaymentModel(
          paymentId: DateTime.now().millisecondsSinceEpoch.toString(),
          orgId: orgId,
          propertyId: lease.propertyId,
          unitId: lease.unitId,
          tenantId: lease.tenantIds.first,
          transactionType: "credit",
          paymentType: "Rent",
          amount: rentAmount,

          effectiveDateEpoch: effectiveDate.millisecondsSinceEpoch,
          actualDateEpoch: today.millisecondsSinceEpoch,
          recordedAtEpoch: DateTime.now().millisecondsSinceEpoch,

          isSystemGenerated: true,
          note: "Auto rent journal (backfill safe)",
          status: "active",

          validFromEpoch: DateTime.now().millisecondsSinceEpoch,
          validToEpoch: null,
          isDeleted: false,
          deletedAt: null,
        );

        await _savePayment(payment);
      }
    }
  }

  Future<List<LeaseDetailsModel>> _getActiveLeases(String orgId) async {
    final snap = await db.ref("orgs/$orgId/LeaseDetails").get();
    final leases = <LeaseDetailsModel>[];

    for (final child in snap.children) {
      final map = child.value as Map<String, dynamic>;
      final lease = LeaseDetailsModel.fromMap(child.key!, map);

      if (lease.status == "active" && !lease.isDeleted) {
        leases.add(lease);
      }
    }

    return leases;
  }

  Future<List<PaymentModel>> _getRentEntries(
      String orgId,
      String unitId,
      DateTime effectiveDate, {
        bool includeDeleted = false,
      }) async {
    final snap = await db
        .ref("orgs/$orgId/Payments")
        .orderByChild("unitId")
        .equalTo(unitId)
        .get();

    final list = <PaymentModel>[];

    for (final child in snap.children) {
      final map = child.value as Map<String, dynamic>;
      final p = PaymentModel.fromMap(child.key!, map);

      if (p.paymentType != "Rent") continue;

      final eff = DateTime.fromMillisecondsSinceEpoch(p.effectiveDateEpoch);
      if (eff.year == effectiveDate.year && eff.month == effectiveDate.month && eff.day == effectiveDate.day) {
        if (!includeDeleted && p.isDeleted) continue;
        list.add(p);
      }
    }

    return list;
  }

  Future<void> _savePayment(PaymentModel payment) async {
    await db
        .ref("orgs/${payment.orgId}/Payments/${payment.paymentId}")
        .set(payment.toMap());
  }
}


/*
exports.runMonthlyLedgerJob = functions.pubsub
  .schedule('0 0 1 * *') // first day of month at midnight
  .timeZone('America/New_York')
  .onRun(async (context) => {

    const admin = require('firebase-admin');
    const db = admin.database();

    const now = new Date();
    const year = now.getFullYear();
    const month = now.getMonth(); // previous month

    const orgsSnap = await db.ref("orgs").get();

    orgsSnap.forEach(async (orgNode) => {
      const orgId = orgNode.key;

      const paymentsSnap = await db.ref(`orgs/${orgId}/Payments`).get();
      let debit = 0;
      let credit = 0;

      paymentsSnap.forEach((child) => {
        const p = child.val();
        const date = new Date(p.paymentDateEpoch);

        if (date.getFullYear() === year && date.getMonth() === month) {
          if (p.transactionType === "debit") debit += p.amount;
          else credit += p.amount;
        }
      });

      const net = debit - credit;

      await db.ref(`orgs/${orgId}/PaymentLedger/${year}-${month + 1}`).set({
        year,
        month: month + 1,
        totalDebit: debit,
        totalCredit: credit,
        net,
        createdAt: Date.now()
      });
    });

    return null;
  });

 */