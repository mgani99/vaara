// lib/domain/re_user.dart
class ReUser {
  final int userId;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final String profilePictureUrl;
  final String authProvider;
  final String firebaseUid;

  final List<dynamic> fcmTokens;

  final String status;
  final int createdAt;
  final int updatedAt;
  final int lastLoginAt;

  final String language;
  final String timezone;

  final bool emailNotifications;
  final bool smsNotifications;
  final bool pushNotifications;

  // Global onboarding flag (not org-specific)
  final bool onboardingCompleted;

  ReUser({
    required this.userId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.profilePictureUrl,
    required this.authProvider,
    required this.firebaseUid,
    required this.fcmTokens,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.lastLoginAt,
    required this.language,
    required this.timezone,
    required this.emailNotifications,
    required this.smsNotifications,
    required this.pushNotifications,
    this.onboardingCompleted = false,
  });

  factory ReUser.fromMap(Map<String, dynamic> map) {
    return ReUser(
      userId: map['userId'] as int,
      email: map['email'] ?? "",
      firstName: map['firstName'] ?? "",
      lastName: map['lastName'] ?? "",
      phone: map['phone'] ?? "",
      profilePictureUrl: map['profilePictureUrl'] ?? "",
      authProvider: map['authProvider'] ?? "password",
      firebaseUid: map['firebaseUid'] ?? "",
      fcmTokens: map['fcmTokens'] is List ? map['fcmTokens'] as List : const [],
      status: map['status'] ?? "active",
      createdAt: map['createdAt'] as int? ?? 0,
      updatedAt: map['updatedAt'] as int? ?? 0,
      lastLoginAt: map['lastLoginAt'] as int? ?? 0,
      language: map['language'] ?? "en",
      timezone: map['timezone'] ?? "America/New_York",
      emailNotifications: map['emailNotifications'] ?? true,
      smsNotifications: map['smsNotifications'] ?? false,
      pushNotifications: map['pushNotifications'] ?? true,
      onboardingCompleted: map['onboardingCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "userId": userId,
      "email": email,
      "firstName": firstName,
      "lastName": lastName,
      "phone": phone,
      "profilePictureUrl": profilePictureUrl,
      "authProvider": authProvider,
      "firebaseUid": firebaseUid,
      "fcmTokens": fcmTokens,
      "status": status,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
      "lastLoginAt": lastLoginAt,
      "language": language,
      "timezone": timezone,
      "emailNotifications": emailNotifications,
      "smsNotifications": smsNotifications,
      "pushNotifications": pushNotifications,
      "onboardingCompleted": onboardingCompleted,
    };
  }

  String get fullName => "$firstName $lastName";
  ReUser copyWith({
    int? userId,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? profilePictureUrl,
    String? authProvider,
    String? firebaseUid,
    List<String>? fcmTokens,
    String? status,
    int? createdAt,
    int? updatedAt,
    int? lastLoginAt,
    String? language,
    String? timezone,
    bool? emailNotifications,
    bool? smsNotifications,
    bool? pushNotifications,
    bool? onboardingCompleted,
  }) {
    return ReUser(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      authProvider: authProvider ?? this.authProvider,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      language: language ?? this.language,
      timezone: timezone ?? this.timezone,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
}




// lib/session/user_preferences.dart
class UserPreferences {
  final String userId;
  final String? defaultOrgId;
  final int updatedAt;

  UserPreferences({
    required this.userId,
    this.defaultOrgId,
    required this.updatedAt,
  });

  factory UserPreferences.fromMap(String userId, Map<String, dynamic> map) {
    return UserPreferences(
      userId: userId,
      defaultOrgId: map['defaultOrgId'],
      updatedAt: map['updatedAt'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'defaultOrgId': defaultOrgId,
      'updatedAt': updatedAt,
    };
  }

  UserPreferences copyWith({
    String? defaultOrgId,
    int? updatedAt,
  }) {
    return UserPreferences(
      userId: userId,
      defaultOrgId: defaultOrgId ?? this.defaultOrgId,
      updatedAt: updatedAt ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}
