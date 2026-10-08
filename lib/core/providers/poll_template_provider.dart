import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stimmapp/core/data/repositories/poll_template_repository.dart';

final pollTemplateRepositoryProvider = FutureProvider.autoDispose
    .family<PollTemplateRepository, String>((ref, userId) async {
      return PollTemplateRepository(
        await SharedPreferences.getInstance(),
        userId,
      );
    });
