import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:stimmapp/core/constants/german_states.dart';

class PlaceAddressInfo {
  const PlaceAddressInfo({
    this.state,
    this.countryCode,
    this.town,
    this.freeformAddress,
  });

  final String? state;
  final String? countryCode;
  final String? town;
  final String? freeformAddress;
}

class TomTomAddressSuggestion {
  const TomTomAddressSuggestion({
    required this.address,
    required this.info,
  });

  final String address;
  final PlaceAddressInfo info;
}

class TomTomSearchService {
  TomTomSearchService(this._apiKey);

  final Dio _dio = Dio();
  final String _apiKey;

  bool get hasApiKey => _apiKey.trim().isNotEmpty;

  Future<List<TomTomAddressSuggestion>> searchAddresses(
    String query, {
    List<String>? countries,
    int limit = 5,
  }) async {
    if (!hasApiKey || query.trim().length < 2) {
      return const [];
    }

    try {
      final encodedQuery = Uri.encodeComponent(query.trim());
      final response = await _dio.get(
        'https://api.tomtom.com/search/2/search/$encodedQuery.json',
        queryParameters: {
          'key': _apiKey,
          'typeahead': true,
          'limit': limit,
          'countrySet': (countries ?? const <String>[])
              .where((country) => country.trim().isNotEmpty)
              .join(','),
          'idxSet': 'PAD,Addr,Str',
          'language': 'en-US',
        },
      );

      final results = response.data['results'] as List<dynamic>? ?? const [];
      return results
          .map((item) {
            final map = item as Map<String, dynamic>;
            final address = (map['address'] as Map?)?.cast<String, dynamic>() ??
                const <String, dynamic>{};
            final info = _parseAddressInfo(address);
            final freeformAddress =
                (address['freeformAddress'] as String?)?.trim();
            final label = (freeformAddress != null && freeformAddress.isNotEmpty)
                ? freeformAddress
                : _buildFallbackLabel(address);
            if (label == null || label.isEmpty) {
              return null;
            }
            return TomTomAddressSuggestion(address: label, info: info);
          })
          .whereType<TomTomAddressSuggestion>()
          .toList();
    } catch (error) {
      debugPrint('TomTom address search failed: $error');
      return const [];
    }
  }

  Future<PlaceAddressInfo> resolveAddress(
    String query, {
    List<String>? countries,
  }) async {
    final suggestions = await searchAddresses(
      query,
      countries: countries,
      limit: 1,
    );
    if (suggestions.isEmpty) {
      return const PlaceAddressInfo();
    }
    return suggestions.first.info;
  }

  PlaceAddressInfo _parseAddressInfo(Map<String, dynamic> address) {
    final countryCode = (address['countryCode'] as String?)?.toUpperCase();
    final municipality = (address['municipality'] as String?)?.trim();
    final localName = (address['localName'] as String?)?.trim();
    final municipalitySubdivision =
        (address['municipalitySubdivision'] as String?)?.trim();
    final countrySecondarySubdivision =
        (address['countrySecondarySubdivision'] as String?)?.trim();
    final town = _pickTown(
      municipality: municipality,
      localName: localName,
      municipalitySubdivision: municipalitySubdivision,
      countrySecondarySubdivision: countrySecondarySubdivision,
    );
    final subdivisionName =
        (address['countrySubdivisionName'] as String?)?.trim();
    final subdivision = (address['countrySubdivision'] as String?)?.trim();

    return PlaceAddressInfo(
      state: _matchState(subdivisionName ?? subdivision),
      countryCode: countryCode,
      town: town,
      freeformAddress: (address['freeformAddress'] as String?)?.trim(),
    );
  }

  String? _pickTown({
    String? municipality,
    String? localName,
    String? municipalitySubdivision,
    String? countrySecondarySubdivision,
  }) {
    if (municipality != null && municipality.isNotEmpty) {
      return municipality;
    }
    if (localName != null && localName.isNotEmpty) {
      return localName;
    }
    if (municipalitySubdivision != null && municipalitySubdivision.isNotEmpty) {
      return municipalitySubdivision.split(',').first.trim();
    }
    if (countrySecondarySubdivision != null &&
        countrySecondarySubdivision.isNotEmpty) {
      return countrySecondarySubdivision;
    }
    return null;
  }

  String? _buildFallbackLabel(Map<String, dynamic> address) {
    final parts = <String>[
      if ((address['streetNumber'] as String?)?.trim().isNotEmpty == true)
        (address['streetNumber'] as String).trim(),
      if ((address['streetName'] as String?)?.trim().isNotEmpty == true)
        (address['streetName'] as String).trim(),
      if ((address['municipality'] as String?)?.trim().isNotEmpty == true)
        (address['municipality'] as String).trim(),
      if ((address['country'] as String?)?.trim().isNotEmpty == true)
        (address['country'] as String).trim(),
    ];
    if (parts.isEmpty) {
      return null;
    }
    return parts.join(', ');
  }

  String? _matchState(String? stateName) {
    if (stateName == null || stateName.trim().isEmpty) {
      return null;
    }

    final normalized = stateName.trim().toLowerCase();
    for (final state in germanStates) {
      if (state.toLowerCase() == normalized) {
        return state;
      }
    }

    final aliases = <String, String>{
      'be': 'Berlin',
      'bw': 'Baden-Wuerttemberg',
      'by': 'Bayern',
      'hb': 'Bremen',
      'hh': 'Hamburg',
      'he': 'Hessen',
      'mv': 'Mecklenburg-Vorpommern',
      'ni': 'Niedersachsen',
      'nw': 'Nordrhein-Westfalen',
      'rp': 'Rheinland-Pfalz',
      'sh': 'Schleswig-Holstein',
      'sl': 'Saarland',
      'sn': 'Sachsen',
      'st': 'Sachsen-Anhalt',
      'th': 'Thueringen',
    };
    if (aliases.containsKey(normalized)) {
      return germanStates.firstWhere(
        (state) =>
            state.toLowerCase() == aliases[normalized]!.toLowerCase() ||
            state
                .toLowerCase()
                .replaceAll('ü', 'u')
                .replaceAll('ä', 'a')
                .replaceAll('ö', 'o') ==
            aliases[normalized]!.toLowerCase(),
        orElse: () => aliases[normalized]!,
      );
    }

    if (normalized.contains('berlin')) return 'Berlin';
    if (normalized.contains('bayern') || normalized.contains('bavaria')) {
      return 'Bayern';
    }
    if (normalized.contains('bremen')) return 'Bremen';
    if (normalized.contains('hamburg')) return 'Hamburg';
    if (normalized.contains('hessen') || normalized.contains('hesse')) {
      return 'Hessen';
    }
    if (normalized.contains('niedersachsen') ||
        normalized.contains('lower saxony')) {
      return 'Niedersachsen';
    }
    if (normalized.contains('nordrhein-westfalen') ||
        normalized.contains('north rhine-westphalia')) {
      return 'Nordrhein-Westfalen';
    }
    if (normalized.contains('rheinland-pfalz') ||
        normalized.contains('rhineland-palatinate')) {
      return 'Rheinland-Pfalz';
    }
    if (normalized.contains('saarland')) return 'Saarland';
    if (normalized.contains('sachsen-anhalt') ||
        normalized.contains('saxony-anhalt')) {
      return 'Sachsen-Anhalt';
    }
    if (normalized.contains('sachsen') || normalized.contains('saxony')) {
      return 'Sachsen';
    }
    if (normalized.contains('schleswig-holstein')) {
      return 'Schleswig-Holstein';
    }
    if (normalized.contains('thuringia') ||
        normalized.contains('thueringen') ||
        normalized.contains('thüringen')) {
      return 'Thüringen';
    }
    if (normalized.contains('baden-württemberg') ||
        normalized.contains('baden-wuerttemberg')) {
      return 'Baden-Württemberg';
    }
    if (normalized.contains('brandenburg')) return 'Brandenburg';
    if (normalized.contains('mecklenburg-vorpommern')) {
      return 'Mecklenburg-Vorpommern';
    }

    return null;
  }
}
