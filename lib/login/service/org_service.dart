import 'package:firebase_database/firebase_database.dart';
import 'package:my_app/login/domain/orgUser.dart';
import 'package:my_app/login/domain/org_model.dart';


class OrgService {
  final _db = FirebaseDatabase.instance.ref();

  Future<String> createOrg({
    required OrgModel org,
    required OrgUserModel owner,
  }) async {
    final orgRef = _db.child("Orgs").push();
    final orgId = orgRef.key!;

    // Save org
    await orgRef.set(org.toMap());

    // Save owner under OrgUsers
    await _db.child("OrgUsers/$orgId/${owner.userId}").set(owner.toMap());

    // Save membership under UserOrgs
    await _db.child("UserOrgs/${owner.userId}/$orgId").set(true);

    return orgId;
  }
}
