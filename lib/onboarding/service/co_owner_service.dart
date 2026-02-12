import 'package:firebase_database/firebase_database.dart';
import 'package:my_app/onboarding/model/co_owner_invite.dart';

class CoOwnerService {
  final _db = FirebaseDatabase.instance.ref();

  Future<void> sendInvite(CoOwnerInvite invite) async {
    final ref = _db.child("Invitations").push();
    await ref.set(invite.toMap());
  }
}
