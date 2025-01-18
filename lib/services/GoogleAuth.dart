
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ScaffoldSnackbar {
  // ignore: public_member_api_docs
  ScaffoldSnackbar(this._context);

  /// The scaffold of current context.
  factory ScaffoldSnackbar.of(BuildContext context) {
    return ScaffoldSnackbar(context);
  }

  final BuildContext _context;

  /// Helper method to show a SnackBar.
  void show(String message) {
    ScaffoldMessenger.of(_context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
class AuthService {
  static final _instance = AuthService._();
  final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'https://www.googleapis.com/auth/drive.file', 'https://www.googleapis.com/auth/gmail.readonly'],
  );

  AuthService._();

  factory AuthService() {
    return _instance;
  }

  /// Sign in with Google
  /// returns auth-headers on success, else null
  Future<Map<String, String>?> googleSignIn() async {
    try {
      GoogleSignInAccount? googleAccount;
      if (_googleSignIn.currentUser == null) {
        googleAccount = await _googleSignIn.signIn();
      } else {
        googleAccount = await _googleSignIn.signInSilently();
      }

      return await googleAccount?.authHeaders;
    } catch (e) {
      return null;
    }
  }

  /// sign out google account
  Future<void> googleSignOut() => _googleSignIn.signOut();
}


class DriveClient implements http.BaseClient {
  final _client = http.Client();
  final Map<String, String> authHeaders;
  DriveClient(this.authHeaders);

  @override
  void close() {}

  @override
  Future<http.Response> delete(
      Uri url, {
        Map<String, String>? headers,
        Object? body,
        Encoding? encoding,
      }) {
    headers ??= {};
    headers.addAll(authHeaders);
    return _client.delete(
      url,
      headers: headers,
      body: body,
      encoding: encoding,
    );
  }

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    headers ??= {};
    headers.addAll(authHeaders);
    return _client.get(url, headers: headers);
  }

  @override
  Future<http.Response> head(Uri url, {Map<String, String>? headers}) {
    headers ??= {};
    headers.addAll(authHeaders);
    return _client.head(url, headers: headers);
  }

  @override
  Future<http.Response> patch(
      Uri url, {
        Map<String, String>? headers,
        Object? body,
        Encoding? encoding,
      }) {
    headers ??= {};
    headers.addAll(authHeaders);
    return _client.patch(url, headers: headers, body: body, encoding: encoding);
  }

  @override
  Future<http.Response> post(
      Uri url, {
        Map<String, String>? headers,
        Object? body,
        Encoding? encoding,
      }) {
    headers ??= {};
    headers.addAll(authHeaders);
    return _client.post(url, headers: headers, body: body, encoding: encoding);
  }

  @override
  Future<http.Response> put(
      Uri url, {
        Map<String, String>? headers,
        Object? body,
        Encoding? encoding,
      }) {
    headers ??= {};
    headers.addAll(authHeaders);
    return _client.put(url, headers: headers, body: body, encoding: encoding);
  }

  @override
  Future<String> read(Uri url, {Map<String, String>? headers}) {
    headers ??= {};
    headers.addAll(authHeaders);
    return _client.read(url, headers: headers);
  }

  @override
  Future<Uint8List> readBytes(Uri url, {Map<String, String>? headers}) {
    headers ??= {};
    headers.addAll(authHeaders);
    return _client.readBytes(url, headers: headers);
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(authHeaders);
    return _client.send(request);
  }
}