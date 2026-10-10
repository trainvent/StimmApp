import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';
import 'package:stimmapp/core/data/models/public_profile.dart';
import 'package:stimmapp/core/data/repositories/public_profile_repository.dart';

final publicProfileRepositoryProvider = Provider<PublicProfileRepository>(
  (ref) => PublicProfileRepository(locator.databaseService),
);
final publicProfileProvider = StreamProvider.autoDispose
    .family<PublicProfile?, String>(
      (ref, uid) => ref.watch(publicProfileRepositoryProvider).watch(uid),
      dependencies: [publicProfileRepositoryProvider],
    );
final publicProfileFormsProvider = FutureProvider.autoDispose
    .family<List<PublicProfileForm>, String>(
      (ref, uid) =>
          ref.watch(publicProfileRepositoryProvider).publications(uid),
      dependencies: [publicProfileRepositoryProvider],
    );
