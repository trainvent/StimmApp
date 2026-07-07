import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stimmapp/app/mobile/widgets/triangle_loading_indicator.dart';
import 'package:stimmapp/core/data/models/petition.dart';
import 'package:stimmapp/core/data/models/poll.dart';
import 'package:stimmapp/core/data/models/survey.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/petition_repository.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

enum FormResultType { petition, poll, survey }

class FormResultPage extends StatelessWidget {
  const FormResultPage.petition({super.key, required this.petition})
    : type = FormResultType.petition,
      poll = null,
      survey = null;

  const FormResultPage.poll({super.key, required this.poll})
    : type = FormResultType.poll,
      petition = null,
      survey = null;

  const FormResultPage.survey({super.key, required this.survey})
    : type = FormResultType.survey,
      petition = null,
      poll = null;

  final FormResultType type;
  final Petition? petition;
  final Poll? poll;
  final Survey? survey;

  @override
  Widget build(BuildContext context) {
    final title = switch (type) {
      FormResultType.petition => petition!.title,
      FormResultType.poll => poll!.title,
      FormResultType.survey => survey!.title,
    };

    return Scaffold(
      appBar: AppBar(title: Text(_pageTitle(context))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            _expiresAtLabel(context, switch (type) {
              FormResultType.petition => petition!.expiresAt,
              FormResultType.poll => poll!.expiresAt,
              FormResultType.survey => survey!.expiresAt,
            }),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          switch (type) {
            FormResultType.petition => _PetitionResults(petition: petition!),
            FormResultType.poll => _PollResults(poll: poll!),
            FormResultType.survey => _SurveyResults(survey: survey!),
          },
        ],
      ),
    );
  }

  String _pageTitle(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'de'
        ? 'Endergebnis'
        : 'Final results';
  }

  String _expiresAtLabel(BuildContext context, DateTime expiresAt) {
    final date = DateFormat('yyyy-MM-dd').format(expiresAt);
    return Localizations.localeOf(context).languageCode == 'de'
        ? 'Abgeschlossen am $date'
        : 'Finished on $date';
  }
}

class _PetitionResults extends StatelessWidget {
  const _PetitionResults({required this.petition});

  final Petition petition;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: PetitionRepository.create().getParticipantsWithSignaturesOnce(
        petition.id,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: TriangleLoadingIndicator());
        }
        final signatures = snapshot.data ?? const <Map<String, dynamic>>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryNumber(
              value: petition.signatureCount,
              label: context.l10n.signatures,
            ),
            const SizedBox(height: 24),
            if (signatures.isEmpty)
              Text(_emptyResultsLabel(context))
            else
              ...signatures.map((signature) {
                final profile = signature['profile'] as UserProfile?;
                final reason = signature['reason'] as String?;
                final name = [
                  profile?.givenName,
                  profile?.surname,
                ].where((part) => part?.trim().isNotEmpty == true).join(' ');
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.how_to_reg),
                  title: Text(name.isEmpty ? profile?.email ?? '-' : name),
                  subtitle: reason == null || reason.trim().isEmpty
                      ? null
                      : Text(reason),
                );
              }),
          ],
        );
      },
    );
  }
}

class _PollResults extends StatelessWidget {
  const _PollResults({required this.poll});

  final Poll poll;

  @override
  Widget build(BuildContext context) {
    final totalVotes = poll.totalVotes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryNumber(value: totalVotes, label: _votesLabel(context)),
        const SizedBox(height: 24),
        if (poll.options.isEmpty)
          Text(_emptyResultsLabel(context))
        else
          ...poll.options.map((option) {
            final count = poll.votes[option.id] ?? 0;
            return _ResultBar(
              label: option.label,
              count: count,
              total: totalVotes,
            );
          }),
      ],
    );
  }
}

class _SurveyResults extends StatelessWidget {
  const _SurveyResults({required this.survey});

  final Survey survey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryNumber(
          value: survey.responseCount,
          label: _responsesLabel(context),
        ),
        const SizedBox(height: 24),
        if (survey.questions.isEmpty)
          Text(_emptyResultsLabel(context))
        else
          ...survey.questions.map((question) {
            final totalVotes = survey.totalVotesForQuestion(question.id);
            final optionVotes =
                survey.questionVotes[question.id] ?? const <String, int>{};
            return Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  for (final option in question.options)
                    _ResultBar(
                      label: option.label,
                      count: optionVotes[option.id] ?? 0,
                      total: totalVotes,
                    ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _SummaryNumber extends StatelessWidget {
  const _SummaryNumber({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(
              value.toString(),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultBar extends StatelessWidget {
  const _ResultBar({
    required this.label,
    required this.count,
    required this.total,
  });

  final String label;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : count / total;
    final percentage = NumberFormat.percentPattern(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(ratio);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text('$count · $percentage'),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
    );
  }
}

String _votesLabel(BuildContext context) {
  return Localizations.localeOf(context).languageCode == 'de'
      ? 'Stimmen'
      : 'votes';
}

String _responsesLabel(BuildContext context) {
  return Localizations.localeOf(context).languageCode == 'de'
      ? 'Antworten'
      : 'responses';
}

String _emptyResultsLabel(BuildContext context) {
  return Localizations.localeOf(context).languageCode == 'de'
      ? 'Keine Ergebnisse vorhanden.'
      : 'No results available.';
}
