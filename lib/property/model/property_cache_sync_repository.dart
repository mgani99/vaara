import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

import 'package:my_app/property/domain/property_model.dart';
import 'package:my_app/session/app_data.dart';

class CacheSyncService {
  final FirebaseDatabase db;
  final AppSession session;

  CacheSyncService({
    required this.db,
    required this.session,
  });

  // Firebase refs
  DatabaseReference? _propRef;
  DatabaseReference? _unitRef;
  DatabaseReference? _leaseRef;
  DatabaseReference? _tenantRef;

  // Subscriptions
  StreamSubscription? _propAdd;
  StreamSubscription? _propChange;
  StreamSubscription? _propRemove;

  StreamSubscription? _unitAdd;
  StreamSubscription? _unitChange;
  StreamSubscription? _unitRemove;

  StreamSubscription? _leaseAdd;
  StreamSubscription? _leaseChange;
  StreamSubscription? _leaseRemove;

  StreamSubscription? _tenantAdd;
  StreamSubscription? _tenantChange;
  StreamSubscription? _tenantRemove;

  // ============================================================
  // ATTACH ORG
  // ============================================================
  Future<void> attachOrg(String orgId) async {
    await detachOrg();

    _propRef = db.ref("orgs/$orgId/Properties");
    _unitRef = db.ref("orgs/$orgId/Units");
    _leaseRef = db.ref("orgs/$orgId/LeaseDetails");
    _tenantRef = db.ref("orgs/$orgId/Tenants");

    _attachPropertyListeners();
    _attachUnitListeners();
    _attachLeaseListeners();
    _attachTenantListeners();
  }

  // ============================================================
  // DETACH ORG
  // ============================================================
  Future<void> detachOrg() async {
    await _propAdd?.cancel();
    await _propChange?.cancel();
    await _propRemove?.cancel();

    await _unitAdd?.cancel();
    await _unitChange?.cancel();
    await _unitRemove?.cancel();

    await _leaseAdd?.cancel();
    await _leaseChange?.cancel();
    await _leaseRemove?.cancel();

    await _tenantAdd?.cancel();
    await _tenantChange?.cancel();
    await _tenantRemove?.cancel();
  }

  // ============================================================
  // PROPERTY LISTENERS
  // ============================================================
  void _attachPropertyListeners() {
    if (_propRef == null) return;

    _propAdd = _propRef!.onChildAdded.listen(_onPropertyUpsert);
    _propChange = _propRef!.onChildChanged.listen(_onPropertyUpsert);
    _propRemove = _propRef!.onChildRemoved.listen(_onPropertyRemove);
  }

  void _onPropertyUpsert(DatabaseEvent e) {
    final snap = e.snapshot;
    if (!snap.exists) return;

    final id = snap.key!;
    final map = Map<String, dynamic>.from(snap.value as Map);

    // ⭐ ARCHIVE DETECTION
    if (map["isDeleted"] == true || map["status"] == "archived") {
      session.propertyCache.remove(id);
      session.notifyListeners();
      return;
    }

    final model = PropertyModel.fromMap(id, map);
    session.propertyCache[id] = model;
    session.notifyListeners();
  }

  void _onPropertyRemove(DatabaseEvent e) {
    final id = e.snapshot.key;
    if (id == null) return;

    session.propertyCache.remove(id);
    session.notifyListeners();
  }

  // ============================================================
  // UNIT LISTENERS
  // ============================================================
  void _attachUnitListeners() {
    if (_unitRef == null) return;

    _unitAdd = _unitRef!.onChildAdded.listen(_onUnitUpsert);
    _unitChange = _unitRef!.onChildChanged.listen(_onUnitUpsert);
    _unitRemove = _unitRef!.onChildRemoved.listen(_onUnitRemove);
  }

  void _onUnitUpsert(DatabaseEvent e) {
    final snap = e.snapshot;
    if (!snap.exists) return;

    final id = snap.key!;
    final map = Map<String, dynamic>.from(snap.value as Map);

    // ⭐ ARCHIVE DETECTION
    if (map["isDeleted"] == true || map["status"] == "archived") {
      session.unitCache.remove(id);
      session.notifyListeners();
      return;
    }

    final model = UnitModel.fromMap(id, map);
    session.unitCache[id] = model;
    session.notifyListeners();
  }

  void _onUnitRemove(DatabaseEvent e) {
    final id = e.snapshot.key;
    if (id == null) return;

    session.unitCache.remove(id);
    session.notifyListeners();
  }

  // ============================================================
  // LEASE LISTENERS
  // ============================================================
  void _attachLeaseListeners() {
    if (_leaseRef == null) return;

    _leaseAdd = _leaseRef!.onChildAdded.listen(_onLeaseUpsert);
    _leaseChange = _leaseRef!.onChildChanged.listen(_onLeaseUpsert);
    _leaseRemove = _leaseRef!.onChildRemoved.listen(_onLeaseRemove);
  }

  void _onLeaseUpsert(DatabaseEvent e) {
    final snap = e.snapshot;
    if (!snap.exists) return;

    final id = snap.key!;
    final map = Map<String, dynamic>.from(snap.value as Map);

    // ⭐ ARCHIVE DETECTION
    if (map["isDeleted"] == true || map["status"] == "archived") {
      final unitId = map["unitId"];
      session.currentLeaseCache.remove(unitId);
      session.notifyListeners();
      return;
    }

    final model = LeaseDetailsModel.fromMap(id, map);
    //final isCurrent = map["isCurrent"] == true;


    session.currentLeaseCache[model.leaseId] = model;


    session.notifyListeners();
  }

  void _onLeaseRemove(DatabaseEvent e) {
    final snap = e.snapshot;
    if (!snap.exists) return;

    final leaseId = snap.key;

    if (leaseId == null) return;

    session.currentLeaseCache.remove(leaseId);
    session.notifyListeners();
  }

  // ============================================================
  // TENANT LISTENERS
  // ============================================================
  void _attachTenantListeners() {
    if (_tenantRef == null) return;

    _tenantAdd = _tenantRef!.onChildAdded.listen(_onTenantUpsert);
    _tenantChange = _tenantRef!.onChildChanged.listen(_onTenantUpsert);
    _tenantRemove = _tenantRef!.onChildRemoved.listen(_onTenantRemove);
  }

  void _onTenantUpsert(DatabaseEvent e) {
    final snap = e.snapshot;
    if (!snap.exists) return;

    final id = snap.key!;
    final map = Map<String, dynamic>.from(snap.value as Map);

    // ⭐ ARCHIVE DETECTION
    if (map["isDeleted"] == true || map["status"] == "archived") {
      session.tenantCache.remove(id);
      session.notifyListeners();
      return;
    }

    final model = TenantModel.fromMap(id, map);
    session.tenantCache[id] = model;
    session.notifyListeners();
  }

  void _onTenantRemove(DatabaseEvent e) {
    final id = e.snapshot.key;
    if (id == null) return;

    session.tenantCache.remove(id);
    session.notifyListeners();
  }
}
