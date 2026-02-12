
import 'package:firebase_database/firebase_database.dart';
import 'package:my_app/login/domain/re_user.dart';

class ProfileRepository {
  final DatabaseReference db;

  ProfileRepository({required this.db});

  Future<ReUser> fetchUser(int userId) async {
    final snap = await db.child("Users/$userId").get();
    return ReUser.fromMap(snap.value as Map<String, dynamic>);
  }

  Future<void> updateUser(ReUser user) async {
    await db.child("Users/${user.userId}").update(user.toJson());
  }

  Future<List<ReUser>> fetchUsersByFirebaseUid(String firebaseUid) async {
    final snap = await db
        .child("Users")
        .orderByChild("firebaseUid")
        .equalTo(firebaseUid)
        .get();

    return snap.children
        .map((c) => ReUser.fromMap(c.value as Map<String, dynamic>))
        .toList();
  }
}
