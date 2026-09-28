import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stimmapp/core/data/models/poll_template.dart';
import 'package:stimmapp/core/data/repositories/poll_template_repository.dart';
import 'package:stimmapp/core/providers/poll_template_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stimmapp/app/pages/main/home/creator/base_creator_page.dart';
import 'package:stimmapp/app/pages/main/home/creator/widgets/choice_option_list_editor.dart';
import 'package:stimmapp/app/pages/main/groups/groups_overview_page.dart';
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
const String _manageGroupsValue = '__manage_groups__';

class SurveyCreatorPage extends ConsumerStatefulWidget {
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
  ConsumerState<SurveyCreatorPage> createState() => _SurveyCreatorPageState();
}

class _SurveyCreatorPageState extends ConsumerState<SurveyCreatorPage> {
  final _uuid = const Uuid();
  final _creatorKey = GlobalKey<BaseCreatorPageState>();
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
    late final PollTemplateRepository repository;
    try {
      repository = await ref.read(
        pollTemplateRepositoryProvider(userId).future,
      );
      repository.load();
    } catch (_) {
      if (mounted) showErrorSnackBar(context.l10n.pollTemplateError);
      return;
    }
    if (!mounted) return;
    final nameController = TextEditingController(text: title.text.trim());
    final included = _TemplateField.values.toSet();
    final settings = _creatorKey.currentState!.templateSettings;
    final labels = <_TemplateField, String>{
      _TemplateField.title: context.l10n.title,
      _TemplateField.description: context.l10n.description,
      _TemplateField.questions: context.l10n.pollTemplateQuestionsAndAnswers,
      _TemplateField.tags: context.l10n.tags,
      _TemplateField.scope: context.l10n.scope,
      _TemplateField.duration: context.l10n.duration,
      _TemplateField.audience: context.l10n.publishTo,
    };
    final name = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(context.l10n.savePollTemplate),
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
                    autofocus: true,
                    maxLength: AppLimits.maxTitleLength,
                    onChanged: (_) => update(() {}),
                    decoration: InputDecoration(
                      labelText: context.l10n.pollTemplateName,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(context.l10n.pollTemplateIncludeFields),
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
                          context.l10n.pollTemplateOverwriteConfirmation,
                        );
                        if (!confirmed) return;
                      }
                      if (context.mounted) Navigator.pop(context, name);
                    },
              child: Text(
                repository.containsName(nameController.text)
                    ? context.l10n.pollTemplateReplaceAction
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
    final template = PollTemplate(
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
                PollTemplateQuestion(
                  title: question.titleController.text,
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
      if (mounted) showSuccessSnackBar(context.l10n.pollTemplateSaved);
    } catch (_) {
      if (mounted) showErrorSnackBar(context.l10n.pollTemplateError);
    }
  }

  Future<void> _chooseTemplate(
    TextEditingController title,
    TextEditingController description,
  ) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    try {
      final repository = await ref.read(
        pollTemplateRepositoryProvider(userId).future,
      );
      final templates = repository.load();
      if (!mounted) return;
      final selected = await showDialog<PollTemplate>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, update) => AlertDialog(
            title: Text(context.l10n.pollTemplates),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.l10n.pollTemplatesLocal),
                  const SizedBox(height: 12),
                  if (templates.isEmpty) Text(context.l10n.pollTemplatesEmpty),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: templates.length,
                      itemBuilder: (context, index) {
                        final template = templates[index];
                        return ListTile(
                          title: Text(template.name),
                          onTap: () => Navigator.pop(dialogContext, template),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: context.l10n.pollTemplateDeleteAction,
                            onPressed: () async {
                              if (!await _confirmReplacement(
                                context.l10n.pollTemplateDelete,
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
                                    this.context.l10n.pollTemplateError,
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
      if (!await _confirmReplacement(context.l10n.pollTemplateReplace) ||
          !mounted) {
        return;
      }
      if (selected.includesAudience && selected.groupId != null) {
        final groups = await _groupRepository.watchGroupsForUser(userId).first;
        if (!mounted) return;
        if (!groups.any((group) => group.id == selected.groupId)) {
          showErrorSnackBar(context.l10n.pollTemplateGroupUnavailable);
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
                  .take(AppLimits.maxSurveyQuestions)
                  .map(
                    (question) => _createQuestionDraft(
                      title: question.title,
                      options: question.options
                          .take(AppLimits.maxSurveyOptionsPerQuestion)
                          .toList(),
                    ),
                  ),
            );
          if (_questions.isEmpty) _questions.add(_createQuestionDraft());
        }
      });
      await _saveSpecificDraft();
    } catch (_) {
      if (mounted) showErrorSnackBar(context.l10n.pollTemplateError);
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
          icon: const Icon(Icons.library_books_outlined),
          tooltip: context.l10n.pollTemplates,
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
      color: colors.primary,
      surfaceTintColor: Colors.transparent,
      iconColor: colors.onPrimary,
      itemBuilder: (_) => [
        for (final name in presets.keys)
          PopupMenuItem(
            value: name,
            child: Text(name, style: TextStyle(color: colors.onPrimary)),
          ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      key: _creatorKey,
      title: widget.presentAsPoll
          ? context.l10n.createPoll
          : context.l10n.createSurvey,
      tutorialSteps: PollTutorialHelper.getSteps(context),
      onSubmit: _createSurvey,
      contentActionsBuilder: _buildTemplateActions,
      appBarActionBuilder: (title, description) => IconButton(
        icon: const Icon(Icons.bookmark_add_outlined),
        tooltip: context.l10n.savePollTemplate,
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
