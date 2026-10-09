import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stimmapp/app/pages/main/home/base_overview_page.dart';
import 'package:stimmapp/app/widgets/form_list_tile_widget.dart';
import 'package:stimmapp/app/widgets/buttons/info_dialog_button.dart';
import 'package:trainvent_general/trainvent_general.dart';
import 'package:stimmapp/core/data/models/home_item.dart';
import 'package:stimmapp/core/data/models/poll.dart';
import 'package:stimmapp/core/data/models/poll_group.dart';
import 'package:stimmapp/core/data/models/survey.dart';
import 'package:stimmapp/core/data/repositories/poll_group_repository.dart';
import 'package:stimmapp/core/data/repositories/poll_repository.dart';
import 'package:stimmapp/core/data/repositories/survey_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

class PollsPage extends StatefulWidget {
  const PollsPage({
    super.key,
    this.initialGroupId,
    this.showTopNavigation = false,
  });

  final String? initialGroupId;
  final bool showTopNavigation;

  @override
  State<PollsPage> createState() => _PollsPageState();
}

class _PollsPageState extends State<PollsPage> {
  // null shows all groups; an empty ID selects forms without a group.
  late String? _selectedGroupId = widget.initialGroupId;
  bool _showSurveys = true;

  Stream<List<HomeItem>> _listPollsAndSurveys({
    required String query,
    required String status,
  }) {
    final pollStream = PollRepository.create()
        .list(query: query, status: status)
        .map((polls) => polls.cast<HomeItem>());
    if (!_showSurveys) {
      return pollStream;
    }

    return _combineLatestItems(
      pollStream,
      SurveyRepository.create()
          .list(query: query, status: status)
          .map((surveys) => surveys.cast<HomeItem>()),
    );
  }

  Stream<List<HomeItem>> _combineLatestItems(
    Stream<List<HomeItem>> pollStream,
    Stream<List<HomeItem>> surveyStream,
  ) {
    late StreamSubscription<List<HomeItem>> pollSubscription;
    late StreamSubscription<List<HomeItem>> surveySubscription;
    List<HomeItem>? latestPolls;
    List<HomeItem>? latestSurveys;

    final controller = StreamController<List<HomeItem>>();
    void emitIfReady() {
      final polls = latestPolls;
      final surveys = latestSurveys;
      if (polls == null || surveys == null || controller.isClosed) {
        return;
      }
      final items = [...polls, ...surveys]
        ..sort((a, b) => _createdAt(b).compareTo(_createdAt(a)));
      controller.add(items);
    }

    controller.onListen = () {
      pollSubscription = pollStream.listen((items) {
        latestPolls = items;
        emitIfReady();
      }, onError: controller.addError);
      surveySubscription = surveyStream.listen((items) {
        latestSurveys = items;
        emitIfReady();
      }, onError: controller.addError);
    };
    controller.onCancel = () async {
      await pollSubscription.cancel();
      await surveySubscription.cancel();
    };
    return controller.stream;
  }

  Stream<Set<String>> _combineLatestSets(
    Stream<Set<String>> pollIdStream,
    Stream<Set<String>> surveyIdStream,
  ) {
    late StreamSubscription<Set<String>> pollSubscription;
    late StreamSubscription<Set<String>> surveySubscription;
    Set<String>? latestPollIds;
    Set<String>? latestSurveyIds;

    final controller = StreamController<Set<String>>();
    void emitIfReady() {
      final pollIds = latestPollIds;
      final surveyIds = latestSurveyIds;
      if (pollIds == null || surveyIds == null || controller.isClosed) {
        return;
      }
      controller.add({
        ...pollIds.map((id) => 'poll:$id'),
        ...surveyIds.map((id) => 'survey:$id'),
      });
    }

    controller.onListen = () {
      pollSubscription = pollIdStream.listen((items) {
        latestPollIds = items;
        emitIfReady();
      }, onError: controller.addError);
      surveySubscription = surveyIdStream.listen((items) {
        latestSurveyIds = items;
        emitIfReady();
      }, onError: controller.addError);
    };
    controller.onCancel = () async {
      await pollSubscription.cancel();
      await surveySubscription.cancel();
    };
    return controller.stream;
  }

  DateTime _createdAt(HomeItem item) {
    if (item is Poll) {
      return item.createdAt;
    }
    if (item is Survey) {
      return item.createdAt;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String? _groupId(HomeItem item) {
    if (item is Poll) {
      return item.groupId;
    }
    if (item is Survey) {
      return item.groupId;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = authService.currentUser?.uid;
    return BaseOverviewPage<HomeItem>(
      streamKey: _showSurveys,
      appBarTitle: widget.showTopNavigation
          ? context.l10n.viewGroupPolls
          : null,
      streamProvider: (query, status) =>
          _listPollsAndSurveys(query: query, status: status),
      participatedIdsStreamProvider: (uid) => _combineLatestSets(
        PollRepository.create().watchVotedPollIds(uid),
        SurveyRepository.create().watchCompletedSurveyIds(uid),
      ),
      participationKeyProvider: (item) =>
          item is Survey ? 'survey:${item.id}' : 'poll:${item.id}',
      extraFilter: (item) {
        final selectedGroupId = _selectedGroupId;
        if (selectedGroupId == null) {
          return true;
        }
        if (selectedGroupId.isEmpty) {
          return _groupId(item)?.isEmpty ?? true;
        }
        return _groupId(item) == selectedGroupId;
      },
      extraFilterCount:
          (_selectedGroupId == null ? 0 : 1) + (_showSurveys ? 0 : 1),
      clearExtraFilters: () {
        if (_selectedGroupId == null && _showSurveys) {
          return;
        }
        setState(() {
          _selectedGroupId = null;
          _showSurveys = true;
        });
      },
      structureFilterSectionBuilder: (dialogContext, setDialogState) {
        return CheckboxListTile(
          key: const Key('show_surveys_filter_checkbox'),
          contentPadding: EdgeInsets.zero,
          value: _showSurveys,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text(context.l10n.showSurveys)),
              const SizedBox(width: 4),
              InfoDialogButton(
                title: context.l10n.showSurveys,
                content: Text(context.l10n.showSurveysInfo),
                cornerImagePath: 'assets/images/Lemm_teaching.png',
              ),
            ],
          ),
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: (value) {
            setDialogState(() {});
            setState(() => _showSurveys = value ?? true);
          },
        );
      },
      filterDialogSectionBuilder: currentUid == null
          ? null
          : (dialogContext, setDialogState) {
              return FutureBuilder<List<PollGroup>>(
                future: PollGroupRepository.create().getAccessibleGroupsForUser(
                  currentUid,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    debugPrint(
                      'Poll group filter stream error: ${snapshot.error}',
                    );
                    return Text('${context.l10n.error}: ${snapshot.error}');
                  }
                  final groups = snapshot.data ?? const <PollGroup>[];
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: TriangleLoadingIndicator(
                            size: 20,
                            strokeWidth: 2,
                            showFill: false,
                          ),
                        ),
                      ),
                    );
                  }
                  final availableGroupIds = groups
                      .map((group) => group.id)
                      .toSet();
                  if (_selectedGroupId != null &&
                      _selectedGroupId!.isNotEmpty &&
                      !availableGroupIds.contains(_selectedGroupId)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() => _selectedGroupId = null);
                      }
                    });
                  }
                  final noGroup = _selectedGroupId == '';
                  void selectGroup(String? value) {
                    setState(() => _selectedGroupId = value);
                    setDialogState(() {});
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        key: const Key('poll_no_group_filter'),
                        tooltip: context.l10n.noGroupFilter,
                        isSelected: noGroup,
                        icon: const Icon(Icons.people_outline),
                        selectedIcon: const Icon(Icons.group_off_outlined),
                        onPressed: () => selectGroup(noGroup ? null : ''),
                      ),
                      if (!noGroup) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: ValueKey(
                              'poll_group_filter_${_selectedGroupId ?? 'all'}',
                            ),
                            initialValue: _selectedGroupId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              hintText: context.l10n.filterByGroup,
                              border: const OutlineInputBorder(),
                              isDense: true,
                              suffixIcon: _selectedGroupId == null
                                  ? null
                                  : IconButton(
                                      tooltip: context.l10n.clearGroupFilter,
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () => selectGroup(null),
                                    ),
                            ),
                            items: groups
                                .map(
                                  (group) => DropdownMenuItem<String>(
                                    value: group.id,
                                    child: Text(
                                      group.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: selectGroup,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              );
            },
      itemBuilder: (context, p, discoveryStatus) {
        final isSurvey = p is Survey;
        final total = p.participantCount;
        return FormListTileWidget(
          title: p.title,
          description: p.description,
          count: total,
          countIcon: isSurvey ? Icons.assignment_outlined : Icons.how_to_vote,
          status: DiscoveryStatusChips(status: discoveryStatus),
          onTap: () {
            Navigator.of(
              context,
            ).pushNamed(isSurvey ? '/survey/${p.id}' : '/poll/${p.id}');
          },
        );
      },
    );
  }
}
