import 'package:flutter/foundation.dart';
import 'package:my_app/session/user_role.dart';

class AppSession extends ChangeNotifier {
  // ------------------------------------------------------------
  // USER + ORG
  // ------------------------------------------------------------
  String? userId;
  String? userEmail;
  String? userName;

  String? activeOrgId;
  UserRole? activeRole;

  // List of org IDs the user belongs to
  List<String> orgIds = [];

  // Optional: org names (if you want to store them)
  Map<String, String> orgNames = {};

  // ------------------------------------------------------------
  // PROPERTY + UNIT CONTEXT (NEW)
  // ------------------------------------------------------------
  String? activePropertyId;
  String? activeUnitId;
  String? activeUnitName;

  // ------------------------------------------------------------
  // MONTH NAVIGATION (Dashboard)
  // ------------------------------------------------------------
  DateTime _navigationDate = DateTime.now();
  DateTime get navigationDate => _navigationDate;

  void nextMonth() {
    _navigationDate = DateTime(
      _navigationDate.year,
      _navigationDate.month + 1,
      1,
    );
    notifyListeners();
  }

  void previousMonth() {
    _navigationDate = DateTime(
      _navigationDate.year,
      _navigationDate.month - 1,
      1,
    );
    notifyListeners();
  }

  // ------------------------------------------------------------
  // ACTIVE ORG NAME
  // ------------------------------------------------------------
  String? get activeOrgName {
    if (activeOrgId == null) return null;
    return orgNames[activeOrgId];
  }

  void setOrgName(String orgId, String name) {
    orgNames[orgId] = name;
    notifyListeners();
  }

  // ------------------------------------------------------------
  // SETTERS
  // ------------------------------------------------------------
  void setUser({
    required String id,
    String? email,
    String? name,
  }) {
    userId = id;
    userEmail = email;
    userName = name;
    notifyListeners();
  }

  void setActiveOrg(String orgId) {
    activeOrgId = orgId;
    notifyListeners();
  }

  void setActiveRole(UserRole role) {
    activeRole = role;
    notifyListeners();
  }

  void setOrgMemberships(List<String> orgs) {
    orgIds = orgs;
    notifyListeners();
  }

  // ------------------------------------------------------------
  // PROPERTY + UNIT CONTEXT (NEW)
  // ------------------------------------------------------------
  void setPropertyContext({
    required String propertyId,
    required String unitId,
    required String unitName,
  }) {
    activePropertyId = propertyId;
    activeUnitId = unitId;
    activeUnitName = unitName;
    notifyListeners();
  }

  // ------------------------------------------------------------
  // ENSURE USER LOADED (NEW)
  // Called on HomePage initState()
  // ------------------------------------------------------------
  Future<void> ensureUserLoaded() async {
    if (userId == null) return;

    // In your real app, fetch user profile here:
    // final profile = await userRepo.getUser(userId!);

    // Fallback if missing
    userName ??= "User";

    notifyListeners();
  }

  // ------------------------------------------------------------
  // CLEAR SESSION
  // ------------------------------------------------------------
  void clear() {
    userId = null;
    userEmail = null;
    userName = null;

    activeOrgId = null;
    activeRole = null;

    activePropertyId = null;
    activeUnitId = null;
    activeUnitName = null;

    orgIds = [];
    orgNames = {};

    _navigationDate = DateTime.now();

    notifyListeners();
  }
}


/// Strongly-typed wrapper around a userId.
/// Domain layer uses `int`, UI/session uses `String`.
class UserId {
  final int value;

  const UserId(this.value);

  factory UserId.fromSession(String? id) {
    if (id == null) {
      throw StateError("Session userId is null");
    }
    return UserId(int.parse(id));
  }

  String get asString => value.toString();
  int get asInt => value;

  @override
  String toString() => value.toString();
}
