import 'package:my_app/login/domain/re_user.dart';
import 'package:my_app/profile/model/profile_repository.dart';


class ProfileService {
  final ProfileRepository repo;

  ProfileService({required this.repo});

  Future<ReUser> getUser(int userId) {
    return repo.fetchUser(userId);
  }

  Future<void> updateUser(ReUser user) {
    return repo.updateUser(user);
  }

  Future<List<ReUser>> getUsersByFirebaseUid(String firebaseUid) {
    return repo.fetchUsersByFirebaseUid(firebaseUid);
  }
}
