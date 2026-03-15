import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/pages/main/home/base_overview_page.dart';
import 'package:stimmapp/core/data/models/poll.dart';
import 'package:stimmapp/core/data/models/poll_group.dart';
import 'package:stimmapp/core/data/repositories/poll_group_repository.dart';
import 'package:stimmapp/core/data/repositories/poll_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

class PollsPage extends StatefulWidget {
  const PollsPage({super.key});

  @override
  State<PollsPage> createState() => _PollsPageState();
}

class _PollsPageState extends State<PollsPage> {
  String? _selectedGroupId;

  @override
  Widget build(BuildContext context) {
    final repo = PollRepository.create();
    final currentUid = authService.currentUser?.uid;
    return BaseOverviewPage<Poll>(
      streamProvider: (query, status) =>
          repo.list(query: query, status: status),
      extraFilter: (poll) {
        final selectedGroupId = _selectedGroupId;
        if (selectedGroupId == null || selectedGroupId.isEmpty) {
          return true;
        }
        return poll.groupId == selectedGroupId;
      },
      extraFilterCount:
          (_selectedGroupId == null || _selectedGroupId!.isEmpty) ? 0 : 1,
      clearExtraFilters: () {
        if (_selectedGroupId == null) {
          return;
        }
        setState(() => _selectedGroupId = null);
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
                    debugPrint('Poll group filter stream error: ${snapshot.error}');
                    return Text(
                      '${context.l10n.error}: ${snapshot.error}',
                    );
                  }
                  final groups = snapshot.data ?? const <PollGroup>[];
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  if (groups.isEmpty) {
                    return Text(context.l10n.groupFilterEmpty);
                  }
                  final availableGroupIds = groups.map((group) => group.id).toSet();
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
                        decoration: const InputDecoration(
                          hintText: 'All groups',
                          border: OutlineInputBorder(),
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
      itemBuilder: (context, p) {
        final total = p.totalVotes;
        return ListTile(
          title: Text(p.title),
          subtitle: Text(
            p.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.how_to_vote, size: 18),
              const SizedBox(width: 4),
              Text(total.toString()),
            ],
          ),
          onTap: () {
            Navigator.of(context).pushNamed('/poll/${p.id}');
          },
        );
      },
    );
  }
}
