class OrgModel {
  final String orgId;
  final String name;
  final String type; // personal, llc, trust, partnership, other
  final int createdAt;

  OrgModel({
    required this.orgId,
    required this.name,
    required this.type,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "type": type,
      "createdAt": createdAt,
    };
  }

  factory OrgModel.fromMap(String orgId, Map<String, dynamic> map) {
    return OrgModel(
      orgId: orgId,
      name: map["name"] ?? "",
      type: map["type"] ?? "personal",
      createdAt: map["createdAt"] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}
