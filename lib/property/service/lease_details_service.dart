

import 'package:my_app/property/model/lease_details_repository.dart';
import 'package:my_app/session/app_data.dart';

import '../domain/property_model.dart';

class LeaseDetailsService {
  final LeaseDetailsRepository repo;
  final AppSession session;

  LeaseDetailsService({
    required this.repo,
    required this.session,
  });


  Future<LeaseDetailsModel> createLease(String orgId, LeaseDetailsModel lease) async {
    final id = await repo.createLease(lease);
    final newLease = lease.copyWith(leaseId: id);
    repo.updateLeaseId(id, orgId);
    return newLease;
  }


  Future<LeaseDetailsModel?> getLease(String orgId, String leaseId) {
    return repo.getLease(orgId, leaseId);
  }

  Future<List<LeaseDetailsModel>> getLeasesForUnit(
      String orgId, String unitId) {
    return repo.getLeasesForUnit(orgId, unitId);
  }

  Future<void> updateLease(String orgId, String leaseId, {required double rentAmount, required String status}) async {}
}
