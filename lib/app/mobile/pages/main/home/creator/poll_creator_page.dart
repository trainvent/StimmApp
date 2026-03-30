import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/pages/main/home/creator/base_creator_page.dart';
import 'package:stimmapp/app/mobile/pages/main/groups/member_groups_page.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/constants/app_limits.dart';
import 'package:stimmapp/core/constants/poll_tutorial_helper.dart';
import 'package:stimmapp/core/data/models/poll.dart';
import 'package:stimmapp/core/data/models/poll_group.dart';
import 'package:stimmapp/core/data/repositories/poll_group_repository.dart';
import 'package:stimmapp/core/data/repositories/poll_repository.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/data/services/content_moderation_service.dart';
import 'package:stimmapp/core/data/services/publishing_quota_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:uuid/uuid.dart';

const String _publicGroupValue = '__public__';
const String _manageGroupsValue = '__manage_groups__';

class PollCreatorPage extends StatefulWidget {
  const PollCreatorPage({super.key});

  @override
  State<PollCreatorPage> createState() => _PollCreatorPageState();
}

class _PollCreatorPageState extends State<PollCreatorPage> {
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  final _uuid = const Uuid();
  final Map<String, PollGroup> _knownGroupsById = <String, PollGroup>{};
  PollGroup? _selectedGroup;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    for (final controller in _optionControllers) {
      controller.dispose();
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
        key: const Key('poll_group_dropdown'),
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
          key: const Key('poll_group_dropdown'),
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

  void _addOption() {
    if (_optionControllers.length >= AppLimits.maxPollOptions) {
      showErrorSnackBar(
        context.l10n.maximumPollOptionsAllowed(AppLimits.maxPollOptions),
      );
      return;
    }
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
    });
  }

  void _reorderOptions(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _optionControllers.removeAt(oldIndex);
      _optionControllers.insert(newIndex, item);
    });
  }

  Future<void> _createPoll({
    required String title,
    required String description,
    required List<String> tags,
    required String scopeType,
    String? scopeContinentCode,
    String? scopeCountryCode,
    String? scopeStateOrRegion,
    String? scopeTown,
    required int durationDays,
  }) async {
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      showErrorSnackBar(context.l10n.pleaseSignInFirst);
      return;
    }

    final moderationInputs = <String?>[
      title,
      description,
      ..._optionControllers.map((controller) => controller.text),
    ];
    if (ContentModerationService.instance.containsObjectionableContent(
      moderationInputs,
    )) {
      showErrorSnackBar(context.l10n.removeAbusiveLanguageBeforePublishing);
      return;
    }

    // Validate options
    for (var controller in _optionControllers) {
      if (controller.text.trim().isEmpty) {
        showErrorSnackBar(context.l10n.optionRequired);
        throw Exception(context.l10n.optionRequired); // Stop submission
      }
    }

    try {
      final options = _optionControllers
          .map(
            (controller) =>
                PollOption(id: _uuid.v4(), label: controller.text.trim()),
          )
          .toList();

      final userProfile = await UserRepository.create().getById(
        currentUser.uid,
      );
      final resolvedCountryCode =
          scopeCountryCode?.toUpperCase() ??
          userProfile?.countryCode?.toUpperCase() ??
          (userProfile?.supportsStateScope == true ? 'DE' : null);

      final now = DateTime.now();
      final poll = Poll(
        id: '',
        title: title,
        description: description,
        tags: tags,
        options: options,
        votes: {for (var option in options) option.id: 0},
        createdBy: currentUser.uid,
        createdAt: now,
        expiresAt: now.add(Duration(days: durationDays)),
        scopeType: scopeType,
        continentCode: scopeContinentCode,
        countryCode: resolvedCountryCode,
        groupId: _selectedGroup?.id,
        groupName: _selectedGroup?.name,
        visibility: _selectedGroup == null ? 'public' : 'group',
        stateOrRegion: scopeStateOrRegion,
        town: scopeTown,
      );

      List<Poll> matchedTitles = await PollRepository.create()
          .list(query: poll.title, status: "active")
          .first;
      String matchedTitle = matchedTitles.isNotEmpty
          ? matchedTitles.first.title
          : '';
      if (matchedTitle.isNotEmpty && matchedTitle == poll.title) {
        if (mounted) showErrorSnackBar(context.l10n.petitionTitleInUseAlready);
        return;
      }

      await PublishingQuotaService.instance.incrementPoll();

      final pollId = await PollRepository.create().createPoll(poll);

      if (mounted) {
        showSuccessSnackBar(context.l10n.createdPoll + pollId);
        Navigator.of(context).pop();
      }
    } on StateError catch (e) {
      if (mounted) {
        if (e.message == 'poll_daily_limit_reached') {
          showErrorSnackBar(context.l10n.dailyCreateLimitReached);
        } else {
          showErrorSnackBar(context.l10n.failedToCreatePoll + e.toString());
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context.l10n.failedToCreatePoll + e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseCreatorPage(
      title: context.l10n.createPoll,
      tutorialSteps: PollTutorialHelper.getSteps(context),
      onSubmit: _createPoll,
      additionalTopFields: [
        _buildGroupSelector(),
        const SizedBox(height: 20),
      ],
      additionalMiddleFields: [
        const SizedBox(height: 20),
        Text(
          context.l10n.options,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _optionControllers.length,
          onReorder: _reorderOptions,
          buildDefaultDragHandles: false, // Disable default handles
          itemBuilder: (context, index) {
            final controller = _optionControllers[index];
            return Padding(
              key: ValueKey(controller),
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  ReorderableDragStartListener(
                    index: index,
                    child: const Icon(Icons.drag_handle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: controller,
                      maxLength: AppLimits.maxPollOptionLength,
                      decoration: InputDecoration(
                        labelText: context.l10n.optionNumber(index + 1),
                        border: const OutlineInputBorder(),
                        counterText: "",
                      ),
                      validator: (v) => (v?.trim().isEmpty ?? true)
                          ? context.l10n.optionRequired
                          : null,
                    ),
                  ),
                  if (_optionControllers.length > 2)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => _removeOption(index),
                    ),
                ],
              ),
            );
          },
        ),
        if (_optionControllers.length < AppLimits.maxPollOptions)
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: Text(context.l10n.addOption),
            onPressed: _addOption,
          ),
      ],
    );
  }
}
