import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stimmapp/core/data/repositories/questionnaire_template_repository.dart';

final questionnaireTemplateRepositoryProvider = FutureProvider.autoDispose
    .family<QuestionnaireTemplateRepository, String>((ref, userId) async {
      return QuestionnaireTemplateRepository(
        await SharedPreferences.getInstance(),
        userId,
      );
    });
