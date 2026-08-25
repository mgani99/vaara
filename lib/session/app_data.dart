import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:my_app/login/domain/re_user.dart';
import 'package:my_app/login/model/user_repository.dart';
import 'package:my_app/login/service/role_resolver.dart';
import 'package:my_app/login/model/org_user_repository.dart';
import 'package:my_app/property/domain/payment_model.dart';

import 'package:my_app/property/domain/property_model.dart';
import 'package:my_app/property/model/property_cache_sync_repository.dart';

import 'package:my_app/property/model/property_repository.dart';
import 'package:my_app/property/model/unit_repository.dart';
import 'package:my_app/property/model/lease_details_repository.dart';
import 'package:my_app/property/model/tenant_repository.dart';



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
  // SETTERS
  // ============================================================
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

  void setActiveOrg(String? orgId) {
    _activeOrgId = orgId;

    if (orgId != null) {
      //print("attacheing cache");
      cacheSync.attachOrg(orgId);   // ⭐ REALTIME SYNC ENABLED
    } else {
      cacheSync.detachOrg();        // ⭐ STOP LISTENERS
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

    // 5. VALUATIONS
    _valuationCache.clear();
    for (final p in properties) {
      final val = await propertyRepo.getValuation(orgId, p.propertyId);
      if (val != null) {
        _valuationCache[p.propertyId] = val;
      }
    }

    notifyListeners();
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

    // Load orgs for dropdown
    final orgs = await orgUserRepo.getOrgsForUser(userId);
    setOrganizations(orgs);

    final prefs = await prefsRepo.getPreferences(userId);

    // ------------------------------------------------------------
    // 1. Saved default org
    // ------------------------------------------------------------
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

        await loadOrgScopedData();   // ⭐ initial load
        return;
      }
    }

    // ------------------------------------------------------------
    // 2. Choose best org + role
    // ------------------------------------------------------------
    final best = await roleResolver.chooseBestOrgAndRole(userId);

    if (best != null) {
      final orgId = best['orgId']!;
      final role = best['role']!;
      final orgName = await orgUserRepo.getOrgName(orgId);

      setActiveOrg(orgId);
      setActiveOrgName(orgName);
      setActiveRole(role);

      await prefsRepo.setDefaultOrg(userId, orgId);

      await loadOrgScopedData();     // ⭐ initial load
    }
  }

  // ============================================================
  // CLEAR ENTIRE SESSION
  // ============================================================
  void clear() {
    cacheSync.detachOrg();           // ⭐ stop realtime listeners

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

  void updatePropertyInCache(PropertyModel propertyModel) {
    _propertyCache[propertyModel.propertyId] = propertyModel;
    notifyListeners();
  }

  void noifyListeners() {
    notifyListeners();
  }
}
