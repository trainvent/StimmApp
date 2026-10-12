import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:stimmapp/app/scaffolds/app_bottom_bar_buttons.dart';
import 'package:trainvent_general/trainvent_general.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/theme/app_text_styles.dart';

class UserHistoryPage extends StatefulWidget {
  const UserHistoryPage({super.key, this.uid, this.database});

  @visibleForTesting
  final String? uid;

  @visibleForTesting
  final FirebaseFirestore? database;

  @override
  State<UserHistoryPage> createState() => _UserHistoryPageState();
}

class _UserHistoryPageState extends State<UserHistoryPage> {
  late Future<List<_HistoryItem>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _fetchUserHistory();
  }

  Future<List<_HistoryItem>> _fetchUserHistory() async {
    final uid = widget.uid ?? authService.currentUser?.uid;
    if (uid == null) return [];

    final db = widget.database ?? locator.database;
    final userDocRef = db.collection('users').doc(uid);

    final signedPetitionsFuture = userDocRef
        .collection('signedPetitions')
        .get();
    final votedPollsFuture = userDocRef.collection('votedPolls').get();
    final createdPetitionsFuture = db
        .collection('petitions')
        .where('createdBy', isEqualTo: uid)
        .get();
    final createdPollsFuture = db
        .collection('polls')
        .where('createdBy', isEqualTo: uid)
        .get();

    final completedSurveysFuture = userDocRef
        .collection('completedSurveys')
        .get();
    final createdSurveysFuture = db
        .collection('surveys')
        .where('createdBy', isEqualTo: uid)
        .get();

    final results = await Future.wait([
      signedPetitionsFuture,
      votedPollsFuture,
      createdPetitionsFuture,
      createdPollsFuture,
      completedSurveysFuture,
      createdSurveysFuture,
    ]);

    final signedPetitionsSnapshot = results[0];
    final votedPollsSnapshot = results[1];
    final createdPetitionsSnapshot = results[2];
    final createdPollsSnapshot = results[3];
    final completedSurveysSnapshot = results[4];
    final createdSurveysSnapshot = results[5];

    final List<Future<DocumentSnapshot>> petitionFutures =
        signedPetitionsSnapshot.docs
            .map((doc) => db.collection('petitions').doc(doc.id).get())
            .toList();

    final List<Future<DocumentSnapshot>> pollFutures = votedPollsSnapshot.docs
        .map((doc) => db.collection('polls').doc(doc.id).get())
        .toList();

    final petitionSnapshots = await Future.wait(petitionFutures);
    final pollSnapshots = await Future.wait(pollFutures);

    final surveySnapshots = await Future.wait(
      completedSurveysSnapshot.docs.map(
        (doc) => db.collection('surveys').doc(doc.id).get(),
      ),
    );

    final historyItems = <_HistoryItem>[];

    for (var index = 0; index < petitionSnapshots.length; index++) {
      final doc = petitionSnapshots[index];
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final activity = signedPetitionsSnapshot.docs[index].data();
        historyItems.add(
          _HistoryItem(
            title: data['title'] as String?,
            type: _HistoryType.petition,
            action: _HistoryAction.participation,
            timestamp: _toDateTime(activity['signedAt']),
          ),
        );
      }
    }

    for (var index = 0; index < pollSnapshots.length; index++) {
      final doc = pollSnapshots[index];
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final activity = votedPollsSnapshot.docs[index].data();
        historyItems.add(
          _HistoryItem(
            title: data['title'] as String?,
            type: _HistoryType.poll,
            action: _HistoryAction.participation,
            timestamp: _toDateTime(activity['votedAt']),
          ),
        );
      }
    }

    for (final doc in createdPetitionsSnapshot.docs) {
      final data = doc.data();
      historyItems.add(
        _HistoryItem(
          title: data['title'] as String?,
          type: _HistoryType.petition,
          action: _HistoryAction.publication,
          timestamp: _toDateTime(data['createdAt']),
        ),
      );
    }

    for (final doc in createdPollsSnapshot.docs) {
      final data = doc.data();
      historyItems.add(
        _HistoryItem(
          title: data['title'] as String?,
          type: _HistoryType.poll,
          action: _HistoryAction.publication,
          timestamp: _toDateTime(data['createdAt']),
        ),
      );
    }

    for (var index = 0; index < surveySnapshots.length; index++) {
      final doc = surveySnapshots[index];
      if (!doc.exists) continue;
      final data = doc.data() as Map<String, dynamic>;
      historyItems.add(
        _HistoryItem(
          title: data['title'] as String?,
          type: _HistoryType.survey,
          action: _HistoryAction.participation,
          timestamp: _toDateTime(
            completedSurveysSnapshot.docs[index].data()['submittedAt'],
          ),
        ),
      );
    }
    for (final doc in createdSurveysSnapshot.docs) {
      final data = doc.data();
      historyItems.add(
        _HistoryItem(
          title: data['title'] as String?,
          type: _HistoryType.survey,
          action: _HistoryAction.publication,
          timestamp: _toDateTime(data['createdAt']),
        ),
      );
    }

    historyItems.sort((a, b) {
      final aTimestamp = a.timestamp;
      final bTimestamp = b.timestamp;
      if (aTimestamp == null && bTimestamp == null) return 0;
      if (aTimestamp == null) return 1;
      if (bTimestamp == null) return -1;

      return bTimestamp.compareTo(aTimestamp);
    });
    return historyItems;
  }

  DateTime? _toDateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomBarButtons(
      appBar: AppBar(
        title: Text(context.l10n.activityHistory, style: AppTextStyles.lBold),
      ),
      body: FutureBuilder<List<_HistoryItem>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: TriangleLoadingIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('${context.l10n.error}${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(context.l10n.noActivityFound, style: AppTextStyles.m),
            );
          }

          final historyItems = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: historyItems.length,
            itemBuilder: (context, index) {
              final item = historyItems[index];
              final isPetition = item.type == _HistoryType.petition;
              final isPublication = item.action == _HistoryAction.publication;
              final title = item.title ?? context.l10n.noTitle;
              final action = switch ((item.type, isPublication)) {
                (_HistoryType.petition, true) => context.l10n.createdPetition,
                (_HistoryType.poll, true) => context.l10n.createdPoll,
                (_HistoryType.survey, true) => context.l10n.createdSurvey,
                (_HistoryType.petition, false) => context.l10n.signed,
                (_HistoryType.poll, false) => context.l10n.voted,
                (_HistoryType.survey, false) => context.l10n.surveySubmitted,
              };

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  leading: Icon(
                    isPetition
                        ? Icons.article
                        : item.type == _HistoryType.survey
                        ? Icons.list_alt
                        : Icons.poll,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(title, style: AppTextStyles.mBold),
                  subtitle: Text(action, style: AppTextStyles.s),
                  trailing: Tooltip(
                    message: isPublication ? context.l10n.publications : action,
                    child: Icon(
                      isPublication
                          ? Icons.publish_outlined
                          : Icons.how_to_vote_outlined,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      buttons: const [], // No buttons needed for this page
    );
  }
}

enum _HistoryType { petition, poll, survey }

enum _HistoryAction { participation, publication }

class _HistoryItem {
  const _HistoryItem({
    required this.title,
    required this.type,
    required this.action,
    required this.timestamp,
  });

  final String? title;
  final _HistoryType type;
  final _HistoryAction action;
  final DateTime? timestamp;
}
