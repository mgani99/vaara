import 'dart:convert';
import 'package:http/http.dart' as http;

/// USPS State Abbreviation Map
const Map<String, String> usStateAbbreviations = {
  "Alabama": "AL", "Alaska": "AK", "Arizona": "AZ", "Arkansas": "AR",
  "California": "CA", "Colorado": "CO", "Connecticut": "CT", "Delaware": "DE",
  "Florida": "FL", "Georgia": "GA", "Hawaii": "HI", "Idaho": "ID",
  "Illinois": "IL", "Indiana": "IN", "Iowa": "IA", "Kansas": "KS",
  "Kentucky": "KY", "Louisiana": "LA", "Maine": "ME", "Maryland": "MD",
  "Massachusetts": "MA", "Michigan": "MI", "Minnesota": "MN",
  "Mississippi": "MS", "Missouri": "MO", "Montana": "MT", "Nebraska": "NE",
  "Nevada": "NV", "New Hampshire": "NH", "New Jersey": "NJ",
  "New Mexico": "NM", "New York": "NY", "North Carolina": "NC",
  "North Dakota": "ND", "Ohio": "OH", "Oklahoma": "OK", "Oregon": "OR",
  "Pennsylvania": "PA", "Rhode Island": "RI", "South Carolina": "SC",
  "South Dakota": "SD", "Tennessee": "TN", "Texas": "TX", "Utah": "UT",
  "Vermont": "VT", "Virginia": "VA", "Washington": "WA",
  "West Virginia": "WV", "Wisconsin": "WI", "Wyoming": "WY"
};

String abbreviateState(String state) => usStateAbbreviations[state] ?? state;

/// Extract street name (remove house number)
String extractStreetName(String street) {
  if (street.isEmpty) return "";
  final parts = street.split(" ");
  if (RegExp(r'^\d').hasMatch(parts.first)) parts.removeAt(0);
  return parts.join(" ").trim();
}

class AddressLookupService {
  static const _baseUrl = "https://nominatim.openstreetmap.org/search";

  Future<List<AddressResult>> search(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse(
        "$_baseUrl"
            "?q=${Uri.encodeComponent(query)}"
            "&format=json"
            "&addressdetails=1"
            "&limit=5"
            "&countrycodes=us"
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
  final String street;
  final String city;
  final String state;
  final String zip;
  final double lat;
  final double lon;

  AddressResult({
    required this.street,
    required this.city,
    required this.state,
    required this.zip,
    required this.lat,
    required this.lon,
  });

  String get formatted {
    final abbr = abbreviateState(state);
    return "$street, $city, $abbr - $zip";
  }

  factory AddressResult.fromJson(Map<String, dynamic> json) {
    final addr = json["address"] ?? {};

    final number = addr["house_number"] ?? "";
    final road = addr["road"] ?? "";
    final street = "$number $road".trim();

    final city = addr["city"] ??
        addr["town"] ??
        addr["village"] ??
        addr["hamlet"] ??
        "";

    return AddressResult(
      street: street,
      city: city,
      state: addr["state"] ?? "",
      zip: addr["postcode"] ?? "",
      lat: double.tryParse(json["lat"] ?? "0") ?? 0,
      lon: double.tryParse(json["lon"] ?? "0") ?? 0,
    );
  }
}
