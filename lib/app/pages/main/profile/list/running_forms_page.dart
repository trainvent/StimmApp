import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stimmapp/app/widgets/snackbar_utils.dart';
import 'package:trainvent_general/trainvent_general.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/models/petition.dart';
import 'package:stimmapp/core/data/models/poll.dart';
import 'package:stimmapp/core/data/models/survey.dart';
import 'package:stimmapp/core/data/repositories/petition_repository.dart';
import 'package:stimmapp/core/data/repositories/poll_repository.dart';
import 'package:stimmapp/core/data/repositories/survey_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/notifiers/quota_update_notifier.dart';
import 'package:stimmapp/generated/l10n.dart';

class RunningFormsPage extends StatefulWidget {
  RunningFormsPage({
    super.key,
    AuthService? auth,
    this.petitionsStreamFactory,
    this.pollsStreamFactory,
    this.surveysStreamFactory,
  }) : auth = auth ?? authService;

  final AuthService auth;
  final Stream<List<Petition>> Function()? petitionsStreamFactory;
  final Stream<List<Poll>> Function()? pollsStreamFactory;
  final Stream<List<Survey>> Function()? surveysStreamFactory;

  @override
  State<RunningFormsPage> createState() => _RunningFormsPageState();
}

class _RunningFormsPageState extends State<RunningFormsPage> {
  late final Stream<List<Petition>> _petitionsStream;
  late final Stream<List<Poll>> _pollsStream;
  late final Stream<List<Survey>> _surveysStream;

  @override
  void initState() {
    super.initState();
    _petitionsStream = _runningPetitionsByMe().map(
      (list) => [...list]..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
    _pollsStream = _runningPollsByMe().map(
      (list) => [...list]..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
    _surveysStream = _runningSurveysByMe().map(
      (list) => [...list]..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }

  Stream<List<Petition>> _runningPetitionsByMe() {
    final factory = widget.petitionsStreamFactory;
    if (factory != null) return factory();
    return PetitionRepository.create()
        .list(query: null, status: IConst.active)
        .map((items) {
          final uid = widget.auth.currentUser?.uid;
          final now = DateTime.now();
          return items
              .where((p) => p.createdBy == uid && p.expiresAt.isAfter(now))
              .toList();
        });
  }

  Stream<List<Poll>> _runningPollsByMe() {
    final factory = widget.pollsStreamFactory;
    if (factory != null) return factory();
    return PollRepository.create().list(query: null, status: IConst.active).map(
      (items) {
        final uid = widget.auth.currentUser?.uid;
        final now = DateTime.now();
        return items
            .where((p) => p.createdBy == uid && p.expiresAt.isAfter(now))
            .toList();
      },
    );
  }

  Stream<List<Survey>> _runningSurveysByMe() {
    final factory = widget.surveysStreamFactory;
    if (factory != null) return factory();
    return SurveyRepository.create()
        .list(query: null, status: IConst.active)
        .map((items) {
          final uid = widget.auth.currentUser?.uid;
          final now = DateTime.now();
          return items
              .where((s) => s.createdBy == uid && s.expiresAt.isAfter(now))
              .toList();
        });
  }

  Future<void> _deletePetition(Petition petition) async {
    final hasNoSignatures = petition.signatureCount == 0;

    if (!hasNoSignatures) {
      showErrorSnackBar(S.of(context).cannotDeletePetitionHasSignatures);
      return;
    }

    final confirm = await _showDeleteDialog();
    if (confirm == true) {
      await PetitionRepository.create().delete(petition.id);
      QuotaUpdateNotifier.instance.notify();
      if (mounted) {
        showSuccessSnackBar(S.of(context).petitionDeleted);
      }
    }
  }

  Future<void> _deletePoll(Poll poll) async {
    final hasNoVotes = poll.totalVotes == 0;

    if (!hasNoVotes) {
      showErrorSnackBar(S.of(context).cannotDeletePollHasVotes);
      return;
    }

    final confirm = await _showDeleteDialog();
    if (confirm == true) {
      await PollRepository.create().delete(poll.id);
      QuotaUpdateNotifier.instance.notify();
      if (mounted) {
        showSuccessSnackBar(S.of(context).pollDeleted);
      }
    }
  }

  Future<void> _deleteSurvey(Survey survey) async {
    final hasNoResponses = survey.responseCount == 0;

    if (!hasNoResponses) {
      showErrorSnackBar(context.l10n.cannotDeleteSurveyHasResponses);
      return;
    }

    final confirm = await _showDeleteDialog();
    if (confirm == true) {
      await SurveyRepository.create().delete(survey.id);
      QuotaUpdateNotifier.instance.notify();
      if (mounted) {
        showSuccessSnackBar(context.l10n.surveyDeleted);
      }
    }
  }

  Future<bool?> _showDeleteDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).deleteForm),
        content: Text(S.of(context).areYouSureYouWantToDeleteThisForm),
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
    );
  }

  void _openPetitionDetails(Petition petition) {
    Navigator.of(context).pushNamed('/petition/${petition.id}');
  }

  void _openPollDetails(Poll poll) {
    Navigator.of(context).pushNamed('/poll/${poll.id}');
  }

  void _openSurveyDetails(Survey survey) {
    Navigator.of(context).pushNamed('/survey/${survey.id}');
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).runningForms),
          bottom: TabBar(
            tabs: [
              Tab(text: context.l10n.petitions),
              Tab(text: context.l10n.polls),
              Tab(text: context.l10n.surveys),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPetitionsTab(),
            _buildPollsTab(),
            _buildSurveysTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildPetitionsTab() {
    return StreamBuilder<List<Petition>>(
      stream: _petitionsStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: TriangleLoadingIndicator());
        }
        if (snap.hasError) {
          debugPrint('Failed to load running petitions: ${snap.error}');
          return Center(child: Text(context.l10n.error));
        }
        final items = snap.data ?? const [];
        if (items.isEmpty) {
          return Center(child: Text(S.of(context).noRunningPetitionsFound));
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (context, i) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final p = items[i];
            final hasNoSignatures = p.signatureCount == 0;

            return ListTile(
              title: Text(p.title),
              subtitle: Text(
                'Expires: ${DateFormat('yyyy-MM-dd').format(p.expiresAt)}',
              ),
              onTap: () => _openPetitionDetails(p),
              trailing: hasNoSignatures
                  ? IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deletePetition(p),
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildPollsTab() {
    return StreamBuilder<List<Poll>>(
      stream: _pollsStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: TriangleLoadingIndicator());
        }
        if (snap.hasError) {
          debugPrint('Failed to load running polls: ${snap.error}');
          return Center(child: Text(context.l10n.error));
        }
        final items = snap.data ?? const [];
        if (items.isEmpty) {
          return Center(child: Text(S.of(context).noRunningPollsFound));
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (context, i) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final p = items[i];
            final hasNoVotes = p.totalVotes == 0;

            return ListTile(
              title: Text(p.title),
              subtitle: Text(
                'Expires: ${DateFormat('yyyy-MM-dd').format(p.expiresAt)}',
              ),
              onTap: () => _openPollDetails(p),
              trailing: hasNoVotes
                  ? IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deletePoll(p),
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildSurveysTab() {
    return StreamBuilder<List<Survey>>(
      stream: _surveysStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: TriangleLoadingIndicator());
        }
        if (snap.hasError) {
          debugPrint('Failed to load running surveys: ${snap.error}');
          return Center(child: Text(context.l10n.error));
        }
        final items = snap.data ?? const [];
        if (items.isEmpty) {
          return Center(child: Text(context.l10n.noRunningSurveysFound));
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (context, i) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final s = items[i];
            final hasNoResponses = s.responseCount == 0;

            return ListTile(
              title: Text(s.title),
              subtitle: Text(
                'Expires: ${DateFormat('yyyy-MM-dd').format(s.expiresAt)}',
              ),
              onTap: () => _openSurveyDetails(s),
              trailing: hasNoResponses
                  ? IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteSurvey(s),
                    )
                  : null,
            );
          },
        );
      },
    );
  }
}
