import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:my_app/payments/service/payment_list_service.dart';
import 'package:my_app/property/domain/property_model.dart';
import 'package:my_app/property/domain/payment_model.dart';


import '../../property/domain/property_model.dart';

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

  // ------------------------------------------------------------
  // LOAD UNITS
  // ------------------------------------------------------------
  Future<void> _loadUnits() async {
    final units = await service.getAllUnits(orgId);
    for (final u in units) {
      unitCache[u.unitId] = u;
    }
  }

  // ------------------------------------------------------------
  // LOAD PAYMENTS FOR MONTH
  // ------------------------------------------------------------
  Future<void> _loadPayments() async {
    final period = _formatPeriod(paymentMonth);
    payments = await service.getPaymentsForPeriod(orgId, period);
  }

  // ------------------------------------------------------------
  // LOAD LEASE HISTORY + ACTIVE LEASE
  // ------------------------------------------------------------
  Future<void> _loadLeaseData() async {
    for (final unit in unitCache.values) {
      // Load full lease history for this unit
      final history = await service.getLeaseHistory(orgId, unit.unitId);
      leaseHistoryCache[unit.unitId] = history;

      // Determine active lease for the selected month
      final active = history.firstWhere(
            (l ) => _isDateWithinLease(paymentMonth, l) && l.status == "active",
        orElse: () => _emptyLease(unit),
      );

      currentLeaseCache[unit.unitId] = active;
    }
  }

  // ------------------------------------------------------------
  // LOAD TENANTS FOR ACTIVE LEASES
  // ------------------------------------------------------------
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

  // ------------------------------------------------------------
  // CHECK IF DATE FALLS WITHIN LEASE RANGE
  // ------------------------------------------------------------
  bool _isDateWithinLease(DateTime date, LeaseDetailsModel lease) {
    final start = lease.parseEpocTime(lease.startDateEpoch);
    final end = lease.parseEpocTime(lease.endDateEpoch);

    return (date.isAfter(start) || date.isAtSameMomentAs(start)) &&
        (date.isBefore(end) || date.isAtSameMomentAs(end));
  }

  // ------------------------------------------------------------
  // FORMAT PERIOD (MMYYYY)
  // ------------------------------------------------------------
  String _formatPeriod(DateTime dt) {
    return "${dt.month.toString().padLeft(2, '0')}${dt.year}";
  }

  // ------------------------------------------------------------
  // EMPTY LEASE (fallback for vacant units)
  // ------------------------------------------------------------
  LeaseDetailsModel _emptyLease(UnitModel unit) {
    return LeaseDetailsModel(
      leaseId: "",
      orgId: orgId,
      propertyId: unit.propertyId,
      unitId: unit.unitId,
      tenantIds: [],
      startDateEpoch: 0,
      endDateEpoch: 0,
      rentAmount: 0,
      createdAt: 0,
      updatedAt: 0,
      status: "ended",
    );
  }

  // ------------------------------------------------------------
  // MONTH NAVIGATION
  // ------------------------------------------------------------
  void nextMonth() {
    paymentMonth = DateTime(paymentMonth.year, paymentMonth.month + 1, 1);
    init();
  }

  void prevMonth() {
    paymentMonth = DateTime(paymentMonth.year, paymentMonth.month - 1, 1);
    init();
  }

  // ------------------------------------------------------------
  // SEARCH + FILTER
  // ------------------------------------------------------------
  void setSearch(String q) {
    searchQuery = q;
    notifyListeners();
  }

  void setFilter(String mode) {
    filterMode = mode;
    notifyListeners();
  }
}
