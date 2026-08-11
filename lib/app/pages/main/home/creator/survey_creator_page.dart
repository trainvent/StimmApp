import 'package:flutter/material.dart';
import 'package:stimmapp/app/pages/main/home/creator/base_creator_page.dart';
import 'package:stimmapp/app/pages/main/home/creator/widgets/choice_option_list_editor.dart';
import 'package:stimmapp/app/pages/main/groups/member_groups_page.dart';
import 'package:stimmapp/app/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/constants/app_limits.dart';
import 'package:stimmapp/core/constants/poll_tutorial_helper.dart';
import 'package:stimmapp/core/data/models/form_scope.dart';
import 'package:stimmapp/core/data/models/poll.dart';
import 'package:stimmapp/core/data/models/poll_group.dart';
import 'package:stimmapp/core/data/models/survey.dart';
import 'package:stimmapp/core/data/repositories/poll_repository.dart';
import 'package:stimmapp/core/data/repositories/poll_group_repository.dart';
import 'package:stimmapp/core/data/repositories/survey_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/data/services/content_moderation_service.dart';
import 'package:stimmapp/core/data/services/publishing_quota_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/services/analytics_service.dart';
import 'package:uuid/uuid.dart';

const String _publicGroupValue = '__public__';
const String _manageGroupsValue = '__manage_groups__';

class SurveyCreatorPage extends StatefulWidget {
  const SurveyCreatorPage({super.key, this.presentAsPoll = false});

  final bool presentAsPoll;

  @override
  State<SurveyCreatorPage> createState() => _SurveyCreatorPageState();
}

class _SurveyCreatorPageState extends State<SurveyCreatorPage> {
  final _uuid = const Uuid();
  final List<_QuestionDraft> _questions = [_QuestionDraft()];
  final Map<String, PollGroup> _knownGroupsById = <String, PollGroup>{};
  PollGroup? _selectedGroup;

  Future<void> _recordGroupPublication({
    required String actorUid,
    required String title,
  }) async {
    final group = _selectedGroup;
    if (group == null) {
      return;
    }
    try {
      final currentUser = authService.currentUser;
      await PollGroupRepository.create().recordPublicationPublished(
        groupId: group.id,
        actorUid: actorUid,
        actorDisplayName: currentUser?.displayName ?? currentUser?.email,
        title: title,
      );
    } catch (error, stackTrace) {
      debugPrint('Could not record group publication activity: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    for (final question in _questions) {
      question.dispose();
    }
    super.dispose();
  }

  Future<void> _openManageGroups() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (context) => const MemberGroupsPage()),
    );
  }

  Future<void> _handleGroupSelection(String? value) async {
    if (value == null || value == _selectedGroup?.id) {
      return;
    }
    if (value == _publicGroupValue) {
      setState(() {
        _selectedGroup = null;
      });
      return;
    }
    if (value == _manageGroupsValue) {
      await _openManageGroups();
      return;
    }

    final currentUser = authService.currentUser;
    if (currentUser == null) {
      return;
    }
    final groups = await PollGroupRepository.create()
        .watchGroupsForUser(currentUser.uid)
        .first;
    if (!mounted) {
      return;
    }
    for (final group in groups) {
      if (group.id == value) {
        setState(() {
          _selectedGroup = group;
          _rememberGroups(<PollGroup>[group]);
        });
        return;
      }
    }
  }

  void _rememberGroups(Iterable<PollGroup> groups) {
    for (final group in groups) {
      _knownGroupsById[group.id] = group;
    }
  }

  Widget _buildGroupSelector() {
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      return DropdownButtonFormField<String>(
        key: const Key('survey_group_dropdown'),
        initialValue: _publicGroupValue,
        decoration: InputDecoration(
          labelText: context.l10n.publishTo,
          border: const OutlineInputBorder(),
        ),
        items: [
          DropdownMenuItem<String>(
            value: _publicGroupValue,
            child: Text(context.l10n.public),
          ),
        ],
        onChanged: null,
      );
    }

    return StreamBuilder<List<PollGroup>>(
      stream: PollGroupRepository.create().watchGroupsForUser(currentUser.uid),
      builder: (context, snapshot) {
        final latestGroups = List<PollGroup>.from(
          snapshot.data ?? const <PollGroup>[],
        );
        if (latestGroups.isNotEmpty) {
          _rememberGroups(latestGroups);
        }
        final groups = _knownGroupsById.values.toList();
        if (_selectedGroup != null &&
            !_knownGroupsById.containsKey(_selectedGroup!.id)) {
          groups.insert(0, _selectedGroup!);
        }
        final selectedValue = _selectedGroup?.id ?? _publicGroupValue;
        return DropdownButtonFormField<String>(
          key: const Key('survey_group_dropdown'),
          initialValue: selectedValue,
          decoration: InputDecoration(
            labelText: context.l10n.publishTo,
            border: const OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem<String>(
              value: _publicGroupValue,
              child: Text(context.l10n.public),
            ),
            ...groups.map(
              (group) => DropdownMenuItem<String>(
                value: group.id,
                child: Text(group.name),
              ),
            ),
            DropdownMenuItem<String>(
              value: _manageGroupsValue,
              child: Text(context.l10n.createOrManageGroups),
            ),
          ],
          onChanged: _handleGroupSelection,
        );
      },
    );
  }

  void _addQuestion() {
    if (_questions.length >= AppLimits.maxSurveyQuestions) {
      showErrorSnackBar(
        context.l10n.maximumSurveyQuestionsAllowed(
          AppLimits.maxSurveyQuestions,
        ),
      );
      return;
    }
    setState(() {
      _questions.add(_QuestionDraft());
    });
  }

  void _removeQuestion(int index) {
    if (_questions.length == 1) {
      return;
    }
    setState(() {
      _questions[index].dispose();
      _questions.removeAt(index);
    });
  }

  void _reorderQuestions(int oldIndex, int newIndex) {
    setState(() {
      final item = _questions.removeAt(oldIndex);
      _questions.insert(newIndex, item);
    });
  }

  void _addOption(_QuestionDraft question) {
    if (question.optionControllers.length >=
        AppLimits.maxSurveyOptionsPerQuestion) {
      showErrorSnackBar(
        context.l10n.maximumPollOptionsAllowed(
          AppLimits.maxSurveyOptionsPerQuestion,
        ),
      );
      return;
    }
    setState(() {
      question.optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(_QuestionDraft question, int index) {
    setState(() {
      question.optionControllers[index].dispose();
      question.optionControllers.removeAt(index);
    });
  }

  void _reorderOptions(_QuestionDraft question, int oldIndex, int newIndex) {
    setState(() {
      final item = question.optionControllers.removeAt(oldIndex);
      question.optionControllers.insert(newIndex, item);
    });
  }

  Future<void> _createSurvey({
    required String title,
    required String description,
    required List<String> tags,
    required FormScope scope,
    required int durationDays,
    required bool openUntilClosed,
  }) async {
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      showErrorSnackBar(context.l10n.pleaseSignInFirst);
      return;
    }

    final moderationInputs = <String?>[
      title,
      description,
      ..._questions.map((question) => question.titleController.text),
      ..._questions.expand(
        (question) =>
            question.optionControllers.map((controller) => controller.text),
      ),
    ];
    if (ContentModerationService.instance.containsObjectionableContent(
      moderationInputs,
    )) {
      showErrorSnackBar(context.l10n.removeAbusiveLanguageBeforePublishing);
      return;
    }

    try {
      final questions = _questions
          .map((question) {
            final options = question.optionControllers
                .map(
                  (controller) => SurveyOption(
                    id: _uuid.v4(),
                    label: controller.text.trim(),
                  ),
                )
                .toList(growable: false);
            return SurveyQuestion(
              id: _uuid.v4(),
              title: question.titleController.text.trim(),
              options: options,
            );
          })
          .toList(growable: false);

      final now = DateTime.now();
      final isSingleQuestionPoll = questions.length == 1;
      if (isSingleQuestionPoll) {
        final question = questions.single;
        final poll = Poll(
          id: '',
          title: title,
          description: description,
          tags: tags,
          options: question.options
              .map((option) => PollOption(id: option.id, label: option.label))
              .toList(growable: false),
          votes: {for (final option in question.options) option.id: 0},
          createdBy: currentUser.uid,
          createdAt: now,
          expiresAt: openUntilClosed
              ? null
              : now.add(Duration(days: durationDays)),
          scope: scope,
          groupId: _selectedGroup?.id,
          groupName: _selectedGroup?.name,
          visibility: _selectedGroup == null ? 'public' : 'group',
        );

        final matchedTitles = await PollRepository.create()
            .list(query: poll.title, status: 'active')
            .first;
        final matchedTitle = matchedTitles.isNotEmpty
            ? matchedTitles.first.title
            : '';
        if (matchedTitle.isNotEmpty && matchedTitle == poll.title) {
          if (mounted) {
            showErrorSnackBar(context.l10n.petitionTitleInUseAlready);
          }
          return;
        }

        await PublishingQuotaService.instance.ensureCanCreatePoll();

        final pollId = await PollRepository.create().createPoll(poll);
        await _recordGroupPublication(
          actorUid: currentUser.uid,
          title: poll.title,
        );
        await AnalyticsService.instance.logPollCreated(
          scopeType: scope.firestoreType,
          visibility: poll.visibility,
          optionCount: poll.options.length,
        );

        if (mounted) {
          showSuccessSnackBar('${context.l10n.createdPoll} $pollId');
          Navigator.of(context).pop();
        }
        return;
      }

      final survey = Survey(
        id: '',
        title: title,
        description: description,
        tags: tags,
        questions: questions,
        questionVotes: {
          for (final question in questions)
            question.id: {for (final option in question.options) option.id: 0},
        },
        createdBy: currentUser.uid,
        createdAt: now,
        expiresAt: openUntilClosed
            ? null
            : now.add(Duration(days: durationDays)),
        scope: scope,
        groupId: _selectedGroup?.id,
        groupName: _selectedGroup?.name,
        visibility: _selectedGroup == null ? 'public' : 'group',
      );

      final matchedTitles = await SurveyRepository.create()
          .list(query: survey.title, status: 'active')
          .first;
      final matchedTitle = matchedTitles.isNotEmpty
          ? matchedTitles.first.title
          : '';
      if (matchedTitle.isNotEmpty && matchedTitle == survey.title) {
        if (mounted) showErrorSnackBar(context.l10n.petitionTitleInUseAlready);
        return;
      }

      await PublishingQuotaService.instance.ensureCanCreatePoll();

      final surveyId = await SurveyRepository.create().createSurvey(survey);
      await _recordGroupPublication(
        actorUid: currentUser.uid,
        title: survey.title,
      );
      await AnalyticsService.instance.logEvent(
        'survey_created',
        parameters: {
          'scope_type': scope.firestoreType,
          'visibility': survey.visibility,
          'question_count': questions.length,
        },
      );

      if (mounted) {
        showSuccessSnackBar('${context.l10n.createdSurvey} $surveyId');
        Navigator.of(context).pop();
      }
    } on StateError catch (error) {
      if (!mounted) {
        return;
      }
      if (error.message == 'poll_daily_limit_reached') {
        showErrorSnackBar(context.l10n.dailyCreateLimitReached);
      } else {
        final failureMessage = _questions.length == 1
            ? context.l10n.failedToCreatePoll
            : context.l10n.failedToCreateSurvey;
        showErrorSnackBar('$failureMessage: $error');
      }
    } catch (error) {
      if (mounted) {
        final failureMessage = _questions.length == 1
            ? context.l10n.failedToCreatePoll
            : context.l10n.failedToCreateSurvey;
        showErrorSnackBar('$failureMessage: $error');
      }
    }
  }

  Widget _buildQuestionCard(int index) {
    final question = _questions[index];
    return Card(
      key: ValueKey(question),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.questionNumber(index + 1),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (_questions.length > 1)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => _removeQuestion(index),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: question.titleController,
              maxLength: AppLimits.maxSurveyQuestionLength,
              decoration: InputDecoration(
                labelText: context.l10n.surveyQuestion,
                border: const OutlineInputBorder(),
              ),
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? context.l10n.questionRequired
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.options,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ChoiceOptionListEditor(
              controllers: question.optionControllers,
              maxOptionLength: AppLimits.maxSurveyOptionLength,
              optionLabelBuilder: (optionIndex) =>
                  context.l10n.optionNumber(optionIndex + 1),
              optionRequiredMessage: context.l10n.optionRequired,
              onReorder: (oldIndex, newIndex) =>
                  _reorderOptions(question, oldIndex, newIndex),
              onRemove: (optionIndex) => _removeOption(question, optionIndex),
            ),
            if (question.optionControllers.length <
                AppLimits.maxSurveyOptionsPerQuestion)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(context.l10n.addOption),
                  onPressed: () => _addOption(question),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseCreatorPage(
      title: widget.presentAsPoll
          ? context.l10n.createPoll
          : context.l10n.createSurvey,
      tutorialSteps: PollTutorialHelper.getSteps(context),
      onSubmit: _createSurvey,
      additionalTopFields: [_buildGroupSelector(), const SizedBox(height: 20)],
      additionalMiddleFields: [
        const SizedBox(height: 20),
        Text(
          context.l10n.questions,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _questions.length,
          onReorderItem: _reorderQuestions,
          buildDefaultDragHandles: false,
          itemBuilder: (context, index) => _buildQuestionCard(index),
        ),
        if (_questions.length < AppLimits.maxSurveyQuestions)
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: Text(context.l10n.addQuestion),
            onPressed: _addQuestion,
          ),
      ],
    );
  }
}

class _QuestionDraft {
  _QuestionDraft()
    : titleController = TextEditingController(),
      optionControllers = [TextEditingController(), TextEditingController()];

  final TextEditingController titleController;
  final List<TextEditingController> optionControllers;

  void dispose() {
    titleController.dispose();
    for (final controller in optionControllers) {
      controller.dispose();
    }
  }
}
