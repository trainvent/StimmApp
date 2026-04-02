import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:stimmapp/core/config/environment.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';

class BannerAdWrapper {
  final BannerAd? _ad;

  BannerAdWrapper(this._ad);

  bool get hasAd => _ad != null;

  Future<void> dispose() async => await _ad?.dispose();

  Widget build() {
    if (_ad == null) return const SizedBox.shrink();
    return AdWidget(ad: _ad);
  }
}

class AdService {
  static const String _androidTestBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _iosTestBannerAdUnitId =
      'ca-app-pub-3940256099942544/2934735716';
  static const String _androidTestInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _iosTestInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/4411468910';

  static final AdService _instance = AdService._internal();

  factory AdService() {
    return _instance;
  }

  AdService._internal();

  bool _mobileAdsInitialized = false;
  bool _canRequestAds = false;

  bool get isSupportedPlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  bool get canRequestAdsCached => _canRequestAds;

  void _logLoadAdError({
    required String adType,
    required String adUnitId,
    required LoadAdError error,
  }) {
    debugPrint(
      '[$adType] failed to load '
      '(unitId: $adUnitId, code: ${error.code}, domain: ${error.domain})',
    );
    debugPrint('[$adType] message: ${error.message}');
    debugPrint('[$adType] responseInfo: ${error.responseInfo}');
    final adapterResponses = error.responseInfo?.adapterResponses;
    if (adapterResponses != null && adapterResponses.isNotEmpty) {
      for (final adapterResponse in adapterResponses) {
        debugPrint('[$adType] adapterResponse: $adapterResponse');
      }
    }
  }

  Future<void> _initializeMobileAdsIfNeeded() async {
    if (_mobileAdsInitialized || !isSupportedPlatform) return;
    await MobileAds.instance.initialize();
    _mobileAdsInitialized = true;
  }

  Future<bool> initialize() async {
    if (!isSupportedPlatform) return false;
    final canRequestAds = await requestConsentInfoUpdateAndMaybeShowForm();
    if (canRequestAds) {
      await _initializeMobileAdsIfNeeded();
    }
    return canRequestAds;
  }

  Future<bool> requestConsentInfoUpdateAndMaybeShowForm() async {
    if (!isSupportedPlatform) {
      _canRequestAds = false;
      return false;
    }

    final completer = Completer<bool>();
    final params = ConsentRequestParameters();

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        try {
          await ConsentForm.loadAndShowConsentFormIfRequired((formError) {
            if (formError != null) {
              debugPrint(
                '[UMP] loadAndShowConsentFormIfRequired error '
                '(${formError.errorCode}): ${formError.message}',
              );
            }
          });
        } finally {
          final canRequestAds = await ConsentInformation.instance
              .canRequestAds();
          _canRequestAds = canRequestAds;
          if (canRequestAds) {
            await _initializeMobileAdsIfNeeded();
          }
          completer.complete(canRequestAds);
        }
      },
      (formError) async {
        debugPrint(
          '[UMP] requestConsentInfoUpdate error '
          '(${formError.errorCode}): ${formError.message}',
        );
        final canRequestAds = await ConsentInformation.instance.canRequestAds();
        _canRequestAds = canRequestAds;
        if (canRequestAds) {
          await _initializeMobileAdsIfNeeded();
        }
        completer.complete(canRequestAds);
      },
    );

    return completer.future;
  }

  Future<bool> showPrivacyOptionsFormIfRequired() async {
    if (!isSupportedPlatform) {
      _canRequestAds = false;
      return false;
    }

    final status = await ConsentInformation.instance
        .getPrivacyOptionsRequirementStatus();
    if (status == PrivacyOptionsRequirementStatus.required) {
      await ConsentForm.showPrivacyOptionsForm((formError) {
        if (formError != null) {
          debugPrint(
            '[UMP] showPrivacyOptionsForm error '
            '(${formError.errorCode}): ${formError.message}',
          );
        }
      });
    }

    final canRequestAds = await ConsentInformation.instance.canRequestAds();
    _canRequestAds = canRequestAds;
    if (canRequestAds) {
      await _initializeMobileAdsIfNeeded();
    }
    return canRequestAds;
  }

  Future<bool> isPrivacyOptionsRequired() async {
    if (!isSupportedPlatform) return false;
    final status = await ConsentInformation.instance
        .getPrivacyOptionsRequirementStatus();
    return status == PrivacyOptionsRequirementStatus.required;
  }

  String get bannerAdUnitId {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return '';
    if (Platform.isAndroid) {
      if (kDebugMode || Environment.isDev) return _androidTestBannerAdUnitId;
      return IConst.googleAdMobBannerAdUnitId;
    } else if (Platform.isIOS) {
      if (kDebugMode || Environment.isDev) return _iosTestBannerAdUnitId;
      return IConst.googleAdMobBannerAdUnitIdIos;
    }
    throw UnsupportedError("Unsupported platform");
  }

  String get interstitialAdUnitId {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return '';
    if (Platform.isAndroid) {
      if (kDebugMode || Environment.isDev) {
        return _androidTestInterstitialAdUnitId;
      }
      return 'ca-app-pub-5296065079333841/5826982633'; // Real Interstitial ID
    } else if (Platform.isIOS) {
      return _iosTestInterstitialAdUnitId;
    }
    throw UnsupportedError("Unsupported platform");
  }

  /// Creates and loads a Banner Ad.
  /// Don't forget to dispose the ad when the widget is disposed.
  BannerAdWrapper createBannerAd({
    required VoidCallback onAdLoaded,
    Function(String)? onAdFailedToLoad,
  }) {
    if (!isSupportedPlatform || !_canRequestAds) {
      return BannerAdWrapper(null);
    }

    final unitId = bannerAdUnitId;
    final banner = BannerAd(
      adUnitId: unitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => onAdLoaded(),
        onAdFailedToLoad: (ad, error) {
          _logLoadAdError(adType: 'BannerAd', adUnitId: unitId, error: error);
          ad.dispose();
          onAdFailedToLoad?.call(error.message);
        },
      ),
    );
    banner.load();
    return BannerAdWrapper(banner);
  }

  /// Loads an Interstitial Ad.
  void loadInterstitialAd({
    required void Function(InterstitialAd) onAdLoaded,
    void Function(LoadAdError)? onAdFailedToLoad,
  }) {
    if (!isSupportedPlatform || !_canRequestAds) return;

    final unitId = interstitialAdUnitId;
    InterstitialAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: (LoadAdError error) {
          _logLoadAdError(
            adType: 'InterstitialAd',
            adUnitId: unitId,
            error: error,
          );
          onAdFailedToLoad?.call(error);
        },
      ),
    );
  }
}
