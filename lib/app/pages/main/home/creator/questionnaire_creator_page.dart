import 'package:stimmapp/core/data/models/form_import.dart';
import 'package:stimmapp/core/data/models/questionnaire.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stimmapp/core/data/models/form_template.dart';
import 'package:stimmapp/core/data/repositories/questionnaire_template_repository.dart';
import 'package:stimmapp/core/providers/questionnaire_template_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stimmapp/app/pages/main/home/creator/base_creator_page.dart';
import 'package:stimmapp/app/pages/main/home/creator/widgets/choice_option_list_editor.dart';
import 'package:stimmapp/app/pages/main/groups/groups_overview_page.dart';
import 'package:stimmapp/app/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/constants/app_limits.dart';
import 'package:stimmapp/core/constants/questionnaire_tutorial_helper.dart';
import 'package:stimmapp/core/data/models/form_scope.dart';
import 'package:stimmapp/core/data/models/poll.dart';
import 'package:stimmapp/core/data/models/questionnaire_group.dart';
import 'package:stimmapp/core/data/models/survey.dart';
import 'package:stimmapp/core/data/repositories/poll_repository.dart';
import 'package:stimmapp/core/data/repositories/questionnaire_group_repository.dart';
import 'package:stimmapp/core/data/repositories/survey_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/data/services/content_moderation_service.dart';
import 'package:stimmapp/core/data/services/publishing_quota_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/services/analytics_service.dart';
import 'package:uuid/uuid.dart';

enum _TemplateField {
  title,
  description,
  questions,
  tags,
  scope,
  duration,
  audience,
}

const String _publicGroupValue = '__public__';

class QuestionnaireCreatorPage extends ConsumerStatefulWidget {
  const QuestionnaireCreatorPage({
    super.key,
    this.initialTemplate,
    this.auth,
    this.groupRepository,
  });

  final FormTemplate? initialTemplate;
  final AuthService? auth;
  final QuestionnaireGroupRepository? groupRepository;

  @override
  ConsumerState<QuestionnaireCreatorPage> createState() =>
      _QuestionnaireCreatorPageState();
}

class _QuestionnaireCreatorPageState
    extends ConsumerState<QuestionnaireCreatorPage> {
  final _uuid = const Uuid();
  final _creatorKey = GlobalKey<BaseCreatorPageState>();
  late final List<_QuestionDraft> _questions;
  final Map<String, QuestionnaireGroup> _knownGroupsById =
      <String, QuestionnaireGroup>{};
  String? _selectedGroupId;
  int _draftRevision = 0;

  AuthService get _auth => widget.auth ?? authService;
  QuestionnaireGroupRepository get _groupRepository =>
      widget.groupRepository ?? QuestionnaireGroupRepository.create();
  bool get _isSingleQuestionPoll =>
      _questions.length == 1 &&
      _questions.single.type == QuestionnaireQuestionType.multipleChoice;

  QuestionnaireGroup? get _selectedGroup =>
      _selectedGroupId == null ? null : _knownGroupsById[_selectedGroupId];
  // Persisted preference identifier; both questionnaire types share this draft.
  static const _specificDraftKey = 'draft_poll_specific_v1';

  @override
  void initState() {
    super.initState();
    final templateQuestions = widget.initialTemplate?.questions;
    _questions = templateQuestions == null || templateQuestions.isEmpty
        ? <_QuestionDraft>[]
        : templateQuestions
              .map(
                (q) => _createQuestionDraft(
                  title: q.title,
                  type: q.type,
                  options: List.of(q.options),
                ),
              )
              .toList();
    if (widget.initialTemplate == null) _restoreSpecificDraft();
  }

  _QuestionDraft _createQuestionDraft({
    String title = '',
    QuestionnaireQuestionType type = QuestionnaireQuestionType.multipleChoice,
    List<String>? options,
  }) {
    return _QuestionDraft(
      title: title,
      type: type,
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
          .take(AppLimits.maxQuestionnaireQuestions)
          .map((rawQuestion) {
            final question = Map<String, dynamic>.from(rawQuestion);
            final type = question['type'] == 'text'
                ? QuestionnaireQuestionType.text
                : QuestionnaireQuestionType.multipleChoice;
            final options = (question['options'] as List?)
                ?.whereType<String>()
                .take(AppLimits.maxQuestionnaireOptionsPerQuestion)
                .toList();
            return _createQuestionDraft(
              title: question['title'] as String? ?? '',
              type: type,
              options: type == QuestionnaireQuestionType.text
                  ? const []
                  : options,
            );
          })
          .toList();
      if (!mounted) return;
      setState(() {
        if (restoredQuestions != null) {
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
            'type': question.type.name,
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
      _questions.clear();
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
      MaterialPageRoute(builder: (context) => const GroupsOverviewPage()),
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
          _rememberGroups(<QuestionnaireGroup>[group]);
        });
        _saveSpecificDraft();
        return;
      }
    }
  }

  void _rememberGroups(Iterable<QuestionnaireGroup> groups) {
    for (final group in groups) {
      _knownGroupsById[group.id] = group;
    }
  }

  Widget _buildGroupSelector() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return DropdownButtonFormField<String>(
        key: const Key('survey_group_dropdown'),
        isExpanded: true,
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

    return StreamBuilder<List<QuestionnaireGroup>>(
      stream: _groupRepository.watchGroupsForUser(currentUser.uid),
      builder: (context, snapshot) {
        final latestGroups = List<QuestionnaireGroup>.from(
          snapshot.data ?? const <QuestionnaireGroup>[],
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
            isExpanded: true,
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
                  child: Text(group.name, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: _handleGroupSelection,
          ),
        );
      },
    );
  }

  void _addQuestion(QuestionnaireQuestionType type) {
    if (_questions.length >= AppLimits.maxQuestionnaireQuestions) {
      showUserMistakeSnackBar(
        context.l10n.maximumQuestionnaireQuestionsAllowed(
          AppLimits.maxQuestionnaireQuestions,
        ),
      );
      return;
    }
    setState(() {
      _questions.add(_createQuestionDraft(type: type));
    });
    _saveSpecificDraft();
  }

  void _removeQuestion(int index) {
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
        AppLimits.maxQuestionnaireOptionsPerQuestion) {
      showUserMistakeSnackBar(
        context.l10n.maximumPollOptionsAllowed(
          AppLimits.maxQuestionnaireOptionsPerQuestion,
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

  Future<bool> _createQuestionnaire({
    required String title,
    required String description,
    required List<String> tags,
    required FormScope scope,
    required int durationDays,
    required bool openUntilClosed,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      showUserMistakeSnackBar(context.l10n.pleaseSignInFirst);
      return false;
    }

    final moderationInputs = <String?>[
      title,
      description,
      ..._questions.map((question) => question.titleController.text),
      ..._questions.expand(
        (question) => question.type == QuestionnaireQuestionType.text
            ? <String>[]
            : question.optionControllers.map((controller) => controller.text),
      ),
    ];
    if (ContentModerationService.instance.containsObjectionableContent(
      moderationInputs,
    )) {
      showUserMistakeSnackBar(
        context.l10n.removeAbusiveLanguageBeforePublishing,
      );
      return false;
    }

    try {
      final questions = _questions
          .map((question) {
            final options = question.optionControllers
                .map(
                  (controller) => QuestionnaireOption(
                    id: _uuid.v4(),
                    label: controller.text.trim(),
                  ),
                )
                .toList(growable: false);
            return QuestionnaireQuestion(
              id: _uuid.v4(),
              title: question.titleController.text.trim(),
              options: question.type == QuestionnaireQuestionType.text
                  ? const []
                  : options,
              type: question.type,
            );
          })
          .toList(growable: false);

      final now = DateTime.now();
      if (_isSingleQuestionPoll) {
        final question = questions.single;
        final poll = Poll(
          id: '',
          questionTitle: question.title,
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
            showUserMistakeSnackBar(context.l10n.petitionTitleInUseAlready);
          }
          return false;
        }

        await PublishingQuotaService.instance.ensureCanCreateQuestionnaire();

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
        }
        return true;
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
        if (mounted) {
          showUserMistakeSnackBar(context.l10n.petitionTitleInUseAlready);
        }
        return false;
      }

      await PublishingQuotaService.instance.ensureCanCreateQuestionnaire();

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
      }
      return true;
    } on StateError catch (error) {
      if (!mounted) {
        return false;
      }
      if (error.message == 'questionnaire_daily_limit_reached') {
        showUserMistakeSnackBar(context.l10n.dailyCreateLimitReached);
      } else {
        final failureMessage = _isSingleQuestionPoll
            ? context.l10n.failedToCreatePoll
            : context.l10n.failedToCreateSurvey;
        showErrorSnackBar('$failureMessage: $error');
      }
    } catch (error) {
      if (mounted) {
        final failureMessage = _isSingleQuestionPoll
            ? context.l10n.failedToCreatePoll
            : context.l10n.failedToCreateSurvey;
        showErrorSnackBar('$failureMessage: $error');
      }
    }
    return false;
  }

  Future<bool> _confirmReplacement(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            content: Text(message),
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
        ) ??
        false;
  }

  Future<void> _saveTemplate(
    TextEditingController title,
    TextEditingController description,
  ) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    late final QuestionnaireTemplateRepository repository;
    try {
      repository = await ref.read(
        questionnaireTemplateRepositoryProvider(userId).future,
      );
      repository.load();
    } catch (_) {
      if (mounted) showErrorSnackBar(context.l10n.formTemplateError);
      return;
    }
    if (!mounted) return;
    final nameController = TextEditingController(text: title.text.trim());
    final included = _TemplateField.values.toSet();
    final settings = _creatorKey.currentState!.templateSettings;
    final labels = <_TemplateField, String>{
      _TemplateField.title: context.l10n.title,
      _TemplateField.description: context.l10n.description,
      _TemplateField.questions: context.l10n.formTemplateQuestionsAndAnswers,
      _TemplateField.tags: context.l10n.tags,
      _TemplateField.scope: context.l10n.scope,
      _TemplateField.duration: context.l10n.duration,
      _TemplateField.audience: context.l10n.publishTo,
    };
    FocusManager.instance.primaryFocus?.unfocus();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(context.l10n.saveFormTemplate),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              // Outlined floating labels extend above the field's bounds.
              // Keep them inside the scroll viewport, even with the keyboard open.
              padding: EdgeInsets.fromLTRB(
                4,
                MediaQuery.textScalerOf(context).scale(12),
                4,
                8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    maxLength: AppLimits.maxTitleLength,
                    onChanged: (_) => update(() {}),
                    decoration: InputDecoration(
                      labelText: context.l10n.formTemplateName,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(context.l10n.formTemplateIncludeFields),
                  for (final field in _TemplateField.values)
                    CheckboxListTile(
                      key: ValueKey('template_field_${field.name}'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(labels[field]!),
                      value: included.contains(field),
                      onChanged: (value) => update(() {
                        if (value == true) {
                          included.add(field);
                        } else {
                          included.remove(field);
                        }
                      }),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: nameController.text.trim().isEmpty || included.isEmpty
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      if (repository.containsName(name)) {
                        final confirmed = await _confirmReplacement(
                          context.l10n.formTemplateOverwriteConfirmation,
                        );
                        if (!confirmed) return;
                      }
                      if (context.mounted) Navigator.pop(context, name);
                    },
              child: Text(
                repository.containsName(nameController.text)
                    ? context.l10n.formTemplateReplaceAction
                    : context.l10n.confirm,
              ),
            ),
          ],
        ),
      ),
    );
    // Let the closing dialog finish using its text controller.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => nameController.dispose(),
    );
    if (name == null || !mounted) return;
    final template = FormTemplate(
      id: _uuid.v4(),
      name: name,
      title: included.contains(_TemplateField.title) ? title.text : null,
      description: included.contains(_TemplateField.description)
          ? description.text
          : null,
      tags: included.contains(_TemplateField.tags) ? settings.tags : null,
      scopeType: included.contains(_TemplateField.scope)
          ? settings.scopeType
          : null,
      countryUnion: included.contains(_TemplateField.scope)
          ? settings.countryUnion
          : null,
      durationDays: included.contains(_TemplateField.duration)
          ? settings.durationDays
          : null,
      openUntilClosed: included.contains(_TemplateField.duration)
          ? settings.openUntilClosed
          : null,
      includesAudience: included.contains(_TemplateField.audience),
      groupId: included.contains(_TemplateField.audience)
          ? _selectedGroupId
          : null,
      questions: included.contains(_TemplateField.questions)
          ? [
              for (final question in _questions)
                FormTemplateQuestion(
                  title: question.titleController.text,
                  type: question.type,
                  options: [
                    for (final option in question.optionControllers)
                      option.text,
                  ],
                ),
            ]
          : null,
    );
    try {
      await repository.save(template);
      if (mounted) showSuccessSnackBar(context.l10n.formTemplateSaved);
    } catch (_) {
      if (mounted) showErrorSnackBar(context.l10n.formTemplateError);
    }
  }

  String _templateSummary(FormTemplate template) {
    final l = context.l10n;
    return [
      if (template.title != null) l.title,
      if (template.description != null) l.description,
      if (template.questions != null)
        l.templateQuestionCount(template.questions!.length),
      if (template.tags != null) l.tags,
      if (template.scopeType != null) l.geographicalScope,
      if (template.durationDays != null || template.openUntilClosed != null)
        l.duration,
      if (template.includesAudience) l.publishTo,
    ].join(' · ');
  }

  Widget _buildPublicationPreview(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          _selectedGroup == null ? Icons.public : Icons.group_outlined,
        ),
        title: Text(context.l10n.publishTo),
        subtitle: Text(_selectedGroup?.name ?? context.l10n.public),
      ),
      for (var index = 0; index < _questions.length; index++)
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${index + 1}. ${_questions[index].titleController.text.trim()}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (_questions[index].type == QuestionnaireQuestionType.text)
                  Text(context.l10n.writtenAnswerHint),
                if (_questions[index].type ==
                    QuestionnaireQuestionType.multipleChoice)
                  for (final option in _questions[index].optionControllers)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.radio_button_unchecked),
                          const SizedBox(width: 12),
                          Expanded(child: Text(option.text.trim())),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ),
    ],
  );

  Future<void> _chooseTemplate(
    TextEditingController title,
    TextEditingController description,
  ) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    try {
      final repository = await ref.read(
        questionnaireTemplateRepositoryProvider(userId).future,
      );
      final templates = repository.load();
      if (!mounted) return;
      final selected = await showDialog<FormTemplate>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, update) => AlertDialog(
            title: Text(context.l10n.formTemplates),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (templates.isEmpty) Text(context.l10n.formTemplatesEmpty),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: templates.length,
                      itemBuilder: (context, index) {
                        final template = templates[index];
                        return ListTile(
                          title: Text(template.name),
                          subtitle: Text(_templateSummary(template)),
                          onTap: () => Navigator.pop(dialogContext, template),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: context.l10n.formTemplateDeleteAction,
                            onPressed: () async {
                              if (!await _confirmReplacement(
                                context.l10n.formTemplateDelete,
                              )) {
                                return;
                              }
                              try {
                                await repository.delete(template.id);
                                if (context.mounted) {
                                  update(() => templates.remove(template));
                                }
                              } catch (_) {
                                if (mounted) {
                                  showErrorSnackBar(
                                    this.context.l10n.formTemplateError,
                                  );
                                }
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(context.l10n.cancel),
              ),
            ],
          ),
        ),
      );
      if (selected == null || !mounted) return;
      if (!await _confirmReplacement(
            '${context.l10n.formTemplateReplace}\n\n${selected.name}\n${_templateSummary(selected)}',
          ) ||
          !mounted) {
        return;
      }
      if (selected.includesAudience && selected.groupId != null) {
        final groups = await _groupRepository.watchGroupsForUser(userId).first;
        if (!mounted) return;
        if (!groups.any((group) => group.id == selected.groupId)) {
          showUserMistakeSnackBar(context.l10n.formTemplateGroupUnavailable);
          return;
        }
        _rememberGroups(groups);
      }
      if (!mounted) return;
      if (!await _creatorKey.currentState!.applyTemplate(selected) ||
          !mounted) {
        return;
      }
      setState(() {
        if (selected.includesAudience) _selectedGroupId = selected.groupId;
        if (selected.questions != null) {
          for (final question in _questions) {
            question.dispose();
          }
          _questions
            ..clear()
            ..addAll(
              selected.questions!
                  .take(AppLimits.maxQuestionnaireQuestions)
                  .map(
                    (question) => _createQuestionDraft(
                      title: question.title,
                      type: question.type,
                      options: question.options
                          .take(AppLimits.maxQuestionnaireOptionsPerQuestion)
                          .toList(),
                    ),
                  ),
            );
        }
      });
      await _saveSpecificDraft();
    } catch (_) {
      if (mounted) showErrorSnackBar(context.l10n.formTemplateError);
    }
  }

  Widget _buildTemplateActions(
    TextEditingController title,
    TextEditingController description,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Row(
      children: [
        Expanded(child: _buildGroupSelector()),
        const SizedBox(width: 8),
        IconButton(
          key: const Key('survey_manage_groups_button'),
          icon: const Icon(Icons.group_outlined),
          tooltip: context.l10n.createOrManageGroups,
          onPressed: _auth.currentUser == null ? null : _openManageGroups,
        ),
        IconButton(
          icon: const Icon(Icons.library_books_outlined),
          tooltip: context.l10n.formTemplates,
          onPressed: _auth.currentUser == null
              ? null
              : () => _chooseTemplate(title, description),
        ),
      ],
    ),
  );

  Widget _buildAnswerPresets(_QuestionDraft question) {
    final l = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final presets = <String, List<String>>{
      l.presetConsent: [
        l.presetYes,
        l.presetUndecided,
        l.presetNo,
        l.presetVeto,
      ],
      l.presetBinary: [l.presetYes, l.presetNo],
      l.presetAgreement: [
        l.presetStronglyAgree,
        l.presetAgree,
        l.presetNeutral,
        l.presetDisagree,
        l.presetStronglyDisagree,
      ],
      l.presetSatisfaction: [
        l.presetVerySatisfied,
        l.presetSatisfied,
        l.presetNeutral,
        l.presetDissatisfied,
        l.presetVeryDissatisfied,
      ],
      l.presetFrequency: [
        l.presetAlways,
        l.presetOften,
        l.presetSometimes,
        l.presetRarely,
        l.presetNever,
      ],
    };
    return PopupMenuButton<String>(
      tooltip: l.answerPresets,
      iconColor: colors.onPrimary,
      itemBuilder: (_) => [
        for (final name in presets.keys)
          PopupMenuItem(value: name, child: Text(name)),
      ],
      onSelected: (name) async {
        if (question.optionControllers.any(
          (option) => option.text.trim().isNotEmpty,
        )) {
          if (!await _confirmReplacement(l.answerPresetReplace)) return;
        }
        if (!mounted || !_questions.contains(question)) return;
        setState(() {
          for (final option in question.optionControllers) {
            option.dispose();
          }
          question.optionControllers.clear();
          for (final label in presets[name]!) {
            question.optionControllers.add(
              TextEditingController(text: label)
                ..addListener(_saveSpecificDraft),
            );
          }
        });
        await _saveSpecificDraft();
      },
      icon: const Icon(Icons.list_alt_rounded),
      style: IconButton.styleFrom(
        foregroundColor: colors.onPrimary,
        backgroundColor: colors.primary,
      ),
    );
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
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => _removeQuestion(index),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: question.titleController,
              maxLength: AppLimits.maxQuestionnaireQuestionLength,
              decoration: InputDecoration(
                labelText: context.l10n.surveyQuestion,
                border: const OutlineInputBorder(),
              ),
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? context.l10n.questionRequired
                  : null,
            ),
            const SizedBox(height: 8),
            if (question.type == QuestionnaireQuestionType.text)
              Text(context.l10n.writtenAnswerHint),
            if (question.type == QuestionnaireQuestionType.multipleChoice) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.options,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildAnswerPresets(question),
                ],
              ),
              ChoiceOptionListEditor(
                controllers: question.optionControllers,
                maxOptionLength: AppLimits.maxQuestionnaireOptionLength,
                optionLabelBuilder: (optionIndex) =>
                    context.l10n.optionNumber(optionIndex + 1),
                optionRequiredMessage: context.l10n.optionRequired,
                onReorder: (oldIndex, newIndex) =>
                    _reorderOptions(question, oldIndex, newIndex),
                onRemove: (optionIndex) => _removeOption(question, optionIndex),
              ),
              if (question.optionControllers.length <
                  AppLimits.maxQuestionnaireOptionsPerQuestion)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(context.l10n.addOption),
                    onPressed: () => _addOption(question),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseCreatorPage(
      initialTemplate: widget.initialTemplate,
      key: _creatorKey,
      importTarget: FormImportTarget.questionnaire,
      onImportQuestions: (questions) async {
        setState(() {
          for (final question in _questions) {
            question.dispose();
          }
          _questions
            ..clear()
            ..addAll(
              questions.map(
                (question) => _createQuestionDraft(
                  title: question.title,
                  type: question.type,
                  options: question.options,
                ),
              ),
            );
        });
        await _saveSpecificDraft();
      },
      title: context.l10n.createQuestionnaire,
      draftStorageKey: 'draft_questionnaire_v1',
      previewTitle: _isSingleQuestionPoll
          ? context.l10n.pollDetails
          : context.l10n.surveyDetails,
      tutorialSteps: QuestionnaireTutorialHelper.getSteps(context),
      onSubmit: _createQuestionnaire,
      previewContentBuilder: _buildPublicationPreview,
      contentActionsBuilder: _buildTemplateActions,
      appBarActionBuilder: (title, description) => IconButton(
        icon: const Icon(Icons.bookmark_add_outlined),
        tooltip: context.l10n.saveFormTemplate,
        onPressed: _auth.currentUser == null
            ? null
            : () => _saveTemplate(title, description),
      ),
      additionalDraftClearer: _clearSpecificDraft,
      onResetAdditionalFields: _resetSpecificFields,
      additionalMiddleFields: [
        const SizedBox(height: 20),
        Text(
          context.l10n.questions,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        FormField<void>(
          validator: (_) =>
              _questions.isEmpty ? context.l10n.addAtLeastOneQuestion : null,
          builder: (field) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _questions.length,
                onReorderItem: _reorderQuestions,
                buildDefaultDragHandles: false,
                itemBuilder: (context, index) => _buildQuestionCard(index),
              ),
              if (_questions.isEmpty && field.hasError)
                Text(
                  field.errorText!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
        if (_questions.length < AppLimits.maxQuestionnaireQuestions)
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add,
                      size: 24,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            key: const Key('add_multiple_choice_question'),
                            icon: const Icon(Icons.list),
                            label: Text(context.l10n.multipleChoiceAnswer),
                            onPressed: () => _addQuestion(
                              QuestionnaireQuestionType.multipleChoice,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            key: const Key('add_text_question'),
                            icon: const Icon(Icons.notes),
                            label: Text(context.l10n.textQuestion),
                            onPressed: () =>
                                _addQuestion(QuestionnaireQuestionType.text),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _QuestionDraft {
  _QuestionDraft({
    required this.onChanged,
    this.type = QuestionnaireQuestionType.multipleChoice,
    String title = '',
    List<String>? options,
  }) : titleController = TextEditingController(text: title),
       optionControllers = _normalizedOptions(options)
           .map((text) => TextEditingController(text: text))
           .toList() {
    titleController.addListener(onChanged);
    for (final controller in optionControllers) {
      controller.addListener(onChanged);
    }
  }

  final QuestionnaireQuestionType type;
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
