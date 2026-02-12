import 'package:firebase_database/firebase_database.dart';
import 'package:my_app/login/domain/re_user.dart';

class UserRepository {
  final DatabaseReference db = FirebaseDatabase.instance.ref();

  // ---------------------------------------------------------
  // CREATE USER (Atomic nextUserId + write user)
  // ---------------------------------------------------------
  Future<ReUser> createUser({
    required String email,
    required String firstName,
    required String lastName,
    required String phone,
    required String firebaseUid,
    String authProvider = "password",
  }) async {
    final nextIdRef = db.child("Users/nextUserId");

    // Atomic increment
    final int newUserId = await nextIdRef.runTransaction((current) {
      final currentValue = (current as int?) ?? 0;
      return Transaction.success(currentValue + 1);
    }).then((result) {
      if (!result.committed) {
        throw Exception("Failed to allocate next user ID");
      }
      return result.snapshot.value as int;
    });

    final now = DateTime.now().millisecondsSinceEpoch;

    final user = ReUser(
      userId: newUserId,
      email: email,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      profilePictureUrl: "",
      authProvider: authProvider,
      firebaseUid: firebaseUid,
      fcmTokens: const [],
      status: "active",
      createdAt: now,
      updatedAt: now,
      lastLoginAt: now,
      language: "en",
      timezone: "America/New_York",
      emailNotifications: true,
      smsNotifications: false,
      pushNotifications: true,
    );

    await db.child("Users/$newUserId").set(user.toJson());

    return user;
  }

  // ---------------------------------------------------------
  // GET USER BY ID
  // ---------------------------------------------------------
  Future<ReUser?> getUser(int userId) async {
    final snapshot = await db.child("Users/$userId").get();
    if (!snapshot.exists) return null;

    final value = snapshot.value;
    if (value is! Map) return null;

    return ReUser.fromMap(Map<String, dynamic>.from(value));
  }

  // ---------------------------------------------------------
  // GET USER BY FIREBASE UID
  // ---------------------------------------------------------
  Future<ReUser?> getByFirebaseUid(String firebaseUid) async {
    final snapshot = await db.child("Users").get();
    if (!snapshot.exists) return null;

    for (var child in snapshot.children) {
      final value = child.value;

      // Skip non-map children like "nextUserId"
      if (value is! Map) continue;

      final map = Map<String, dynamic>.from(value);

      if (map["firebaseUid"] == firebaseUid) {
        return ReUser.fromMap(map);
      }
    }

    return null;
  }

  // ---------------------------------------------------------
  // GET USER BY EMAIL
  // ---------------------------------------------------------
  Future<ReUser?> getByEmail(String email) async {
    final snapshot = await db.child("Users").get();
    if (!snapshot.exists) return null;

    for (var child in snapshot.children) {
      final value = child.value;

      // Skip non-map children like nextUserId
      if (value is! Map) continue;

      final map = Map<String, dynamic>.from(value);

      // Your ReUser uses "email", not "emailAddress"
      if (map['email'] == email) {
        return ReUser.fromMap(map);
      }
    }

    return null;
  }

  // ---------------------------------------------------------
  // PARTIAL UPDATE
  // ---------------------------------------------------------
  Future<void> updateUser(int userId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
    await db.child("Users/$userId").update(updates);
  }

  // ---------------------------------------------------------
  // UPDATE LAST LOGIN
  // ---------------------------------------------------------
  Future<void> updateLastLogin(int userId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.child("Users/$userId").update({
      "lastLoginAt": now,
      "updatedAt": now,
    });
  }

  // ---------------------------------------------------------
  // ADD FCM TOKEN (multi-device safe)
  // ---------------------------------------------------------
  Future<void> addFcmToken(int userId, String token) async {
    final ref = db.child("Users/$userId/fcmTokens");
    final snapshot = await ref.get();

    final List tokens = snapshot.value is List ? snapshot.value as List : [];

    if (!tokens.contains(token)) {
      tokens.add(token);
      await ref.set(tokens);
    }
  }

  // ---------------------------------------------------------
  // REMOVE FCM TOKEN
  // ---------------------------------------------------------
  Future<void> removeFcmToken(int userId, String token) async {
    final ref = db.child("Users/$userId/fcmTokens");
    final snapshot = await ref.get();

    final List tokens = snapshot.value is List ? snapshot.value as List : [];

    tokens.remove(token);
    await ref.set(tokens);
  }

  // ---------------------------------------------------------
  // CHECK IF USER EXISTS
  // ---------------------------------------------------------
  Future<bool> userExists(String email) async {
    final user = await getByEmail(email);
    return user != null;
  }

  // ---------------------------------------------------------
// GET USER BY FIREBASE UID (corrected)
// ---------------------------------------------------------
  Future<ReUser?> getUserByFirebaseUid(String firebaseUid) async {
    final snapshot = await db.child("Users").get();
    if (!snapshot.exists) return null;

    for (var child in snapshot.children) {
      final value = child.value;

      if (value is! Map) continue;

      final map = Map<String, dynamic>.from(value);

      if (map["firebaseUid"] == firebaseUid) {
        map["userId"] = int.tryParse(child.key!) ?? 0;
        return ReUser.fromMap(map);
      }
    }

    return null;
  }

// ---------------------------------------------------------
// UPDATE ONBOARDING COMPLETED
// ---------------------------------------------------------
  Future<void> updateOnboardingCompleted(int userId, bool completed) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.child("Users/$userId").update({
      "onboardingCompleted": completed,
      "updatedAt": now,
    });
  }


}
