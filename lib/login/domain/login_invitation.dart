class Invitation {
  final String inviteId;
  final String orgId;
  final String email;
  final String role; // landlord | tenant | contractor
  final Map<String, dynamic>? metadata;

  Invitation({
    required this.inviteId,
    required this.orgId,
    required this.email,
    required this.role,
    this.metadata,
  });

  factory Invitation.fromMap(String id, Map<String, dynamic> data) {
    return Invitation(
      inviteId: id,
      orgId: data['orgId'],
      email: data['email'],
      role: data['role'],
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orgId': orgId,
      'email': email,
      'role': role,
      'metadata': metadata,
    };
  }
}
