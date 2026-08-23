import 'package:cloud_functions/cloud_functions.dart';

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

class PidVerificationResult {
  const PidVerificationResult({
    required this.verificationSessionId,
    required this.pidClaims,
    required this.verified,
  });

  final String verificationSessionId;
  final Map<String, dynamic> pidClaims;
  final Map<String, dynamic> verified;

  factory PidVerificationResult.fromJson(Map<String, dynamic> json) {
    final data = Map<String, dynamic>.from(json);
    return PidVerificationResult(
      verificationSessionId: (data['verificationSessionId'] ?? '').toString(),
      pidClaims: Map<String, dynamic>.from(data['pidClaims'] ?? const <String, dynamic>{}),
      verified: Map<String, dynamic>.from(data['verified'] ?? const <String, dynamic>{}),
    );
  }
}

class PidVerificationService {
  const PidVerificationService({FirebaseFunctions? functions})
      : _functions = functions;

  final FirebaseFunctions? _functions;

  FirebaseFunctions get functions => _functions ?? FirebaseFunctions.instance;

  Future<PidVerificationRequestResponse> createRequest({
    required bool reverify,
    String? purpose,
    String? returnUrl,
  }) async {
    final result = await functions
        .httpsCallable('createPidVerificationRequestCallable')
        .call<Map<String, dynamic>>({
          'mode': reverify ? 'reverification' : 'registration',
          'purpose': purpose,
          'returnUrl': returnUrl,
        });

    final payload = Map<String, dynamic>.from(result.data as Map);
    return PidVerificationRequestResponse.fromJson(payload);
  }

  Future<PidVerificationResult> verifyResponse({
    required String verificationSessionId,
    required Map<String, dynamic> authorizationResponse,
  }) async {
    final result = await functions
        .httpsCallable('verifyPidVerificationResponseCallable')
        .call<Map<String, dynamic>>({
          'verificationSessionId': verificationSessionId,
          'authorizationResponse': authorizationResponse,
        });

    final payload = Map<String, dynamic>.from(result.data as Map);
    return PidVerificationResult.fromJson(payload);
  }
}
