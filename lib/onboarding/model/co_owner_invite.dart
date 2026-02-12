class CoOwnerInvite {
  final String orgId;
  final String invitedEmail;
  final double ownershipPercent;
  final String invitedBy;
  final int createdAt;

  CoOwnerInvite({
    required this.orgId,
    required this.invitedEmail,
    required this.ownershipPercent,
    required this.invitedBy,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "orgId": orgId,
      "invitedEmail": invitedEmail,
      "ownershipPercent": ownershipPercent,
      "invitedBy": invitedBy,
      "createdAt": createdAt,
      "role": "landlord",
    };
  }
}
