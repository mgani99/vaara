/// A minimal, clean, scalable base class for all domain objects.
/// Keeps shared behavior without forcing business fields.
abstract class BaseDomain {
  /// Every domain object in your SaaS has a unique integer ID.
  final int id;

  BaseDomain(this.id);

  /// Convert the domain object into a JSON map for Firebase.
  Map<String, dynamic> toJson();

  /// Returns the Firebase database path for this object.
  /// Example: "Users/123" or "Properties/45"
  String getObjDBLocation();
}
