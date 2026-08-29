import 'package:firebase_database/firebase_database.dart';

class InvitationRepository {
  final DatabaseReference db = FirebaseDatabase.instance.ref();

  // ------------------------------------------------------------
  // Get all pending invitations for a given email
  // ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getInvitationsForEmail(String email) async {
    final snapshot = await db.child("invitations").get();
    final List<Map<String, dynamic>> invites = [];

    for (var child in snapshot.children) {
      final data = child.value as Map<dynamic, dynamic>;

      if (data["email"] == email && data["accepted"] != true) {
        invites.add({
          "inviteId": data["inviteId"],
          "orgId": data["orgId"],
          "email": data["email"],
          "role": data["role"],
          "accepted": data["accepted"] ?? false,
          "createdAt": data["createdAt"],
          "metadata": data["metadata"],
        });
      }
    }

    return invites;
  }

  Future<List<Map<String, dynamic>>> loadInvitationsForOrg(String orgId) async {
    final snapshot = await db.child("invitations").get();
    final List<Map<String, dynamic>> invites = [];

    for (var child in snapshot.children) {
      final data = child.value as Map<dynamic, dynamic>;

      if (data["orgId"] == orgId) {
        invites.add({
          "inviteId": data["inviteId"],
          "orgId": data["orgId"],
          "email": data["email"],
          "role": data["role"],
          "accepted": data["accepted"] ?? false,
          "createdAt": data["createdAt"],
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
    await db.child("invitations/$inviteId").update({
      "accepted": true,
      "acceptedAt": DateTime.now().millisecondsSinceEpoch,
    });
  }

  // ------------------------------------------------------------
  // Delete invitation (optional cleanup)
  // ------------------------------------------------------------
  Future<void> deleteInvitation(String inviteId) async {
    await db.child("invitations/$inviteId").remove();
  }

  // ------------------------------------------------------------
  // Create an invitation (used by landlords)
  // ------------------------------------------------------------
  Future<String> createInvitation({
    required String orgId,
    required String email,
    required String role, // landlord | tenant | contractor
    String? inviter,
    String? inviterEmail,

    Map<String, dynamic>? metadata,
  }) async {
    final ref = db.child("invitations").push();
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
      "inviter": inviter,
      "inviterEmail": inviterEmail,
    });

    return inviteId;
  }
}
