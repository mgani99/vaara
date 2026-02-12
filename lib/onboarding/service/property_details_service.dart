import 'dart:convert';
import 'package:http/http.dart' as http;

class PropertyDetailsService {
  final String apiKey;

  PropertyDetailsService({required this.apiKey});

  Future<PropertyDetails?> lookup(String address) async {
    final uri = Uri.parse(
      "https://api.estated.com/v4/property"
          "?token=$apiKey"
          "&address=${Uri.encodeComponent(address)}",
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) return null;

    final json = jsonDecode(response.body);

    if (json["status"] != "success") return null;

    return PropertyDetails.fromJson(json["data"]);
  }
}

class PropertyDetails {
  final String? propertyType;
  final int? bedrooms;
  final int? bathrooms;
  final int? squareFeet;
  final int? yearBuilt;
  final String? ownerName;

  PropertyDetails({
    this.propertyType,
    this.bedrooms,
    this.bathrooms,
    this.squareFeet,
    this.yearBuilt,
    this.ownerName,
  });

  factory PropertyDetails.fromJson(Map<String, dynamic> json) {
    final structure = json["structure"] ?? {};
    final owner = json["owner"] ?? {};

    return PropertyDetails(
      propertyType: json["property_type"],
      bedrooms: structure["beds"],
      bathrooms: structure["baths"],
      squareFeet: structure["total_area_sq_ft"],
      yearBuilt: structure["year_built"],
      ownerName: owner["owner1"]["full_name"],
    );
  }
}
