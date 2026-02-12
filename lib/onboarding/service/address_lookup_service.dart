import 'dart:convert';
import 'package:http/http.dart' as http;

class AddressLookupService {
  static const _baseUrl = "https://nominatim.openstreetmap.org/search";

  /// Debounced search (you can wrap this in your UI)
  Future<List<AddressResult>> search(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse(
      "$_baseUrl?q=${Uri.encodeComponent(query)}"
          "&format=json&addressdetails=1&limit=5",
    );

    final response = await http.get(
      uri,
      headers: {
        "User-Agent": "RentalAI-App/1.0 (contact: support@rental.ai)"
      },
    );

    if (response.statusCode != 200) return [];

    final List data = jsonDecode(response.body);
    return data.map((e) => AddressResult.fromJson(e)).toList();
  }
}

class AddressResult {
  final String displayName;
  final double lat;
  final double lon;
  final Map<String, dynamic> address;

  AddressResult({
    required this.displayName,
    required this.lat,
    required this.lon,
    required this.address,
  });

  factory AddressResult.fromJson(Map<String, dynamic> json) {
    return AddressResult(
      displayName: json["display_name"] ?? "",
      lat: double.tryParse(json["lat"] ?? "0") ?? 0,
      lon: double.tryParse(json["lon"] ?? "0") ?? 0,
      address: json["address"] ?? {},
    );
  }
}
