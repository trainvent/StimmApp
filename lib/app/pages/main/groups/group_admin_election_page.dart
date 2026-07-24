import 'package:flutter/material.dart';
import 'package:stimmapp/app/widgets/snackbar_utils.dart';
import 'package:trainvent_general/trainvent_general.dart';
import 'package:stimmapp/core/data/models/poll_group.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/poll_group_repository.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

class GroupAdminElectionPage extends StatefulWidget {
  const GroupAdminElectionPage({
    super.key,
    required this.group,
    this.repository,
    this.userRepository,
    this.auth,
  });

  final PollGroup group;
  final PollGroupRepository? repository;
  final UserRepository? userRepository;
  final AuthService? auth;

  @override
  State<GroupAdminElectionPage> createState() => _GroupAdminElectionPageState();
}

class _GroupAdminElectionPageState extends State<GroupAdminElectionPage> {
  String? _selectedCandidateUid;
  bool _isSaving = false;

  PollGroupRepository get _repository =>
      widget.repository ?? PollGroupRepository.create();
  UserRepository get _userRepository =>
      widget.userRepository ?? UserRepository.create();
  AuthService get _auth => widget.auth ?? authService;

  String _deadlineLabel(BuildContext context, DateTime value) {
    final local = value.toLocal();
    final material = MaterialLocalizations.of(context);
    return '${material.formatFullDate(local)} · ${material.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
  }

  Future<void> _castVote(String candidateUid) async {
    setState(() => _isSaving = true);
    try {
      await _repository.castAdminElectionVote(
        groupId: widget.group.id,
        candidateUid: candidateUid,
      );
      if (mounted) {
        showSuccessSnackBar(context.l10n.adminElectionVoteSaved);
      }
    } catch (error, stackTrace) {
      await showInternalDifficultiesSnackBar(error, stackTrace);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _candidateTile({
    required PollGroupMember member,
    required bool enabled,
  }) {
    return FutureBuilder<UserProfile?>(
      future: _userRepository.getById(member.uid),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final displayName = profile?.displayName?.trim();
        final email = profile?.email?.trim();
        final title = displayName?.isNotEmpty == true
            ? displayName!
            : (email?.isNotEmpty == true
                  ? email!
                  : context.l10n.unknownGroupMember);
        return RadioListTile<String>(
          key: Key('admin_election_candidate_${member.uid}'),
          value: member.uid,
          enabled: enabled,
          title: Text(title),
          subtitle: displayName?.isNotEmpty == true && email?.isNotEmpty == true
              ? Text(email!)
              : null,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        body: Center(child: Text(context.l10n.pleaseSignInFirst)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.adminElectionTitle)),
      body: StreamBuilder<PollGroupAdminElection?>(
        stream: _repository.watchAdminElection(widget.group.id),
        builder: (context, electionSnapshot) {
          if (electionSnapshot.hasError) {
            return Center(child: Text(electionSnapshot.error.toString()));
          }
          if (!electionSnapshot.hasData) {
            return const Center(
              child: TriangleLoadingIndicator(showFill: false),
            );
          }
          final election = electionSnapshot.data;
          if (election == null) {
            return Center(child: Text(context.l10n.noActiveAdminElection));
          }

          return StreamBuilder<PollGroupAdminElectionVote?>(
            stream: _repository.watchAdminElectionVote(widget.group.id, uid),
            builder: (context, voteSnapshot) {
              final savedCandidateUid = voteSnapshot.data?.candidateUid;
              final selectedUid = _selectedCandidateUid ?? savedCandidateUid;
              final electionOpen =
                  election.isOpen && DateTime.now().isBefore(election.endsAt);

              return StreamBuilder<List<PollGroupMember>>(
                stream: _repository.watchMembers(widget.group.id),
                builder: (context, membersSnapshot) {
                  if (!membersSnapshot.hasData) {
                    return const Center(
                      child: TriangleLoadingIndicator(showFill: false),
                    );
                  }
                  final candidates = membersSnapshot.data!
                      .where(
                        (member) => election.candidateUids.contains(member.uid),
                      )
                      .toList();

                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        context.l10n.adminElectionDescription,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.adminElectionDeadline(
                          _deadlineLabel(context, election.endsAt),
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 20),
                      if (candidates.isEmpty)
                        Text(context.l10n.noAdminElectionCandidates)
                      else
                        RadioGroup<String>(
                          groupValue: selectedUid,
                          onChanged: (value) {
                            if (electionOpen && !_isSaving) {
                              setState(() => _selectedCandidateUid = value);
                            }
                          },
                          child: Column(
                            children: candidates
                                .map(
                                  (member) => _candidateTile(
                                    member: member,
                                    enabled: electionOpen && !_isSaving,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        key: const Key('cast_admin_election_vote'),
                        onPressed:
                            electionOpen && selectedUid != null && !_isSaving
                            ? () => _castVote(selectedUid)
                            : null,
                        icon: _isSaving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: TriangleLoadingIndicator(
                                  size: 18,
                                  strokeWidth: 2,
                                  showFill: false,
                                ),
                              )
                            : const Icon(Icons.how_to_vote_outlined),
                        label: Text(
                          savedCandidateUid == null
                              ? context.l10n.castAdminElectionVote
                              : context.l10n.changeAdminElectionVote,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        electionOpen
                            ? context.l10n.adminElectionVoteCanChange
                            : context.l10n.adminElectionVotingClosed,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
