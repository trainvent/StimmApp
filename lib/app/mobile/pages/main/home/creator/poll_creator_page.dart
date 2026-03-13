import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/pages/main/home/creator/base_creator_page.dart';
import 'package:stimmapp/app/mobile/pages/main/home/creator/poll_groups_page.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/constants/app_limits.dart';
import 'package:stimmapp/core/constants/poll_tutorial_helper.dart';
import 'package:stimmapp/core/data/models/poll.dart';
import 'package:stimmapp/core/data/models/poll_group.dart';
import 'package:stimmapp/core/data/repositories/poll_repository.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/data/services/content_moderation_service.dart';
import 'package:stimmapp/core/data/services/publishing_quota_service.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/services/purchases_service.dart';
import 'package:uuid/uuid.dart';

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
  UserProfile? _user;
  PollGroup? _selectedGroup;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  @override
  void dispose() {
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchUser() async {
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      return;
    }
    final user = await UserRepository.create().watchById(currentUser.uid).first;
    if (!mounted) {
      return;
    }
    setState(() {
      _user = user;
    });
  }

  Future<void> _openGroupSelector() async {
    final user = _user;
    final navigator = Navigator.of(context);
    if (user == null) {
      await _fetchUser();
    }
    if (!mounted) {
      return;
    }

    if ((_user?.isPro ?? false) != true) {
      final opened = await PurchasesService.instance.presentPaywall(
        context: context,
      );
      if (!opened) {
        showErrorSnackBar('Could not open paywall');
      }
      return;
    }

    if (!mounted) {
      return;
    }

    final selectedGroup = await navigator.push<PollGroup>(
      MaterialPageRoute(
        builder: (context) => PollGroupsPage(selectedGroupId: _selectedGroup?.id),
      ),
    );
    if (!mounted || selectedGroup == null) {
      return;
    }
    setState(() {
      _selectedGroup = selectedGroup;
    });
  }

  void _addOption() {
    if (_optionControllers.length >= AppLimits.maxPollOptions) {
      showErrorSnackBar('Maximum ${AppLimits.maxPollOptions} options allowed');
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
      showErrorSnackBar(
        'Please remove abusive or objectionable language before publishing.',
      );
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
        if ((_user?.isPro ?? false) == true)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.groups_2_outlined),
            title: const Text('Polling groups'),
            subtitle: Text(
              _selectedGroup == null
                  ? 'Create team-only polls and preload allowed members.'
                  : 'Selected group: ${_selectedGroup!.name}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _openGroupSelector,
          ),
        if (_selectedGroup != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.group, size: 18),
                  label: Text(_selectedGroup!.name),
                ),
                ActionChip(
                  onPressed: () {
                    setState(() {
                      _selectedGroup = null;
                    });
                  },
                  label: const Text('Post publicly instead'),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
      ],
      additionalBottomFields: [
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
                        labelText: context.l10n.option + (index + 1).toString(),
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
