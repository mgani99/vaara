import 'dart:convert';
import 'package:http/http.dart' as http;

class PlaidService {
  static const _baseUrl =
      "https://plaid-backend-302704940049.us-central1.run.app";
      //"http://127.0.0.1:8080";

  static Future<String?> createLinkToken({
    required String orgId,
    required String userId,
    required String bankName,
  }) async {
    final uri = Uri.parse("$_baseUrl/create_link_token").replace(
      queryParameters: {
        "orgId": orgId,
        "userId": userId,
      },
    );

    final res = await http.get(uri);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data["link_token"];
    }
    return null;
  }

  static Future<bool> exchangePublicToken({
    required String publicToken,
    required String orgId,
    required String userId,
    required String bankName,
  }) async {
    final res = await http.post(
      Uri.parse("$_baseUrl/exchange_public_token"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "public_token": publicToken,
        "orgId": orgId,
        "userId": userId,
      }),
    );

    return res.statusCode == 200;
  }

  static Future<Map<String, dynamic>> getBalance({
    required String orgId,
    required String userId,
    required String institutionName,
    required String mask,
    required String acctId
  }) async {
    try {
      final res = await http.post(
        Uri.parse("$_baseUrl/balance"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "orgId": orgId,
          "userId": userId,
          "institutionName": institutionName,
          "acctId": acctId,
        }),
      );

      // Backend error (400, 404, 429, 500, etc.)
      if (res.statusCode != 200) {
        return {
          "balance": null,
          "error": res.body, // ⭐ propagate backend error text
        };
      }

      final json = jsonDecode(res.body);


      final bal = json["balance"];
      if (bal is num) {
        return {
          "balance": bal.toDouble(),
          "error": null,
        };
      }

      return {
        "balance": null,
        "error": "Invalid balance format",
      };

    } catch (e) {
      return {
        "balance": null,
        "error": "Exception: $e", // ⭐ propagate exception
      };
    }
  }
  static Future<void> syncer({
    required String orgId,
  }) async {



    final res = await http.post(
      Uri.parse("$_baseUrl/syncer"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "orgId": orgId,

      }),
    );


  }


}
