import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/providers/auth_provider.dart';
import 'package:stimmapp/core/services/purchases_service.dart';

/// Stream provider for the current entitlement status.
final entitlementStreamProvider = StreamProvider<EntitlementTier>((ref) {
  return PurchasesService.instance.entitlementStream;
});

/// A provider that listens to entitlement changes and updates the user's Firestore profile.
/// This should be watched at the root of the app (e.g. in AuthLayout or similar).
final subscriptionSyncProvider = Provider<void>((ref) {
  final authState = ref.watch(authStateProvider);
  final entitlementAsync = ref.watch(entitlementStreamProvider);

  // Only proceed if user is logged in and we have entitlement data
  if (authState.value == null || !entitlementAsync.hasValue) return;

  final user = authState.value!;
  final tier = entitlementAsync.value!;
  
  // We need to check the current profile to avoid infinite loops or unnecessary writes
  // But we can't easily "await" here inside a synchronous provider body.
  // Instead, we fire-and-forget an async update, but we should be careful.
  
  // Better approach: Use a side-effect.
  // However, providers shouldn't have side effects during build.
  // The correct way is to use a listener in a widget or a dedicated "Manager" class.
  
  // Let's just define the logic here and consume it in AuthLayout.
});

/// Logic to sync subscription status to Firestore.
/// Call this from a top-level widget's build method (via ref.listen) or useEffect.
Future<void> syncSubscriptionStatus(String uid, EntitlementTier tier) async {
  final repo = UserRepository.create();
  final profile = await repo.getById(uid);
  
  if (profile == null) return;

  final isPro = tier == EntitlementTier.pro;
  
  // Only update if changed
  if (profile.isPro != isPro) {
    await repo.upsert(profile.copyWith(
      isPro: isPro,
      wentProAt: isPro ? DateTime.now() : profile.wentProAt, // Keep original date if downgrading? Or null?
      // Usually you keep the history or update it. Let's say we update it on upgrade.
    ));
  }
}
