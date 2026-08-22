import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stimmapp/core/constants/app_limits.dart';
import 'package:stimmapp/core/constants/database_collections.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';
import 'package:stimmapp/core/data/models/survey.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/database_service.dart';
import 'package:stimmapp/core/data/services/participant_profile_loader.dart';

class SurveyRepository {
  SurveyRepository(
    this._fs, {
    ParticipantProfileLoader? participantProfileLoader,
  }) : _participantProfileLoader =
           participantProfileLoader ??
           ParticipantProfileLoader(UserRepository(_fs));
  final DatabaseService _fs;
  final ParticipantProfileLoader _participantProfileLoader;

  static SurveyRepository create() => SurveyRepository(locator.databaseService);

  CollectionReference<Survey> _col() => _fs.colRef<Survey>(
    DatabaseCollections.surveys,
    fromFirestore: Survey.fromFirestore,
    toFirestore: Survey.toFirestore,
  );

  Stream<List<Survey>> list({
    String? query,
    int? limit,
    required String? status,
  }) {
    final q = (query ?? '').trim().toLowerCase();
    final queryRef = _col();

    Stream<List<Survey>> stream;
    if (q.isEmpty) {
      stream = _fs.watchCol<Survey>(
        queryRef.orderBy('createdAt', descending: true),
        limit: limit,
      );
    } else {
      stream = queryRef
          .where('titleLowercase', isGreaterThanOrEqualTo: q)
          .where('titleLowercase', isLessThan: '$q\uf8ff')
          .orderBy('titleLowercase')
          .snapshots()
          .map((snap) => snap.docs.map((doc) => doc.data()).toList());
    }

    return stream.map((surveys) {
      return status == null
          ? surveys
          : surveys.where((survey) => survey.status == status).toList();
    });
  }

  Stream<Survey?> watch(String id) {
    final ref = _fs.docRef<Survey>(
      '${DatabaseCollections.surveys}/$id',
      fromFirestore: Survey.fromFirestore,
      toFirestore: Survey.toFirestore,
    );
    return _fs.watchDoc(ref);
  }

  Future<Survey?> get(String id) async {
    final ref = _fs.docRef<Survey>(
      '${DatabaseCollections.surveys}/$id',
      fromFirestore: Survey.fromFirestore,
      toFirestore: Survey.toFirestore,
    );
    final snap = await ref.get();
    return snap.data();
  }

  Future<String> createSurvey(Survey survey) async {
    final normalizedSurvey = _normalizeSurvey(survey);
    final docRef = await _col().add(normalizedSurvey);
    return docRef.id;
  }

  Future<void> submitResponse({
    required String surveyId,
    required String uid,
    required Map<String, String> answers,
  }) async {
    if (answers.isEmpty) {
      throw StateError('invalid_survey_answers');
    }

    final db = locator.database;
    final surveyRef = db.collection(DatabaseCollections.surveys).doc(surveyId);
    final responseRef = surveyRef
        .collection(DatabaseCollections.responses)
        .doc(uid);
    final userRef = db.collection(DatabaseCollections.users).doc(uid);

    await db.runTransaction((txn) async {
      final surveySnap = await txn.get(surveyRef);
      if (!surveySnap.exists) {
        throw StateError('survey_not_found');
      }
      final responseSnap = await txn.get(responseRef);
      if (responseSnap.exists) {
        return;
      }

      final survey = Survey.fromFirestore(surveySnap, null);
      _validateAnswers(survey: survey, answers: answers);

      final update = <String, Object>{'responseCount': FieldValue.increment(1)};
      for (final entry in answers.entries) {
        update['questionVotes.${entry.key}.${entry.value}'] =
            FieldValue.increment(1);
      }

      txn.set(responseRef, {
        'uid': uid,
        'answers': answers,
        'submittedAt': FieldValue.serverTimestamp(),
      });
      txn.update(surveyRef, update);
      txn.set(userRef.collection('completedSurveys').doc(surveyId), {
        'surveyId': surveyId,
        'answers': answers,
        'submittedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> delete(String id) async {
    await _col().doc(id).delete();
  }

  Stream<List<UserProfile>> watchParticipants(String surveyId) {
    return watchParticipantIds(
      surveyId,
    ).asyncMap(_participantProfileLoader.load);
  }

  Stream<Set<String>> watchParticipantIds(String surveyId) {
    return _fs.instance
        .collection(DatabaseCollections.surveys)
        .doc(surveyId)
        .collection(DatabaseCollections.responses)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.id).toSet());
  }

  Stream<Set<String>> watchCompletedSurveyIds(String uid) {
    return _fs.instance
        .collection(DatabaseCollections.users)
        .doc(uid)
        .collection('completedSurveys')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.id).toSet());
  }

  Future<void> removeResponsesByUser(String uid) async {
    final db = _fs.instance;
    final completedSurveysSnap = await db
        .collection(DatabaseCollections.users)
        .doc(uid)
        .collection('completedSurveys')
        .get();

    await db.runTransaction((txn) async {
      for (final doc in completedSurveysSnap.docs) {
        final surveyId = doc.id;
        final answers = Map<String, dynamic>.from(
          doc.data()['answers'] as Map? ?? const <String, dynamic>{},
        );
        final surveyRef = db
            .collection(DatabaseCollections.surveys)
            .doc(surveyId);
        final update = <String, Object>{
          'responseCount': FieldValue.increment(-1),
        };

        for (final entry in answers.entries) {
          final optionId = entry.value;
          if (optionId is String) {
            update['questionVotes.${entry.key}.$optionId'] =
                FieldValue.increment(-1);
          }
        }

        txn.update(surveyRef, update);
        txn.delete(
          surveyRef.collection(DatabaseCollections.responses).doc(uid),
        );
        txn.delete(
          db
              .collection(DatabaseCollections.users)
              .doc(uid)
              .collection('completedSurveys')
              .doc(surveyId),
        );
      }
    });
  }

  Future<void> closeSurveysCreatedByUser(String uid) async {
    final batch = _fs.instance.batch();
    final createdSurveysSnap = await _col()
        .where('createdBy', isEqualTo: uid)
        .get();
    for (final doc in createdSurveysSnap.docs) {
      batch.update(doc.reference, {'status': 'closed'});
    }
    await batch.commit();
  }

  Future<void> scheduleClose(String id) async {
    await _col().doc(id).update({
      'status': IConst.closing,
      'scheduledCloseAt': Timestamp.fromDate(
        DateTime.now().add(AppLimits.formClosureGracePeriod),
      ),
    });
  }

  Future<void> resume(String id) async {
    final ref = _fs.instance.collection(DatabaseCollections.surveys).doc(id);
    await _fs.instance.runTransaction((transaction) async {
      final snap = await transaction.get(ref);
      final data = snap.data();
      final scheduledCloseAt = data?['scheduledCloseAt'] as Timestamp?;
      final expiresAt = data?['expiresAt'] as Timestamp?;
      final now = DateTime.now();
      if (data?['status'] != IConst.closing ||
          scheduledCloseAt == null ||
          !scheduledCloseAt.toDate().isAfter(now) ||
          (expiresAt != null && !expiresAt.toDate().isAfter(now))) {
        throw StateError('form_resume_window_expired');
      }
      transaction.update(ref, {
        'status': IConst.active,
        'scheduledCloseAt': FieldValue.delete(),
      });
    });
  }

  Survey _normalizeSurvey(Survey survey) {
    final normalizedTitle = survey.title.trim();
    final normalizedDescription = survey.description.trim();
    if (normalizedTitle.isEmpty ||
        normalizedTitle.length > AppLimits.maxTitleLength) {
      throw StateError('invalid_survey_title_length');
    }
    if (normalizedDescription.isEmpty ||
        normalizedDescription.length > AppLimits.maxDescriptionLength) {
      throw StateError('invalid_survey_description_length');
    }

    final normalizedQuestions = survey.questions
        .map((question) {
          final normalizedQuestionTitle = question.title.trim();
          final normalizedOptions = question.options
              .map(
                (option) =>
                    SurveyOption(id: option.id, label: option.label.trim()),
              )
              .where((option) => option.label.isNotEmpty)
              .toList(growable: false);

          return SurveyQuestion(
            id: question.id,
            title: normalizedQuestionTitle,
            options: normalizedOptions,
          );
        })
        .where((question) => question.title.isNotEmpty)
        .toList(growable: false);

    _validateQuestions(normalizedQuestions);

    return survey.copyWith(
      title: normalizedTitle,
      description: normalizedDescription,
      questions: normalizedQuestions,
      questionVotes: _initialQuestionVotes(
        normalizedQuestions,
        survey.questionVotes,
      ),
    );
  }

  void _validateQuestions(List<SurveyQuestion> questions) {
    if (questions.isEmpty ||
        questions.length > AppLimits.maxSurveyQuestions ||
        questions.any(
          (question) =>
              question.id.trim().isEmpty ||
              question.title.length > AppLimits.maxSurveyQuestionLength ||
              question.options.length < 2 ||
              question.options.length > AppLimits.maxSurveyOptionsPerQuestion ||
              question.options.any(
                (option) =>
                    option.id.trim().isEmpty ||
                    option.label.length > AppLimits.maxSurveyOptionLength,
              ),
        )) {
      throw StateError('invalid_survey_questions');
    }

    final questionIds = questions.map((question) => question.id).toSet();
    if (questionIds.length != questions.length) {
      throw StateError('duplicate_survey_question_ids');
    }

    for (final question in questions) {
      final optionIds = question.options.map((option) => option.id).toSet();
      if (optionIds.length != question.options.length) {
        throw StateError('duplicate_survey_option_ids');
      }
    }
  }

  Map<String, Map<String, int>> _initialQuestionVotes(
    List<SurveyQuestion> questions,
    Map<String, Map<String, int>> existingVotes,
  ) {
    return {
      for (final question in questions)
        question.id: {
          for (final option in question.options)
            option.id: existingVotes[question.id]?[option.id] ?? 0,
        },
    };
  }

  void _validateAnswers({
    required Survey survey,
    required Map<String, String> answers,
  }) {
    if (answers.length != survey.questions.length) {
      throw StateError('incomplete_survey_answers');
    }

    for (final question in survey.questions) {
      final optionId = answers[question.id];
      if (optionId == null ||
          !question.options.any((option) => option.id == optionId)) {
        throw StateError('invalid_survey_answers');
      }
    }
  }
}
