import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

const _googleProfileScopes = <String>[
  'https://www.googleapis.com/auth/userinfo.profile',
  'https://www.googleapis.com/auth/user.addresses.read',
  'https://www.googleapis.com/auth/user.birthday.read',
];

class GoogleProfileData {
  const GoogleProfileData({
    this.givenName,
    this.surname,
    this.displayName,
    this.dateOfBirth,
    this.address,
  });

  final String? givenName;
  final String? surname;
  final String? displayName;
  final DateTime? dateOfBirth;
  final String? address;

  bool get isEmpty =>
      givenName == null &&
      surname == null &&
      displayName == null &&
      dateOfBirth == null &&
      address == null;

  bool get hasCompleteSyncData =>
      givenName?.trim().isNotEmpty == true &&
      surname?.trim().isNotEmpty == true &&
      displayName?.trim().isNotEmpty == true &&
      dateOfBirth != null &&
      address?.trim().isNotEmpty == true;

  factory GoogleProfileData.fromPeopleApi(Map<String, dynamic> json) {
    final name = _primaryName(json['names']);
    return GoogleProfileData(
      givenName: name?['givenName'],
      surname: name?['familyName'],
      displayName: name?['displayName'],
      dateOfBirth: _primaryBirthday(json['birthdays']),
      address: _primaryLocation(json['locations']),
    );
  }

  static Map<String, String?>? _primaryName(Object? value) {
    final entries = _orderedEntries(value);
    for (final entry in entries) {
      final givenName = (entry['givenName'] as String?)?.trim();
      final surname = (entry['familyName'] as String?)?.trim();
      final displayName = (entry['displayName'] as String?)?.trim();
      if (givenName?.isNotEmpty == true ||
          surname?.isNotEmpty == true ||
          displayName?.isNotEmpty == true) {
        return <String, String?>{
          'givenName': givenName,
          'familyName': surname,
          'displayName': displayName,
        };
      }
    }
    return null;
  }

  static DateTime? _primaryBirthday(Object? value) {
    final entries = _orderedEntries(value);
    for (final entry in entries) {
      final date = entry['date'];
      if (date is! Map<String, dynamic>) continue;
      final year = date['year'];
      final month = date['month'];
      final day = date['day'];
      if (year is! int || month is! int || day is! int || year == 0) continue;
      try {
        final parsed = DateTime(year, month, day);
        if (parsed.year == year &&
            parsed.month == month &&
            parsed.day == day &&
            !parsed.isAfter(DateTime.now())) {
          return parsed;
        }
      } on ArgumentError {
        continue;
      }
    }
    return null;
  }

  static String? _primaryLocation(Object? value) {
    final entries = _orderedEntries(value);
    entries.sort((left, right) {
      final leftCurrent = left['current'] == true ? 0 : 1;
      final rightCurrent = right['current'] == true ? 0 : 1;
      final currentComparison = leftCurrent.compareTo(rightCurrent);
      if (currentComparison != 0) return currentComparison;

      final leftPrimary = _isPrimary(left) ? 0 : 1;
      final rightPrimary = _isPrimary(right) ? 0 : 1;
      return leftPrimary.compareTo(rightPrimary);
    });
    for (final entry in entries) {
      final location = (entry['value'] as String?)?.trim();
      if (location != null && location.isNotEmpty) return location;
    }
    return null;
  }

  static List<Map<String, dynamic>> _orderedEntries(Object? value) {
    if (value is! List) return <Map<String, dynamic>>[];
    final entries = value.whereType<Map<String, dynamic>>().toList();
    entries.sort((left, right) {
      final leftPrimary = _isPrimary(left) ? 0 : 1;
      final rightPrimary = _isPrimary(right) ? 0 : 1;
      return leftPrimary.compareTo(rightPrimary);
    });
    return entries;
  }

  static bool _isPrimary(Map<String, dynamic> entry) {
    final metadata = entry['metadata'];
    return metadata is Map<String, dynamic> && metadata['primary'] == true;
  }
}

class GoogleAuthIdentity {
  const GoogleAuthIdentity({required this.email, required this.idToken});

  final String email;
  final String? idToken;
}

abstract interface class GoogleAuthClient {
  Future<GoogleAuthIdentity> authenticate();

  Future<GoogleProfileData> importProfileData({bool promptIfNecessary = true});

  Future<void> signOut();
}

class GoogleSignInClient implements GoogleAuthClient {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  Future<void>? _initialization;
  GoogleSignInAccount? _currentAccount;

  Future<void> _initialize() {
    return _initialization ??= _googleSignIn.initialize();
  }

  @override
  Future<GoogleAuthIdentity> authenticate() async {
    await _initialize();
    try {
      final account = await _googleSignIn.authenticate();
      _currentAccount = account;
      return GoogleAuthIdentity(
        email: account.email,
        idToken: account.authentication.idToken,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const GoogleAuthCancelledException();
      }
      throw GoogleAuthClientException(
        code: e.code.name,
        message: e.description,
      );
    }
  }

  @override
  Future<GoogleProfileData> importProfileData({
    bool promptIfNecessary = true,
  }) async {
    await _initialize();
    try {
      _currentAccount ??= await _googleSignIn
          .attemptLightweightAuthentication();
      final authorizationClient =
          _currentAccount?.authorizationClient ??
          _googleSignIn.authorizationClient;
      final authorization =
          await authorizationClient.authorizationForScopes(
            _googleProfileScopes,
          ) ??
          (promptIfNecessary
              ? await authorizationClient.authorizeScopes(_googleProfileScopes)
              : null);
      if (authorization == null) {
        throw const GoogleProfileImportException(
          code: 'authorization-required',
          message: 'Google profile authorization requires user interaction.',
        );
      }
      final response = await http.get(
        Uri.https('people.googleapis.com', '/v1/people/me', {
          'personFields': 'names,locations,birthdays',
        }),
        headers: {
          'Authorization': 'Bearer ${authorization.accessToken}',
          'Accept': 'application/json',
        },
      );
      if (kDebugMode) {
        debugPrint(
          'Google People API import response (${response.statusCode}):',
        );
        debugPrint(_formatDebugResponseBody(response.body));
      }
      if (response.statusCode != 200) {
        throw GoogleProfileImportException(
          code: 'people-api-${response.statusCode}',
          message: _peopleApiErrorMessage(response.body),
        );
      }
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        throw const GoogleProfileImportException(
          code: 'invalid-response',
          message: 'Google returned an invalid profile response.',
        );
      }
      return GoogleProfileData.fromPeopleApi(body);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const GoogleProfileImportCancelledException();
      }
      throw GoogleProfileImportException(
        code: e.code.name,
        message: e.description ?? 'Google profile authorization failed.',
      );
    } on GoogleProfileImportException {
      rethrow;
    } on http.ClientException catch (e) {
      throw GoogleProfileImportException(
        code: 'network-error',
        message: e.message,
      );
    } on FormatException {
      throw const GoogleProfileImportException(
        code: 'invalid-response',
        message: 'Google returned an invalid profile response.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    if (_initialization == null) return;
    try {
      await _googleSignIn.signOut();
      _currentAccount = null;
    } on GoogleSignInException catch (e) {
      throw GoogleAuthClientException(
        code: e.code.name,
        message: e.description,
      );
    }
  }
}

String _formatDebugResponseBody(String responseBody) {
  try {
    return const JsonEncoder.withIndent('  ').convert(jsonDecode(responseBody));
  } on FormatException {
    return responseBody;
  }
}

String _peopleApiErrorMessage(String responseBody) {
  try {
    final decoded = jsonDecode(responseBody);
    if (decoded is Map<String, dynamic>) {
      final error = decoded['error'];
      if (error is Map<String, dynamic>) {
        final status = (error['status'] as String?)?.trim();
        final message = (error['message'] as String?)?.trim();
        if (status != null && status.isNotEmpty) {
          return message == null || message.isEmpty
              ? status
              : '$status: $message';
        }
        if (message != null && message.isNotEmpty) return message;
      }
    }
  } on FormatException {
    // Fall through to a safe generic error.
  }
  return 'Google profile data could not be loaded.';
}

class GoogleAuthCancelledException implements Exception {
  const GoogleAuthCancelledException();
}

class GoogleAuthClientException implements Exception {
  const GoogleAuthClientException({required this.code, this.message});

  final String code;
  final String? message;
}

class GoogleProfileImportException implements Exception {
  const GoogleProfileImportException({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;
}

class GoogleProfileImportCancelledException
    extends GoogleProfileImportException {
  const GoogleProfileImportCancelledException()
    : super(code: 'cancelled', message: 'Google profile import was cancelled.');
}
