import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:stimmapp/core/config/environment.dart';

final pidVerificationServiceProvider = Provider<PidVerificationService>((ref) {
  final service = PidVerificationService();
  ref.onDispose(service.dispose);
  return service;
});

class PidVerificationRequestResponse {
  const PidVerificationRequestResponse({
    required this.authorizationRequest,
    required this.verificationSessionId,
    required this.traceId,
    required this.state,
    required this.expiresAt,
    required this.mode,
    required this.purpose,
  });

  final String authorizationRequest;
  final String verificationSessionId;
  final String traceId;
  final String state;
  final String expiresAt;
  final String mode;
  final String purpose;

  factory PidVerificationRequestResponse.fromJson(Map<String, dynamic> json) {
    return PidVerificationRequestResponse(
      authorizationRequest: (json['authorizationRequest'] ?? '').toString(),
      verificationSessionId: (json['verificationSessionId'] ?? '').toString(),
      traceId: (json['traceId'] ?? '').toString(),
      state: (json['state'] ?? '').toString(),
      expiresAt: (json['expiresAt'] ?? '').toString(),
      mode: (json['mode'] ?? 'registration').toString(),
      purpose: (json['purpose'] ?? 'Registration verification').toString(),
    );
  }
}

class PidVerificationService {
  static const _requestTimeout = Duration(seconds: 15);

  PidVerificationService({FirebaseAuth? auth, http.Client? client})
    : _auth = auth ?? FirebaseAuth.instance,
      _client = client ?? http.Client();

  final FirebaseAuth _auth;
  final http.Client _client;

  void dispose() => _client.close();

  Future<PidResumableSession?> getResumableSession() async {
    final token = await _auth.currentUser?.getIdToken();
    if (token == null) {
      throw const PidVerificationException(
        'You need to be signed in to verify your identity.',
        code: 'unauthenticated',
      );
    }

    final projectId = Firebase.app().options.projectId;
    final response = await _get(
      Uri.parse('https://$projectId.web.app/oid4vp/resumable'),
      headers: {'Authorization': 'Bearer $token'},
      unavailableMessage:
          'The previous PID verification could not be restored.',
    );
    final decoded = _decodeResponse(
      response,
      'The previous PID verification could not be restored.',
    );
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        decoded is! Map<String, dynamic>) {
      final message = decoded is Map<String, dynamic>
          ? decoded['error']?.toString()
          : null;
      throw PidVerificationException(
        message ?? 'The previous PID verification could not be restored.',
        code: _errorCode(response, decoded),
      );
    }
    final session = decoded['session'];
    return session is Map<String, dynamic>
        ? PidResumableSession.fromJson(session)
        : null;
  }

  Future<PidVerificationRequestResponse> createRequest() async {
    final token = await _auth.currentUser?.getIdToken();
    if (token == null) {
      throw const PidVerificationException(
        'You need to be signed in to verify your identity.',
        code: 'unauthenticated',
      );
    }

    final projectId = Firebase.app().options.projectId;
    final response = await _post(
      Uri.parse('https://$projectId.web.app/oid4vp/start'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, Object?>{
        // The verifier persists this constrained source choice and only ever
        // returns to a server-approved destination.
        'returnTarget': kIsWeb ? 'web' : 'native',
        'brand': Environment.isVivot ? 'vivot' : 'stimmapp',
      }),
      unavailableMessage: 'The PID verifier is unavailable. Please try again.',
    );

    final decoded = _decodeResponse(
      response,
      'The PID verifier is unavailable. Please try again.',
    );
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        decoded is! Map<String, dynamic>) {
      final message = decoded is Map<String, dynamic>
          ? decoded['error']?.toString()
          : null;
      throw PidVerificationException(
        message ?? 'The PID verifier is unavailable. Please try again.',
        code: _errorCode(response, decoded),
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
        code: 'unauthenticated',
      );
    }

    final projectId = Firebase.app().options.projectId;
    // A PID session can change from pending to verified between two polls.
    // Make every read a fresh one: some browser/Hosting combinations otherwise
    // revalidate an earlier response as 304, which has no JSON body to parse.
    final statusUri =
        Uri.parse(
          'https://$projectId.web.app/oid4vp/status/${Uri.encodeComponent(sessionId)}',
        ).replace(
          queryParameters: {
            '_': DateTime.now().microsecondsSinceEpoch.toString(),
          },
        );
    final response = await _get(
      statusUri,
      headers: {'Authorization': 'Bearer $token', 'Cache-Control': 'no-store'},
      unavailableMessage: 'The PID verification status is unavailable.',
    );
    final decoded = _decodeResponse(
      response,
      'The PID verification status is unavailable.',
    );
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        decoded is! Map<String, dynamic>) {
      final message = decoded is Map<String, dynamic>
          ? decoded['error']?.toString()
          : null;
      throw PidVerificationException(
        message ?? 'The PID verification status is unavailable.',
        code: _errorCode(response, decoded),
      );
    }
    return PidVerificationStatusResponse.fromJson(decoded);
  }

  Future<void> acceptVerifiedCredentials(String sessionId) async {
    final token = await _auth.currentUser?.getIdToken();
    if (token == null) {
      throw const PidVerificationException(
        'You need to be signed in to verify your identity.',
        code: 'unauthenticated',
      );
    }

    final projectId = Firebase.app().options.projectId;
    final response = await _post(
      Uri.parse(
        'https://$projectId.web.app/oid4vp/accept/${Uri.encodeComponent(sessionId)}',
      ),
      headers: {'Authorization': 'Bearer $token'},
      unavailableMessage: 'The verified PID could not be saved.',
    );
    final decoded = _decodeResponse(
      response,
      'The verified PID could not be saved.',
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['error']?.toString()
          : null;
      throw PidVerificationException(
        message ?? 'The verified PID could not be saved.',
        code: _errorCode(response, decoded),
      );
    }
  }

  Future<String> cancelSession(String sessionId) async {
    final token = await _auth.currentUser?.getIdToken();
    if (token == null) {
      throw const PidVerificationException(
        'Authentication required',
        code: 'unauthenticated',
      );
    }
    final projectId = Firebase.app().options.projectId;
    final response = await _post(
      Uri.parse(
        'https://$projectId.web.app/oid4vp/cancel/${Uri.encodeComponent(sessionId)}',
      ),
      headers: {'Authorization': 'Bearer $token'},
      unavailableMessage: 'Cancellation failed',
    );
    final decoded = _decodeResponse(response, 'Cancellation failed');
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        decoded is! Map<String, dynamic>) {
      throw PidVerificationException(
        'Cancellation failed',
        code: _errorCode(response, decoded),
      );
    }
    return decoded['status']?.toString() ?? 'pending';
  }

  String _errorCode(http.Response response, dynamic decoded) {
    if (response.statusCode == 401) return 'unauthenticated';
    if (response.statusCode == 404) return 'session_not_found';
    if (decoded is Map && decoded['code'] is String) {
      return decoded['code'] as String;
    }
    if (response.statusCode == 409) return 'session_closed';
    if (response.statusCode == 422) return 'invalid_claims';
    return 'unavailable';
  }

  Future<http.Response> _get(
    Uri uri, {
    required Map<String, String> headers,
    required String unavailableMessage,
  }) => _withTimeout(_client.get(uri, headers: headers), unavailableMessage);

  Future<http.Response> _post(
    Uri uri, {
    required Map<String, String> headers,
    Object? body,
    required String unavailableMessage,
  }) => _withTimeout(
    _client.post(uri, headers: headers, body: body),
    unavailableMessage,
  );

  Future<http.Response> _withTimeout(
    Future<http.Response> request,
    String unavailableMessage,
  ) async {
    try {
      return await request.timeout(_requestTimeout);
    } on TimeoutException {
      throw const PidVerificationException(
        'Request timed out',
        code: 'timeout',
      );
    } on PidVerificationException {
      rethrow;
    } catch (_) {
      throw PidVerificationException(unavailableMessage);
    }
  }

  dynamic _decodeResponse(http.Response response, String unavailableMessage) {
    try {
      return jsonDecode(response.body);
    } catch (_) {
      throw PidVerificationException(unavailableMessage);
    }
  }
}

class PidVerificationStatusResponse {
  const PidVerificationStatusResponse({
    required this.status,
    required this.claims,
    required this.normalizedClaims,
    this.error,
  });

  final String status;
  final Map<String, String?> claims;
  final Map<String, String?> normalizedClaims;
  final String? error;

  bool get isFinished =>
      status == 'verified' ||
      status == 'accepted' ||
      status == 'failed' ||
      status == 'expired' ||
      status == 'cancelled';

  factory PidVerificationStatusResponse.fromJson(Map<String, dynamic> json) {
    final rawClaims = json['claims'];
    final rawNormalizedClaims = json['normalizedClaims'];
    return PidVerificationStatusResponse(
      status: (json['status'] ?? 'pending').toString(),
      claims: rawClaims is Map
          ? rawClaims.map(
              (key, value) => MapEntry(key.toString(), value?.toString()),
            )
          : const {},
      normalizedClaims: rawNormalizedClaims is Map
          ? rawNormalizedClaims.map(
              (key, value) => MapEntry(key.toString(), value?.toString()),
            )
          : const {},
      error: json['error']?.toString(),
    );
  }
}

class PidResumableSession {
  const PidResumableSession({
    required this.sessionId,
    required this.status,
    required this.mode,
    required this.purpose,
    required this.expiresAt,
  });

  final String sessionId;
  final String status;
  final String mode;
  final String purpose;
  final String expiresAt;

  factory PidResumableSession.fromJson(Map<String, dynamic> json) {
    return PidResumableSession(
      sessionId: (json['sessionId'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      mode: (json['mode'] ?? 'registration').toString(),
      purpose: (json['purpose'] ?? 'Registration verification').toString(),
      expiresAt: (json['expiresAt'] ?? '').toString(),
    );
  }
}

class PidVerificationException implements Exception {
  const PidVerificationException(this.message, {this.code = 'unavailable'});

  final String code;

  final String message;

  @override
  String toString() => message;
}
