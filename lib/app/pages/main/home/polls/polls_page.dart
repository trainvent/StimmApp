import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stimmapp/app/pages/main/home/base_overview_page.dart';
import 'package:stimmapp/app/widgets/form_list_tile_widget.dart';
import 'package:stimmapp/app/widgets/teaching_lemm_image.dart';
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
  const PollsPage({super.key, this.initialGroupId});

  final String? initialGroupId;

  @override
  State<PollsPage> createState() => _PollsPageState();
}

class _PollsPageState extends State<PollsPage> {
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
        if (selectedGroupId == null || selectedGroupId.isEmpty) {
          return true;
        }
        return _groupId(item) == selectedGroupId;
      },
      extraFilterCount:
          ((_selectedGroupId == null || _selectedGroupId!.isEmpty) ? 0 : 1) +
          (_showSurveys ? 0 : 1),
      clearExtraFilters: () {
        if (_selectedGroupId == null && _showSurveys) {
          return;
        }
        setState(() {
          _selectedGroupId = null;
          _showSurveys = true;
        });
      },
      designFilterSectionBuilder: (dialogContext, setDialogState) {
        return CheckboxListTile(
          key: const Key('show_surveys_filter_checkbox'),
          contentPadding: EdgeInsets.zero,
          value: _showSurveys,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text(context.l10n.showSurveys)),
              const SizedBox(width: 4),
              const _ShowSurveysInfoButton(),
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
                  if (groups.isEmpty) {
                    return Text(context.l10n.groupFilterEmpty);
                  }
                  final availableGroupIds = groups
                      .map((group) => group.id)
                      .toSet();
                  if (_selectedGroupId != null &&
                      !availableGroupIds.contains(_selectedGroupId)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() => _selectedGroupId = null);
                      }
                    });
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        key: const Key('poll_group_filter_dropdown'),
                        initialValue: _selectedGroupId,
                        decoration: InputDecoration(
                          hintText: context.l10n.filterByGroup,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        disabledHint: Text(context.l10n.allGroups),
                        items: groups
                            .map(
                              (group) => DropdownMenuItem<String>(
                                value: group.id,
                                child: Text(group.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() {});
                          setState(() => _selectedGroupId = value);
                        },
                      ),
                      if (_selectedGroupId != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              setDialogState(() {});
                              setState(() => _selectedGroupId = null);
                            },
                            child: Text(context.l10n.clearGroupFilter),
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

class _ShowSurveysInfoButton extends StatefulWidget {
  const _ShowSurveysInfoButton();

  @override
  State<_ShowSurveysInfoButton> createState() => _ShowSurveysInfoButtonState();
}

class _ShowSurveysInfoButtonState extends State<_ShowSurveysInfoButton> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _hideBubble();
    super.dispose();
  }

  void _toggleBubble() {
    if (_overlayEntry == null) {
      _showBubble();
    } else {
      _hideBubble();
    }
  }

  void _showBubble() {
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _hideBubble,
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.topRight,
              followerAnchor: Alignment.bottomRight,
              offset: const Offset(8, -8),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 260,
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colorScheme.outlineVariant),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withValues(alpha: 0.16),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const TeachingLemmImage(),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              context.l10n.showSurveysInfo,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Transform.rotate(
                        angle: 0.785398,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            border: Border(
                              right: BorderSide(
                                color: colorScheme.outlineVariant,
                              ),
                              bottom: BorderSide(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(_overlayEntry!);
  }

  void _hideBubble() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: IconButton(
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 32, height: 32),
        tooltip: context.l10n.info,
        icon: const Icon(Icons.info_outline, size: 20),
        onPressed: _toggleBubble,
      ),
    );
  }
}
