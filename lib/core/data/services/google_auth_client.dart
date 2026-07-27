import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

const _googleProfileScopes = <String>[
  'https://www.googleapis.com/auth/user.addresses.read',
  'https://www.googleapis.com/auth/user.birthday.read',
];

class GoogleProfileData {
  const GoogleProfileData({this.dateOfBirth, this.address});

  final DateTime? dateOfBirth;
  final String? address;

  bool get isEmpty => dateOfBirth == null && address == null;

  factory GoogleProfileData.fromPeopleApi(Map<String, dynamic> json) {
    return GoogleProfileData(
      dateOfBirth: _primaryBirthday(json['birthdays']),
      address: _primaryAddress(json['addresses']),
    );
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

  static String? _primaryAddress(Object? value) {
    final entries = _orderedEntries(value);
    for (final entry in entries) {
      final formatted = (entry['formattedValue'] as String?)?.trim();
      if (formatted != null && formatted.isNotEmpty) return formatted;

      final parts =
          <String?>[
            entry['streetAddress'] as String?,
            [entry['postalCode'] as String?, entry['city'] as String?]
                .whereType<String>()
                .where((part) => part.trim().isNotEmpty)
                .join(' '),
            entry['region'] as String?,
            entry['country'] as String?,
          ].whereType<String>().map((part) => part.trim()).where((part) {
            return part.isNotEmpty;
          }).toList();
      if (parts.isNotEmpty) return parts.join(', ');
    }
    return null;
  }

  static List<Map<String, dynamic>> _orderedEntries(Object? value) {
    if (value is! List) return const [];
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

  Future<GoogleProfileData> importProfileData();

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
  Future<GoogleProfileData> importProfileData() async {
    await _initialize();
    try {
      _currentAccount ??= await _googleSignIn
          .attemptLightweightAuthentication();
      final authorizationClient =
          _currentAccount?.authorizationClient ??
          _googleSignIn.authorizationClient;
      final authorization = await authorizationClient.authorizeScopes(
        _googleProfileScopes,
      );
      final response = await http.get(
        Uri.https('people.googleapis.com', '/v1/people/me', {
          'personFields': 'addresses,birthdays',
        }),
        headers: {
          'Authorization': 'Bearer ${authorization.accessToken}',
          'Accept': 'application/json',
        },
      );
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
