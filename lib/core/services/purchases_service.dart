import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:stimmapp/app/mobile/widgets/selection_notifier_dialog.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:url_launcher/url_launcher.dart';

/*// on startup:
await PurchasesService.instance.init(apiKey: 'your_public_sdk_key');

// listen globally (e.g. in a provider or bloc):
PurchasesService.instance.entitlementStream.listen((status) {
  // update UI / state based on status
});

// show paywall:
await PurchasesService.instance.presentPaywall();

// check current entitlement synchronously:
final status = PurchasesService.instance.currentStatus;
*/

/// Simple enum for your app logic.
enum EntitlementStatus { none, active, expired, unknown }

enum EntitlementTier { free, basic, pro }

enum _WebPaymentOption { webBilling, googlePlay }

class PurchasesService {
  PurchasesService._internal();
  static final PurchasesService _instance = PurchasesService._internal();
  static PurchasesService get instance => _instance;

  /// Stream with the current entitlement status for the main entitlement.
  final _entitlementController = StreamController<EntitlementTier>.broadcast();

  Stream<EntitlementTier> get entitlementStream =>
      _entitlementController.stream;

  /// Last known status (cached in memory).
  EntitlementTier _currentStatus = EntitlementTier.free;
  EntitlementTier get currentStatus => _currentStatus;

  /// The entitlement identifiers you configured in RevenueCat.
  static const String _proEntitlementId = 'pro';
  static const String _basicEntitlementId = 'basic';

  bool _isInitialized = false;
  String? _appUserId;
  bool get isInitialized => _isInitialized;

  /// Call this early in app startup.
  Future<void> init({required String apiKey, String? appUserId}) async {
    if (_isInitialized) {
      log('PurchasesService already initialized. Skipping configuration.');
      return;
    }
    if (apiKey.isEmpty) {
      log('PurchasesService.init skipped: RevenueCat API key is empty.');
      return;
    }
    try {
      await Purchases.setLogLevel(LogLevel.debug);
      await Purchases.configure(
        PurchasesConfiguration(apiKey)..appUserID = appUserId,
      );

      _appUserId = appUserId;
      _isInitialized = true;

      // Listen to any customer info changes (restores, purchases, etc.).
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);

      // Fetch initial state.
      final info = await Purchases.getCustomerInfo();
      _onCustomerInfoUpdated(info);
    } catch (e, st) {
      log('PurchasesService.init error: $e\n$st');
    }
  }

  bool _ensureInitialized({String? action}) {
    if (_isInitialized) {
      return true;
    }
    log(
      'PurchasesService ${action ?? 'action'} skipped: SDK is not initialized.',
    );
    return false;
  }

  void _onCustomerInfoUpdated(CustomerInfo info) {
    try {
      if (!kReleaseMode) {
        final message =
            'RC customerInfo: appUserId=${info.originalAppUserId} '
            'activeEntitlements=${info.entitlements.active.keys.toList()} '
            'allEntitlements=${info.entitlements.all.keys.toList()} '
            'activeSubscriptions=${info.activeSubscriptions.toList()} '
            'allPurchasedProductIds=${info.allPurchasedProductIdentifiers.toList()}';
        log(message);
        debugPrint(message);
      }
      EntitlementTier tier = EntitlementTier.free;

      // Check for Pro first (highest tier)
      if (info.entitlements.all[_proEntitlementId]?.isActive == true) {
        tier = EntitlementTier.pro;
      } else if (info.entitlements.all[_basicEntitlementId]?.isActive == true) {
        tier = EntitlementTier.basic;
      } else if (kDebugMode && info.activeSubscriptions.isNotEmpty) {
        // Debug-only fallback: if RevenueCat entitlements aren't configured yet,
        // treat any active subscription as Pro so dev testing can proceed.
        tier = EntitlementTier.pro;
        log(
          'RC debug fallback: no entitlement matched, but activeSubscriptions '
          'is not empty -> treating as pro.',
        );
      }

      if (_currentStatus != tier) {
        _currentStatus = tier;
        _entitlementController.add(tier);
        log('Entitlement updated: $tier');
      }
    } catch (e, st) {
      log('PurchasesService._onCustomerInfoUpdated error: $e\n$st');
    }
  }

  /// Sync RevenueCat app user with Firebase user.
  Future<void> syncAppUser(String? uid) async {
    if (!_ensureInitialized(action: 'syncAppUser')) return;
    if (_appUserId == uid) return;

    try {
      if (uid == null) {
        await Purchases.logOut();
        _appUserId = null;
        _currentStatus = EntitlementTier.free;
        _entitlementController.add(_currentStatus);
        return;
      }

      final result = await Purchases.logIn(uid);
      _appUserId = uid;
      _onCustomerInfoUpdated(result.customerInfo);
    } catch (e, st) {
      log('PurchasesService.syncAppUser error: $e\n$st');
    }
  }

  /// Restore purchases (required for iOS).
  Future<void> restorePurchases() async {
    if (!_ensureInitialized(action: 'restorePurchases')) return;
    try {
      if (kIsWeb) {
        await refreshCustomerInfo();
        return;
      }
      final info = await Purchases.restorePurchases();
      _onCustomerInfoUpdated(info);
    } catch (e, st) {
      log('restorePurchases error: $e\n$st');
    }
  }

  /// Hosted paywall – returns true on success.
  Future<bool> presentPaywall({BuildContext? context}) async {
    if (kIsWeb) {
      return _presentWebPaywall(context: context);
    }
    if (!_ensureInitialized(action: 'presentPaywall')) {
      return false;
    }
    try {
      final result = await RevenueCatUI.presentPaywall();
      log('presentPaywall result: $result');
      await refreshCustomerInfo();
      return true;
    } catch (e, st) {
      log('presentPaywall error: $e\n$st');
      return false;
    }
  }

  /// Specific hosted paywall if needed – returns true on success.
  Future<bool> presentPaywallIfNeeded(
    String paywallId, {
    BuildContext? context,
  }) async {
    if (kIsWeb) {
      log(
        'RevenueCat Paywalls UI is not supported on Web. '
        'Falling back to package selection.',
      );
      return _presentWebPaywall(context: context);
    }
    if (!_ensureInitialized(action: 'presentPaywallIfNeeded')) {
      return false;
    }
    try {
      final result = await RevenueCatUI.presentPaywallIfNeeded(paywallId);
      log('presentPaywallIfNeeded($paywallId) result: $result');
      await refreshCustomerInfo();
      return true;
    } catch (e, st) {
      log('presentPaywallIfNeeded error: $e\n$st');
      return false;
    }
  }

  Future<bool> _presentWebPaywall({BuildContext? context}) async {
    if (!_isInitialized) {
      log('RevenueCat is not initialized on web. Missing web API key?');
      showErrorSnackBar('Web billing is not configured yet.');
      return false;
    }
    if (context == null) {
      log('Web paywall requested without BuildContext.');
      return false;
    }

    try {
      final selectedOption = await _selectWebPaymentOption(context);
      if (selectedOption == null) {
        return false;
      }
      if (selectedOption == _WebPaymentOption.googlePlay) {
        final uri = Uri.parse(
          'https://play.google.com/store/account/subscriptions',
        );
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          showErrorSnackBar('Could not open Google Play subscriptions.');
          return false;
        }
        return true;
      }

      final offerings = await Purchases.getOfferings();
      if (!context.mounted) {
        return false;
      }
      final offering = offerings.current;
      if (offering == null || offering.availablePackages.isEmpty) {
        showErrorSnackBar('No web billing products are available right now.');
        return false;
      }

      final selectedPackage = await _selectWebPackage(
        context,
        offering.availablePackages,
      );
      if (selectedPackage == null) {
        return false;
      }

      final result = await Purchases.purchase(
        PurchaseParams.package(selectedPackage),
      );
      _onCustomerInfoUpdated(result.customerInfo);
      await refreshCustomerInfo();
      return true;
    } on PlatformException catch (e, st) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        log('presentWebPaywall error: $e\n$st');
        showErrorSnackBar(e.message ?? 'Could not complete purchase.');
      }
      return false;
    } catch (e, st) {
      log('presentWebPaywall error: $e\n$st');
      showErrorSnackBar('Could not complete purchase.');
      return false;
    }
  }

  Future<_WebPaymentOption?> _selectWebPaymentOption(BuildContext context) async {
    final notifier = ValueNotifier<_WebPaymentOption?>(null);
    await showDialog(
      context: context,
      builder: (context) => SelectionNotifierDialog<_WebPaymentOption>(
        notifier: notifier,
        title: 'Select Payment Provider',
        options: _WebPaymentOption.values,
        optionLabel: (context, option) => switch (option) {
          _WebPaymentOption.webBilling => 'Web Billing',
          _WebPaymentOption.googlePlay => 'Google Play',
        },
      ),
    );
    return notifier.value;
  }

  Future<Package?> _selectWebPackage(
    BuildContext context,
    List<Package> packages,
  ) async {
    final notifier = ValueNotifier<Package?>(null);
    await showDialog(
      context: context,
      builder: (context) => SelectionNotifierDialog<Package>(
        notifier: notifier,
        title: 'Select Payment Provider',
        options: packages,
        optionLabel: (context, package) {
          final product = package.storeProduct;
          final period = product.subscriptionPeriod;
          final suffix = (period == null || period.isEmpty) ? '' : ' • $period';
          return '${product.title} (${product.priceString})$suffix';
        },
      ),
    );
    return notifier.value;
  }

  Future<Uri?> getManagementUri() async {
    if (!_ensureInitialized(action: 'getManagementUri')) {
      return null;
    }
    try {
      final info = await Purchases.getCustomerInfo();
      final url = info.managementURL;
      if (url == null || url.isEmpty) {
        return null;
      }
      return Uri.tryParse(url);
    } catch (e, st) {
      log('getManagementUri error: $e\n$st');
      return null;
    }
  }

  /// Convenience: refresh customer info and entitlement.
  Future<void> refreshCustomerInfo() async {
    if (!_ensureInitialized(action: 'refreshCustomerInfo')) return;
    try {
      final info = await Purchases.getCustomerInfo();
      _onCustomerInfoUpdated(info);
    } catch (e, st) {
      log('refreshCustomerInfo error: $e\n$st');
    }
  }

  /// Log out current user and clear state.
  Future<void> logOut() async {
    if (!_ensureInitialized(action: 'logOut')) {
      _currentStatus = EntitlementTier.free;
      _entitlementController.add(_currentStatus);
      return;
    }
    try {
      await Purchases.logOut();
      _currentStatus = EntitlementTier.free;
      _entitlementController.add(_currentStatus);
    } catch (e, st) {
      log('PurchasesService.logOut error: $e\n$st');
    }
  }

  /// Dispose when app shuts down (usually not necessary on mobile).
  Future<void> dispose() async {
    await _entitlementController.close();
  }
}
