import 'package:firebase_database/firebase_database.dart';

class InvitationRepository {
  final DatabaseReference db = FirebaseDatabase.instance.ref();

  // ------------------------------------------------------------
  // Get all pending invitations for a given email
  // ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getInvitationsForEmail(String email) async {
    final snapshot = await db.child("Invitations").get();
    final List<Map<String, dynamic>> invites = [];

    for (var child in snapshot.children) {
      final data = child.value as Map<dynamic, dynamic>;

      if (data["email"] == email && data["accepted"] != true) {
        invites.add({
          "inviteId": child.key,
          "orgId": data["orgId"],
          "email": data["email"],
          "role": data["role"],
          "metadata": data["metadata"],
        });
      }
    }

    return invites;
  }

  // ------------------------------------------------------------
  // Mark invitation as accepted
  // ------------------------------------------------------------
  Future<void> markAccepted(String inviteId) async {
    await db.child("Invitations/$inviteId").update({
      "accepted": true,
      "acceptedAt": DateTime.now().millisecondsSinceEpoch,
    });
  }

  // ------------------------------------------------------------
  // Delete invitation (optional cleanup)
  // ------------------------------------------------------------
  Future<void> deleteInvitation(String inviteId) async {
    await db.child("Invitations/$inviteId").remove();
  }

  // ------------------------------------------------------------
  // Create an invitation (used by landlords)
  // ------------------------------------------------------------
  Future<String> createInvitation({
    required String orgId,
    required String email,
    required String role, // landlord | tenant | contractor
    Map<String, dynamic>? metadata,
  }) async {
    final ref = db.child("Invitations").push();
    final inviteId = ref.key!;
    final now = DateTime.now().millisecondsSinceEpoch;

    await ref.set({
      "inviteId": inviteId,
      "orgId": orgId,
      "email": email,
      "role": role,
      "metadata": metadata,
      "accepted": false,
      "createdAt": now,
    });

    return inviteId;
  }
}
