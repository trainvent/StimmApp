import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

final pidVerificationService = PidVerificationService();

class PidVerificationRequestResponse {
  const PidVerificationRequestResponse({
    required this.authorizationRequest,
    required this.verificationSessionId,
    required this.state,
    required this.expiresAt,
    required this.mode,
    required this.purpose,
  });

  final String authorizationRequest;
  final String verificationSessionId;
  final String state;
  final String expiresAt;
  final String mode;
  final String purpose;

  factory PidVerificationRequestResponse.fromJson(Map<String, dynamic> json) {
    return PidVerificationRequestResponse(
      authorizationRequest: (json['authorizationRequest'] ?? '').toString(),
      verificationSessionId: (json['verificationSessionId'] ?? '').toString(),
      state: (json['state'] ?? '').toString(),
      expiresAt: (json['expiresAt'] ?? '').toString(),
      mode: (json['mode'] ?? 'registration').toString(),
      purpose: (json['purpose'] ?? 'Registration verification').toString(),
    );
  }
}

class PidVerificationService {
  PidVerificationService({FirebaseAuth? auth, http.Client? client})
    : _auth = auth ?? FirebaseAuth.instance,
      _client = client ?? http.Client();

  final FirebaseAuth _auth;
  final http.Client _client;

  Future<PidVerificationRequestResponse> createRequest({
    required bool reverify,
    String? purpose,
    String? returnUrl,
  }) async {
    final token = await _auth.currentUser?.getIdToken();
    if (token == null) {
      throw const PidVerificationException(
        'You need to be signed in to verify your identity.',
      );
    }

    final projectId = Firebase.app().options.projectId;
    final response = await _client.post(
      Uri.parse('https://$projectId.web.app/oid4vp/start'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'mode': reverify ? 'reverification' : 'registration',
        'purpose': purpose,
        'returnUrl': returnUrl,
      }),
    );

    final decoded = jsonDecode(response.body);
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        decoded is! Map<String, dynamic>) {
      final message = decoded is Map<String, dynamic>
          ? decoded['error']?.toString()
          : null;
      throw PidVerificationException(
        message ?? 'The PID verifier is unavailable. Please try again.',
      );
    }

    final payload = decoded;
    return PidVerificationRequestResponse.fromJson(payload);
  }

  Future<PidVerificationStatusResponse> getStatus(String sessionId) async {
    final token = await _auth.currentUser?.getIdToken();
    if (token == null) {
      throw const PidVerificationException(
        'You need to be signed in to verify your identity.',
      );
    }

    final projectId = Firebase.app().options.projectId;
    final response = await _client.get(
      Uri.parse(
        'https://$projectId.web.app/oid4vp/status/${Uri.encodeComponent(sessionId)}',
      ),
      headers: {'Authorization': 'Bearer $token'},
    );
    final decoded = jsonDecode(response.body);
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        decoded is! Map<String, dynamic>) {
      final message = decoded is Map<String, dynamic>
          ? decoded['error']?.toString()
          : null;
      throw PidVerificationException(
        message ?? 'The PID verification status is unavailable.',
      );
    }
    return PidVerificationStatusResponse.fromJson(decoded);
  }

  Future<void> acceptVerifiedCredentials(String sessionId) async {
    final token = await _auth.currentUser?.getIdToken();
    if (token == null) {
      throw const PidVerificationException(
        'You need to be signed in to verify your identity.',
      );
    }

    final projectId = Firebase.app().options.projectId;
    final response = await _client.post(
      Uri.parse(
        'https://$projectId.web.app/oid4vp/accept/${Uri.encodeComponent(sessionId)}',
      ),
      headers: {'Authorization': 'Bearer $token'},
    );
    final decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['error']?.toString()
          : null;
      throw PidVerificationException(
        message ?? 'The verified PID could not be saved.',
      );
    }
  }
}

class PidVerificationStatusResponse {
  const PidVerificationStatusResponse({
    required this.status,
    required this.claims,
    this.error,
  });

  final String status;
  final Map<String, String?> claims;
  final String? error;

  bool get isFinished =>
      status == 'verified' || status == 'failed' || status == 'expired';

  factory PidVerificationStatusResponse.fromJson(Map<String, dynamic> json) {
    final rawClaims = json['claims'];
    return PidVerificationStatusResponse(
      status: (json['status'] ?? 'pending').toString(),
      claims: rawClaims is Map
          ? rawClaims.map(
              (key, value) => MapEntry(key.toString(), value?.toString()),
            )
          : const {},
      error: json['error']?.toString(),
    );
  }
}

class PidVerificationException implements Exception {
  const PidVerificationException(this.message);

  final String message;

  @override
  String toString() => message;
}
