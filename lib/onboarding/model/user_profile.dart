class UserProfile {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String? businessName;
  final int createdAt;

  UserProfile({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    this.businessName,
    required this.createdAt,
  });

  // ------------------------------------------------------------
  // FROM FIREBASE
  // ------------------------------------------------------------
  factory UserProfile.fromMap(String userId, Map<String, dynamic> map) {
    return UserProfile(
      userId: userId,
      name: map["name"] ?? "",
      email: map["email"] ?? "",
      phone: map["phone"] ?? "",
      businessName: map["businessName"],
      createdAt: map["createdAt"] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  // ------------------------------------------------------------
  // TO FIREBASE
  // ------------------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "email": email,
      "phone": phone,
      "businessName": businessName,
      "createdAt": createdAt,
    };
  }

  // ------------------------------------------------------------
  // COPY-WITH (for updates)
  // ------------------------------------------------------------
  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? businessName,
  }) {
    return UserProfile(
      userId: userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      businessName: businessName ?? this.businessName,
      createdAt: createdAt,
    );
  }
}
