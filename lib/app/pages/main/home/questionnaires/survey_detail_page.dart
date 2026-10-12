import 'package:stimmapp/core/providers/public_profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trainvent_general/trainvent_general.dart';
import 'package:stimmapp/core/constants/app_limits.dart';
import 'package:stimmapp/app/pages/main/home/base_detail_page.dart';
import 'package:stimmapp/app/widgets/buttons/sign_action_button.dart';
import 'package:stimmapp/app/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/data/models/survey.dart';
import 'package:stimmapp/core/data/repositories/moderation_repository.dart';
import 'package:stimmapp/core/data/repositories/survey_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/notifiers/quota_update_notifier.dart';
import 'package:stimmapp/core/providers/auth_provider.dart';

class SurveyDetailPage extends ConsumerStatefulWidget {
  const SurveyDetailPage({super.key, required this.id});
  final String id;

  @override
  ConsumerState<SurveyDetailPage> createState() => _SurveyDetailPageState();
}

class _SurveyDetailPageState extends ConsumerState<SurveyDetailPage> {
  final Map<String, String> _selectedOptionIds = {};
  final Map<String, TextEditingController> _textControllers = {};

  @override
  void dispose() {
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = ref.watch(currentUserProvider)?.uid;
    final repo = SurveyRepository.create();
    final answerAllQuestionsMessage = context.l10n.answerAllSurveyQuestions;
    final participantIdsStream = repo.watchParticipantIds(
      widget.id,
      uid: currentUid,
    );
    return BaseDetailPage<Survey>(
      id: widget.id,
      appBarTitle: context.l10n.surveyDetails,
      streamProvider: repo.watch,
      publicProfileRepository: ref.watch(publicProfileRepositoryProvider),
      participantsStream: repo.watchParticipants(widget.id),
      participantIdsStream: participantIdsStream,
      sharePathSegment: 'survey',
      topRightActionBuilder: (context, survey) {
        final currentUid = authService.currentUser?.uid;
        if (currentUid == null) {
          return const SizedBox.shrink();
        }
        if (currentUid == survey.createdBy) {
          final canDelete = survey.responseCount == 0;
          return PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete') {
                await _deleteSurvey(context, survey);
              }
            },
            itemBuilder: (context) => canDelete
                ? [
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Text(context.l10n.deleteForm),
                    ),
                  ]
                : [
                    PopupMenuItem<String>(
                      enabled: false,
                      child: Text(context.l10n.noFittingOptions),
                    ),
                  ],
          );
        }
        return PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'report') {
              await BaseDetailPage.showReportDialog(
                context,
                item: survey,
                contentType: 'survey',
              );
            } else if (value == 'block') {
              await _confirmBlockUser(context, survey);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: 'report',
              child: Text(context.l10n.reportContent),
            ),
            PopupMenuItem<String>(
              value: 'block',
              child: Text(context.l10n.blockUser),
            ),
          ],
        );
      },
      contentBuilder: (context, survey) => StreamBuilder<Set<String>>(
        stream: participantIdsStream,
        builder: (context, snapshot) {
          final hasSubmitted =
              currentUid != null &&
              !snapshot.hasError &&
              snapshot.connectionState != ConnectionState.waiting &&
              (snapshot.data?.contains(currentUid) ?? false);
          return ListView.separated(
            itemCount: survey.questions.length,
            separatorBuilder: (context, index) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final question = survey.questions[index];
              if (question.isText) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      question.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      key: ValueKey('written_answer_${question.id}'),
                      controller: _textControllers.putIfAbsent(
                        question.id,
                        TextEditingController.new,
                      ),
                      minLines: 3,
                      maxLines: 6,
                      maxLength: AppLimits.maxSurveyTextAnswerLength,
                      decoration: InputDecoration(
                        labelText: context.l10n.yourWrittenAnswer,
                        helperText: context.l10n.writtenAnswerHint,
                        helperMaxLines: 3,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    if (authService.currentUser?.uid == survey.createdBy)
                      _WrittenResponses(
                        surveyId: survey.id,
                        questionId: question.id,
                      ),
                  ],
                );
              }
              final selectedOptionId = _selectedOptionIds[question.id];
              final total = survey.totalVotesForQuestion(question.id);
              return RadioGroup<String>(
                groupValue: selectedOptionId,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedOptionIds[question.id] = value);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...question.options.map((option) {
                      final count =
                          survey.questionVotes[question.id]?[option.id] ?? 0;
                      final pct = total == 0
                          ? 0
                          : (count / total * 100).round();
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(option.label)),
                            if (hasSubmitted) Text('$count • $pct%'),
                          ],
                        ),
                        leading: Radio<String>(value: option.id),
                        onTap: () {
                          setState(
                            () => _selectedOptionIds[question.id] = option.id,
                          );
                        },
                      );
                    }),
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomAction: SignActionButton(
        submissionId: 'survey:${widget.id}',
        label: context.l10n.submitSurvey,
        participantIdsStream: participantIdsStream,
        onAction: ({String? reason}) async {
          final survey = await repo.get(widget.id);
          if (survey == null) return;
          final answers = <String, String>{};
          for (final question in survey.questions) {
            final answer = question.isText
                ? _textControllers[question.id]?.text.trim()
                : _selectedOptionIds[question.id];
            if (answer != null && answer.isNotEmpty) {
              answers[question.id] = answer;
            }
          }
          if (answers.length != survey.questions.length) {
            throw StateError(answerAllQuestionsMessage);
          }
          final user = authService.currentUser!;
          await repo.submitResponse(
            surveyId: widget.id,
            uid: user.uid,
            answers: answers,
          );
          if (context.mounted) Navigator.pop(context);
        },
        successMessage: context.l10n.surveySubmitted,
      ),
    );
  }

  Future<void> _deleteSurvey(BuildContext context, Survey survey) async {
    if (survey.responseCount != 0) {
      showErrorSnackBar(context.l10n.cannotDeleteSurveyHasResponses);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteForm),
        content: Text(context.l10n.areYouSureYouWantToDeleteThisForm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.confirm),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    await SurveyRepository.create().delete(survey.id);
    QuotaUpdateNotifier.instance.notify();
    if (context.mounted) {
      showSuccessSnackBar(context.l10n.surveyDeleted);
      Navigator.of(context).pop();
    }
  }

  Future<void> _confirmBlockUser(BuildContext context, Survey survey) async {
    final shouldBlock = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.blockUser),
        content: Text(context.l10n.blockUserDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.blockUser),
          ),
        ],
      ),
    );

    if (shouldBlock != true) {
      return;
    }

    final blockerId = authService.currentUser?.uid;
    if (blockerId == null) {
      return;
    }

    await ModerationRepository.create().blockUser(
      blockerId: blockerId,
      blockedUserId: survey.createdBy,
      contentType: 'survey',
      contentId: survey.id,
      details: 'User blocked from survey detail page.',
    );
    if (context.mounted) {
      showSuccessSnackBar(context.l10n.userBlockedContentHidden);
      Navigator.of(context).pop();
    }
  }
}

final _writtenResponsesProvider = StreamProvider.autoDispose
    .family<List<Map<String, String>>, String>((ref, surveyId) {
      return SurveyRepository.create().watchTextResponses(surveyId);
    });

class _WrittenResponses extends ConsumerWidget {
  const _WrittenResponses({required this.surveyId, required this.questionId});
  final String surveyId;
  final String questionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ExpansionTile(
      title: Text(context.l10n.writtenResponses),
      children: [
        ref
            .watch(_writtenResponsesProvider(surveyId))
            .when(
              loading: () => const SizedBox(
                height: 48,
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: TriangleLoadingIndicator(),
                  ),
                ),
              ),
              error: (error, stack) =>
                  ListTile(title: Text(context.l10n.writtenResponsesError)),
              data: (responses) {
                final answers = responses
                    .map((response) => response[questionId])
                    .whereType<String>()
                    .toList();
                if (answers.isEmpty) {
                  return ListTile(title: Text(context.l10n.noWrittenResponses));
                }
                return Column(
                  children: [
                    for (final answer in answers)
                      ListTile(title: SelectableText(answer)),
                  ],
                );
              },
            ),
      ],
    );
  }
}
