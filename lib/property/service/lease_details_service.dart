

import 'package:my_app/property/domain/lease_details_model.dart';
import 'package:my_app/property/model/lease_details_repository.dart';

class LeaseDetailsService {
  final LeaseDetailsRepository repo;

  LeaseDetailsService({required this.repo});

  Future<String> createLease(LeaseDetailsModel lease) {
    return repo.createLease(lease);
  }

  Future<LeaseDetailsModel?> getLease(String orgId, String leaseId) {
    return repo.getLease(orgId, leaseId);
  }

  Future<List<LeaseDetailsModel>> getLeasesForUnit(
      String orgId, String unitId) {
    return repo.getLeasesForUnit(orgId, unitId);
  }
}
