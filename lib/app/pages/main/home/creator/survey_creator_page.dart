import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  const SurveyCreatorPage({
    super.key,
    this.presentAsPoll = false,
    this.auth,
    this.groupRepository,
  });

  final bool presentAsPoll;
  final AuthService? auth;
  final PollGroupRepository? groupRepository;

  @override
  State<SurveyCreatorPage> createState() => _SurveyCreatorPageState();
}

class _SurveyCreatorPageState extends State<SurveyCreatorPage> {
  final _uuid = const Uuid();
  late final List<_QuestionDraft> _questions;
  final Map<String, PollGroup> _knownGroupsById = <String, PollGroup>{};
  String? _selectedGroupId;
  int _draftRevision = 0;

  AuthService get _auth => widget.auth ?? authService;
  PollGroupRepository get _groupRepository =>
      widget.groupRepository ?? PollGroupRepository.create();
  PollGroup? get _selectedGroup =>
      _selectedGroupId == null ? null : _knownGroupsById[_selectedGroupId];
  String get _specificDraftKey => widget.presentAsPoll
      ? 'draft_poll_specific_v1'
      : 'draft_survey_specific_v1';

  @override
  void initState() {
    super.initState();
    _questions = [_createQuestionDraft()];
    _restoreSpecificDraft();
  }

  _QuestionDraft _createQuestionDraft({
    String title = '',
    List<String>? options,
  }) {
    return _QuestionDraft(
      title: title,
      options: options,
      onChanged: _saveSpecificDraft,
    );
  }

  Future<void> _restoreSpecificDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_specificDraftKey);
    if (encoded == null) return;

    try {
      final data = jsonDecode(encoded) as Map<String, dynamic>;
      final rawQuestions = data['questions'] as List?;
      final restoredQuestions = rawQuestions
          ?.whereType<Map>()
          .take(AppLimits.maxSurveyQuestions)
          .map((rawQuestion) {
            final question = Map<String, dynamic>.from(rawQuestion);
            final options = (question['options'] as List?)
                ?.whereType<String>()
                .take(AppLimits.maxSurveyOptionsPerQuestion)
                .toList();
            return _createQuestionDraft(
              title: question['title'] as String? ?? '',
              options: options,
            );
          })
          .toList();
      if (!mounted) return;
      setState(() {
        if (restoredQuestions != null && restoredQuestions.isNotEmpty) {
          for (final question in _questions) {
            question.dispose();
          }
          _questions
            ..clear()
            ..addAll(restoredQuestions);
        }
        _selectedGroupId = data['groupId'] as String?;
      });
    } on FormatException catch (error) {
      debugPrint('Ignoring malformed poll draft: $error');
    } on TypeError catch (error) {
      debugPrint('Ignoring invalid poll draft: $error');
    }
  }

  Future<void> _saveSpecificDraft() async {
    final revision = ++_draftRevision;
    final encoded = jsonEncode({
      'groupId': _selectedGroupId,
      'questions': [
        for (final question in _questions)
          {
            'title': question.titleController.text,
            'options': [
              for (final controller in question.optionControllers)
                controller.text,
            ],
          },
      ],
    });
    final prefs = await SharedPreferences.getInstance();
    if (!mounted || revision != _draftRevision) return;
    await prefs.setString(_specificDraftKey, encoded);
  }

  Future<void> _clearSpecificDraft() async {
    _draftRevision++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_specificDraftKey);
  }

  void _resetSpecificFields() {
    setState(() {
      for (final question in _questions) {
        question.dispose();
      }
      _questions
        ..clear()
        ..add(_createQuestionDraft());
      _selectedGroupId = null;
    });
  }

  Future<void> _recordGroupPublication({
    required String actorUid,
    required String title,
  }) async {
    final group = _selectedGroup;
    if (group == null) {
      return;
    }
    try {
      final currentUser = _auth.currentUser;
      await _groupRepository.recordPublicationPublished(
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
    if (value == null || value == _selectedGroupId) {
      return;
    }
    if (value == _publicGroupValue) {
      setState(() {
        _selectedGroupId = null;
      });
      _saveSpecificDraft();
      return;
    }
    if (value == _manageGroupsValue) {
      await _openManageGroups();
      return;
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return;
    }
    final groups = await _groupRepository
        .watchGroupsForUser(currentUser.uid)
        .first;
    if (!mounted) {
      return;
    }
    for (final group in groups) {
      if (group.id == value) {
        setState(() {
          _selectedGroupId = group.id;
          _rememberGroups(<PollGroup>[group]);
        });
        _saveSpecificDraft();
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
    final currentUser = _auth.currentUser;
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
      stream: _groupRepository.watchGroupsForUser(currentUser.uid),
      builder: (context, snapshot) {
        final latestGroups = List<PollGroup>.from(
          snapshot.data ?? const <PollGroup>[],
        );
        if (latestGroups.isNotEmpty) {
          _rememberGroups(latestGroups);
        }
        final groups = _knownGroupsById.values.toList();
        final selectedValue = _knownGroupsById.containsKey(_selectedGroupId)
            ? _selectedGroupId!
            : _publicGroupValue;
        return KeyedSubtree(
          key: ValueKey(selectedValue),
          child: DropdownButtonFormField<String>(
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
          ),
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
      _questions.add(_createQuestionDraft());
    });
    _saveSpecificDraft();
  }

  void _removeQuestion(int index) {
    if (_questions.length == 1) {
      return;
    }
    setState(() {
      _questions[index].dispose();
      _questions.removeAt(index);
    });
    _saveSpecificDraft();
  }

  void _reorderQuestions(int oldIndex, int newIndex) {
    setState(() {
      final item = _questions.removeAt(oldIndex);
      _questions.insert(newIndex, item);
    });
    _saveSpecificDraft();
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
      question.addOption();
    });
    _saveSpecificDraft();
  }

  void _removeOption(_QuestionDraft question, int index) {
    setState(() {
      question.optionControllers[index].dispose();
      question.optionControllers.removeAt(index);
    });
    _saveSpecificDraft();
  }

  void _reorderOptions(_QuestionDraft question, int oldIndex, int newIndex) {
    setState(() {
      final item = question.optionControllers.removeAt(oldIndex);
      question.optionControllers.insert(newIndex, item);
    });
    _saveSpecificDraft();
  }

  Future<void> _createSurvey({
    required String title,
    required String description,
    required List<String> tags,
    required FormScope scope,
    required int durationDays,
    required bool openUntilClosed,
  }) async {
    final currentUser = _auth.currentUser;
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
      additionalDraftClearer: _clearSpecificDraft,
      onResetAdditionalFields: _resetSpecificFields,
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
  _QuestionDraft({
    required this.onChanged,
    String title = '',
    List<String>? options,
  }) : titleController = TextEditingController(text: title),
       optionControllers = _normalizedOptions(
         options,
       ).map((text) => TextEditingController(text: text)).toList() {
    titleController.addListener(onChanged);
    for (final controller in optionControllers) {
      controller.addListener(onChanged);
    }
  }

  final VoidCallback onChanged;
  final TextEditingController titleController;
  final List<TextEditingController> optionControllers;

  static List<String> _normalizedOptions(List<String>? options) {
    final normalized = List<String>.from(options ?? const <String>[]);
    while (normalized.length < 2) {
      normalized.add('');
    }
    return normalized;
  }

  void addOption() {
    final controller = TextEditingController()..addListener(onChanged);
    optionControllers.add(controller);
  }

  void dispose() {
    titleController.removeListener(onChanged);
    titleController.dispose();
    for (final controller in optionControllers) {
      controller.removeListener(onChanged);
      controller.dispose();
    }
  }
}
