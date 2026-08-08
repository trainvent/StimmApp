import 'package:flutter/material.dart';
import 'package:stimmapp/app/pages/main/home/base_detail_page.dart';
import 'package:stimmapp/app/widgets/buttons/sign_action_button.dart';
import 'package:stimmapp/app/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/data/models/survey.dart';
import 'package:stimmapp/core/data/repositories/moderation_repository.dart';
import 'package:stimmapp/core/data/repositories/survey_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/notifiers/quota_update_notifier.dart';

class SurveyDetailPage extends StatefulWidget {
  const SurveyDetailPage({super.key, required this.id});
  final String id;

  @override
  State<SurveyDetailPage> createState() => _SurveyDetailPageState();
}

class _SurveyDetailPageState extends State<SurveyDetailPage> {
  final Map<String, String> _selectedOptionIds = {};

  @override
  Widget build(BuildContext context) {
    final repo = SurveyRepository.create();
    final answerAllQuestionsMessage = context.l10n.answerAllSurveyQuestions;
    final participantIdsStream = repo.watchParticipantIds(widget.id);
    return BaseDetailPage<Survey>(
      id: widget.id,
      appBarTitle: context.l10n.surveyDetails,
      streamProvider: repo.watch,
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
      contentBuilder: (context, survey) {
        return ListView.separated(
          itemCount: survey.questions.length,
          separatorBuilder: (context, index) => const Divider(height: 24),
          itemBuilder: (context, index) {
            final question = survey.questions[index];
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
                    final pct = total == 0 ? 0 : (count / total * 100).round();
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(option.label)),
                          Text('$count • $pct%'),
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
      bottomAction: SignActionButton(
        submissionId: 'survey:${widget.id}',
        label: context.l10n.submitSurvey,
        participantIdsStream: participantIdsStream,
        onAction: ({String? reason}) async {
          final survey = await repo.get(widget.id);
          if (survey == null) return;
          final answers = {
            for (final question in survey.questions)
              if (_selectedOptionIds[question.id] != null)
                question.id: _selectedOptionIds[question.id]!,
          };
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
