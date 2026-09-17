import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:my_app/login/domain/re_user.dart';
import 'package:my_app/login/model/user_repository.dart';
import 'package:my_app/login/service/role_resolver.dart';
import 'package:my_app/login/model/org_user_repository.dart';
import 'package:my_app/payments/repository/payment_repository.dart';

import 'package:my_app/property/domain/property_model.dart';
import 'package:my_app/property/model/property_cache_sync_repository.dart';

import 'package:my_app/property/model/property_repository.dart';
import 'package:my_app/property/model/unit_repository.dart';
import 'package:my_app/property/model/lease_details_repository.dart';
import 'package:my_app/property/model/tenant_repository.dart';

import '../login/domain/orgUser.dart';



class AppSession extends ChangeNotifier {
  // ============================================================
  // USER + ORG + ROLE
  // ============================================================
  ReUser? _user;
  String? _activeOrgId;
  String? _activeOrgName;
  String? _activeRole;

  List<Map<String, dynamic>> _organizations = [];

  // ============================================================
  // ORG-SCOPED CACHES
  // ============================================================
  final Map<String, PropertyModel> _propertyCache = {};
  final Map<String, UnitModel> _unitCache = {};
  final Map<String, LeaseDetailsModel> _currentLeaseCache = {};
  final Map<String, TenantModel> _tenantCache = {};
  final Map<String, PropertyValuationModel> _valuationCache = {};
  Map<String, PropertyValuationModel> get valuationCache => _valuationCache;

  final Map<String, Map<String, MonthlyLedgerModel>> _ledgerMonthCache = {};
  Map<String, Map<String, MonthlyLedgerModel>> get ledgerMonthCache => _ledgerMonthCache;


  // ============================================================
  // PAYMENT CACHE
  // ============================================================
  final Map<String, PaymentModel> _paymentCache = {};
  Map<String, PaymentModel> get paymentCache => _paymentCache;

  // ============================================================
  // ORG USERS CACHE
  // ============================================================
  final Map<String, OrgUser> _orgUsersCache = {};
  Map<String, OrgUser> get orgUsersCache => _orgUsersCache;

  // ============================================================
  // USER PROFILE CACHE (ReUser)
  // ============================================================
  final Map<String, ReUser> _userCache = {};
  Map<String, ReUser> get userCache => _userCache;

  // ============================================================
  // REPOSITORIES
  // ============================================================
  final RoleResolver roleResolver;
  final OrgUserRepository orgUserRepo;
  final UserPreferencesRepository prefsRepo;

  final PropertyRepository propertyRepo;
  final UnitRepository unitRepo;
  final LeaseDetailsRepository leaseRepo;
  final TenantRepository tenantRepo;
  final PaymentRepository paymentRepo;

  // ============================================================
  // REALTIME SYNC SERVICE
  // ============================================================
  late final CacheSyncService cacheSync;

  AppSession({
    required this.roleResolver,
    required this.orgUserRepo,
    required this.prefsRepo,
    required this.propertyRepo,
    required this.unitRepo,
    required this.leaseRepo,
    required this.tenantRepo,
    required this.paymentRepo,
  }) {
    cacheSync = CacheSyncService(
      db: FirebaseDatabase.instance,
      session: this,
    );
  }

  // ============================================================
  // GETTERS
  // ============================================================
  ReUser? get user => _user;
  String? get activeOrgId => _activeOrgId;
  String? get activeOrgName => _activeOrgName;
  String? get activeRole => _activeRole;
  List<Map<String, dynamic>> get organizations => _organizations;

  Map<String, PropertyModel> get propertyCache => _propertyCache;
  Map<String, UnitModel> get unitCache => _unitCache;
  Map<String, LeaseDetailsModel> get currentLeaseCache => _currentLeaseCache;
  Map<String, TenantModel> get tenantCache => _tenantCache;

  List<PaymentModel> get recentPayments => _recentPayments;
  final List<PaymentModel> _recentPayments = [];

  // ============================================================
  // CACHE UPDATERS
  // ============================================================
  void updateOrgUserInCache(OrgUser orgUser) {
    _orgUsersCache[orgUser.userId] = orgUser;
    notifyListeners();
  }

  void updateOrganizationName(String orgId, String newName) {
    for (var org in _organizations) {
      if (org["orgId"] == orgId) {
        org["name"] = newName;
        break;
      }
    }
    notifyListeners();
  }

  void setUser(ReUser user) {
    _user = user;
    notifyListeners();
  }

  void updateValuationInCache(PropertyValuationModel valuation) {
    _valuationCache[valuation.propertyId] = valuation;
    notifyListeners();
  }

  void setOrganizations(List<Map<String, dynamic>> orgs) {
    _organizations = orgs;
    notifyListeners();
  }

  void updateTenantInCache(TenantModel tenant) {
    _tenantCache[tenant.tenantId] = tenant;
    notifyListeners();
  }

  void updateLeaseInCache(LeaseDetailsModel lease) {
    _currentLeaseCache[lease.leaseId] = lease;
    notifyListeners();
  }

  void updateUnitInCache(UnitModel unit) {
    _unitCache[unit.unitId] = unit;
    notifyListeners();
  }

  void updatePaymentInCache(PaymentModel payment) {
    _paymentCache[payment.paymentId] = payment;
    notifyListeners();
  }

  void updateLedgerMonthInCache(String period, Map<String, MonthlyLedgerModel> monthData) {
    _ledgerMonthCache[period] = monthData;

    // Evict older months if > 3 cached
    if (_ledgerMonthCache.length > 24) {
      final sortedKeys = _ledgerMonthCache.keys.toList()..sort();
      final oldest = sortedKeys.first;
      _ledgerMonthCache.remove(oldest);
    }

    notifyListeners();
  }



  // ============================================================
  // ACTIVE ORG SETTERS
  // ============================================================
  void setActiveOrg(String? orgId) {
    _activeOrgId = orgId;

    if (orgId != null) {
      cacheSync.attachOrg(orgId);
    } else {
      cacheSync.detachOrg();
    }

    notifyListeners();
  }

  void setActiveOrgName(String? name) {
    _activeOrgName = name;
    notifyListeners();
  }

  void setActiveRole(String? role) {
    _activeRole = role;
    notifyListeners();
  }

  // ============================================================
  // CLEAR ORG-SCOPED CACHE
  // ============================================================
  void clearOrgScopedData() {
    _propertyCache.clear();
    _unitCache.clear();
    _currentLeaseCache.clear();
    _tenantCache.clear();
    _valuationCache.clear();
    _orgUsersCache.clear();
    _paymentCache.clear();
    _userCache.clear();
    _ledgerMonthCache.clear();   // ⭐ NEW
    notifyListeners();
  }

  // ============================================================
  // LOAD ORG-SCOPED DATA (initial load only)
  // ============================================================
  Future<void> loadOrgScopedData() async {
    final orgId = activeOrgId;
    if (orgId == null) return;

    // 1. PROPERTIES
    final properties = await propertyRepo.getPropertiesForOrg(orgId);
    _propertyCache
      ..clear()
      ..addEntries(properties.map((p) => MapEntry(p.propertyId, p)));

    // 2. UNITS
    final units = await unitRepo.getUnitsForOrg(orgId);
    _unitCache
      ..clear()
      ..addEntries(units.map((u) => MapEntry(u.unitId, u)));

    // 3. CURRENT LEASES
    final leases = await leaseRepo.getCurrentLeasesForOrg(orgId);
    _currentLeaseCache
      ..clear()
      ..addEntries(leases.map((l) => MapEntry(l.leaseId, l)));

    // 4. TENANTS
    final tenantIds = leases
        .expand((l) => l.tenantIds ?? [])
        .map((id) => id.toString())
        .toSet()
        .toList();

    final tenants = await tenantRepo.getTenantsByIds(orgId, tenantIds);

    _tenantCache
      ..clear()
      ..addEntries(tenants.map((t) => MapEntry(t.tenantId, t)));

    // 5. ORG USERS
    final orgUsers = await orgUserRepo.getUsersForOrg(orgId);
    _orgUsersCache
      ..clear()
      ..addEntries(orgUsers.map((u) => MapEntry(u.userId, u)));

    // 6. USER PROFILES
    _userCache.clear();
    for (final orgUser in orgUsers) {
      final profile = await orgUserRepo.getUserProfile(orgUser.userId);
      if (profile != null) {
        _userCache[orgUser.userId] = profile;
      }
    }


    // 7. VALUATIONS
    _valuationCache.clear();
    for (final p in properties) {
      final val = await propertyRepo.getValuation(orgId, p.propertyId);
      if (val != null) {
        _valuationCache[p.propertyId] = val;
      }
    }

    // 8. PAYMENTS — only current month
    final now = DateTime.now();
    final payments = await paymentRepo.fetchPaymentsForMonth(
      orgId,
      now.year,
      now.month,
    );

    _paymentCache
      ..clear()
      ..addEntries(payments.map((p) => MapEntry(p.paymentId, p)));

    await preloadLedgerForPreviousMonth(activeOrgId!);
    notifyListeners();
  }

  Future<Map<String, MonthlyLedgerModel>> getMonthlyLedger(
      String orgId,
      DateTime monthDate,
      ) async {
    final period = "${monthDate.year}-${monthDate.month.toString().padLeft(2, '0')}";

    // Return from cache
    if (_ledgerMonthCache.containsKey(period)) {
      print('cache hit $period');
      return _ledgerMonthCache[period]!;
    }

    print('cache miss $period');
    // Fetch from DB
    final ref = FirebaseDatabase.instance
        .ref("orgs/$orgId/MonthlyLedger/$period");

    final snapshot = await ref.get();
    if (!snapshot.exists) {
      updateLedgerMonthInCache(period, {});
      return {};
    }

    final raw = snapshot.value as Map<dynamic, dynamic>;
    final parsed = <String, MonthlyLedgerModel>{};

    raw.forEach((key, value) {
      parsed[key.toString()] =
          MonthlyLedgerModel.fromMap(key.toString(), Map<String, dynamic>.from(value));
    });

    updateLedgerMonthInCache(period, parsed);
    return parsed;
  }


  Future<List<PaymentModel>> getPaymentsForMonth(String orgId, int year, int month) async {
    return await paymentRepo.fetchPaymentsForMonth(orgId, year, month);
  }

  // ============================================================
  // LOAD USER + ORG + ROLE
  // ============================================================
  Future<void> ensureUserLoaded() async {
    if (_user == null) return;
    if (_activeOrgId != null && _activeRole != null && _activeOrgName != null) {
      return;
    }

    final userId = _user!.userId.toString();

    final orgs = await orgUserRepo.getOrgsForUser(userId);
    setOrganizations(orgs);

    final prefs = await prefsRepo.getPreferences(userId);

    if (prefs?.defaultOrgId != null) {
      final orgId = prefs!.defaultOrgId!;
      final orgUser = await orgUserRepo.getOrgUser(orgId, userId);
      final orgName = await orgUserRepo.getOrgName(orgId);

      if (orgUser != null) {
        final role = await roleResolver.resolveRole(
          userId: userId,
          orgId: orgId,
        );

        setActiveOrg(orgId);
        setActiveOrgName(orgName);
        setActiveRole(role);

        await loadOrgScopedData();
        return;
      }
    }

    final best = await roleResolver.chooseBestOrgAndRole(userId);

    if (best != null) {
      final orgId = best['orgId']!;
      final role = best['role']!;
      final orgName = await orgUserRepo.getOrgName(orgId);

      setActiveOrg(orgId);
      setActiveOrgName(orgName);
      setActiveRole(role);

      await prefsRepo.setDefaultOrg(userId, orgId);

      await loadOrgScopedData();
    }
  }
  Future<void> preloadLedgerForPreviousMonth(String orgId) async {
    final now = DateTime.now();
    final prevMonth = DateTime(now.year, now.month - 1, 1);
    await getMonthlyLedger(orgId, prevMonth);
  }


  // ============================================================
  // CLEAR ENTIRE SESSION
  // ============================================================
  void clear() {
    cacheSync.detachOrg();

    _user = null;
    _activeOrgId = null;
    _activeOrgName = null;
    _activeRole = null;

    clearOrgScopedData();
    _organizations = [];

    notifyListeners();
  }

  Future<void> setDefaultOrg(String orgId) async {
    await prefsRepo.setDefaultOrg(_user!.userId.toString(), orgId);
  }

  void noifyListeners() {
    notifyListeners();
  }
}

