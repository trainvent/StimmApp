import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/pages/main/home/creator/poll_creator_page.dart';
import 'package:stimmapp/app/mobile/pages/main/home/creator/survey_creator_page.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

class PollSurveyCreatorChoicePage extends StatelessWidget {
  const PollSurveyCreatorChoicePage({super.key});

  Future<void> _open(BuildContext context, Widget page) async {
    await Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.polls)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ListTile(
            leading: const Icon(Icons.how_to_vote_outlined),
            title: Text(context.l10n.createPoll),
            subtitle: Text(context.l10n.createNewPollDescription),
            onTap: () => _open(context, const PollCreatorPage()),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.ballot_outlined),
            title: Text(context.l10n.createSurvey),
            subtitle: Text(context.l10n.createNewSurveyDescription),
            onTap: () => _open(context, const SurveyCreatorPage()),
          ),
        ],
      ),
    );
  }
}
