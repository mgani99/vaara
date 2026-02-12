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

  // NEW FIELDS
  final bool onboardingCompleted;     // <--- NEW
  final String? defaultRole;          // <--- NEW (landlord/tenant/contractor)

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
    this.onboardingCompleted = false,   // default false
    this.defaultRole,                   // nullable
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

      // NEW FIELDS
      onboardingCompleted: map['onboardingCompleted'] ?? false,
      defaultRole: map['defaultRole'],
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

      // NEW FIELDS
      "onboardingCompleted": onboardingCompleted,
      "defaultRole": defaultRole,
    };
  }
}
