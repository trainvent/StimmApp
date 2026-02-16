import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/pages/main/home/creator/base_creator_page.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/constants/app_limits.dart';
import 'package:stimmapp/core/constants/poll_tutorial_helper.dart';
import 'package:stimmapp/core/data/models/poll.dart';
import 'package:stimmapp/core/data/repositories/poll_repository.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/data/services/publishing_quota_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
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

  @override
  void dispose() {
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
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

  Future<void> _createPoll({
    required String title,
    required String description,
    required List<String> tags,
    required bool isStateDependent,
    required int durationDays,
  }) async {
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      showErrorSnackBar(context.l10n.pleaseSignInFirst);
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

      String? state;
      if (isStateDependent) {
        final userProfile = await UserRepository.create().getById(
          currentUser.uid,
        );
        state = userProfile?.state;
      }

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
        state: state,
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
      sourceUrl: 'https://www.bpb.de/system/files/dokument_pdf/M%2001.04%20Fragebogenerstellung_3.pdf',
      onSubmit: _createPoll,
      additionalBottomFields: [
        const SizedBox(height: 20),
        Text(
          context.l10n.options,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        ..._optionControllers.asMap().entries.map((entry) {
          final index = entry.key;
          final controller = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
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
        }),
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
