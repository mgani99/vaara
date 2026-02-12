import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:my_app/payments/service/payment_list_service.dart';
import 'package:my_app/property/domain/lease_details_model.dart';
import 'package:my_app/property/domain/payment_model.dart';
import 'package:my_app/property/domain/tenant_model.dart';
import 'package:my_app/property/domain/unit_model.dart';


class PaymentListController extends ChangeNotifier {
  final PaymentListService service;
  final String orgId;

  PaymentListController({
    required this.service,
    required this.orgId,
  });

  DateTime paymentMonth = DateTime.now();

  // caches
  final Map<String, UnitModel> unitCache = {};
  final Map<String, TenantModel> tenantCache = {};
  final Map<String, LeaseDetailsModel> currentLeaseCache = {};
  final Map<String, List<LeaseDetailsModel>> leaseHistoryCache = {};

  // payments
  List<PaymentModel> payments = [];

  // search + filter
  String searchQuery = "";
  String filterMode = "none";

  bool loading = false;

  Future<void> init() async {
    loading = true;
    notifyListeners();

    await _loadUnits();
    await _loadPayments();
    await _loadLeaseData();
    await _loadTenants();

    loading = false;
    notifyListeners();
  }

  Future<void> _loadUnits() async {
    final units = await service.getAllUnits(orgId);
    for (final u in units) {
      unitCache[u.unitId] = u;
    }
  }

  Future<void> _loadPayments() async {
    final period = _formatPeriod(paymentMonth);
    payments = await service.getPaymentsForPeriod(orgId, period);
  }

  Future<void> _loadLeaseData() async {
    for (final unit in unitCache.values) {
      final history = await service.getLeaseHistory(orgId, unit.unitId);
      leaseHistoryCache[unit.unitId] = history;

      // find active lease
      final active = history.firstWhere(
            (l) => _isDateWithinLease(paymentMonth, l),
        orElse: () => LeaseDetailsModel(
          leaseId: "",
          orgId: orgId,
          propertyId: unit.propertyId,
          unitId: unit.unitId,
          tenantIds: [],
          startDate: "1900-01-01",
          endDate: "1900-01-01",
          rentAmount: 0,
          createdAt: 0,
        ),
      );

      currentLeaseCache[unit.unitId] = active;
    }
  }

  Future<void> _loadTenants() async {
    final ids = <String>{};

    for (final lease in currentLeaseCache.values) {
      ids.addAll(lease.tenantIds);
    }

    for (final id in ids) {
      final t = await service.getTenant(orgId, id);
      if (t != null) tenantCache[id] = t;
    }
  }

  bool _isDateWithinLease(DateTime date, LeaseDetailsModel lease) {
    final start = DateTime.tryParse(lease.startDate) ?? DateTime(1900);
    final end = DateTime.tryParse(lease.endDate) ?? DateTime(1900);
    return (date.isAfter(start) || date.isAtSameMomentAs(start)) &&
        (date.isBefore(end) || date.isAtSameMomentAs(end));
  }

  String _formatPeriod(DateTime dt) {
    return "${dt.month.toString().padLeft(2, '0')}${dt.year}";
  }

  void nextMonth() {
    paymentMonth = DateTime(paymentMonth.year, paymentMonth.month + 1, 1);
    init();
  }

  void prevMonth() {
    paymentMonth = DateTime(paymentMonth.year, paymentMonth.month - 1, 1);
    init();
  }

  void setSearch(String q) {
    searchQuery = q;
    notifyListeners();
  }

  void setFilter(String mode) {
    filterMode = mode;
    notifyListeners();
  }
}
