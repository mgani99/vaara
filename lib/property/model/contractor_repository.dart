import 'package:firebase_database/firebase_database.dart';

class ContractorRepository {
  final DatabaseReference db = FirebaseDatabase.instance.ref();

  Future<void> createContractorProfile({
    required String orgId,
    required int userId,
    required String businessName,
    required String serviceType,
    required String phone,
    String? notes,
  }) async {
    await db.child("Orgs/$orgId/Contractors/$userId").set({
      "contractorId": userId,
      "businessName": businessName,
      "serviceType": serviceType,
      "phone": phone,
      "notes": notes,
      "createdAt": DateTime.now().millisecondsSinceEpoch,
    });
  }



  Future<bool> isContractorForOrg(String userId, String orgId) async {
  final snap = await db.child("Orgs/$orgId/contractors/$userId").get();
  return snap.exists;
  }


}
