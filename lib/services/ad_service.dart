import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:stimmapp/core/config/environment.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';

class BannerAdWrapper {
  final BannerAd? _ad;

  BannerAdWrapper(this._ad);

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

  Future<void> initialize() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    await MobileAds.instance.initialize();
  }

  String get bannerAdUnitId {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return '';
    if (Platform.isAndroid) {
      if (kDebugMode || Environment.isDev) return _androidTestBannerAdUnitId;
      return IConst.googleAdMobBannerAdUnitId;
    } else if (Platform.isIOS) {
      return _iosTestBannerAdUnitId;
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
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return BannerAdWrapper(null);
    }

    final banner = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => onAdLoaded(),
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd failed to load: $error');
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
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('InterstitialAd failed to load: $error');
          onAdFailedToLoad?.call(error);
        },
      ),
    );
  }
}
