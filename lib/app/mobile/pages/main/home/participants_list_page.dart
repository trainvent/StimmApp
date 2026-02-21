import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/widgets/triangle_loading_indicator.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

class ParticipantsListPage extends StatelessWidget {
  const ParticipantsListPage({
    super.key,
    required this.participantsStream,
    this.signaturesStream,
  });

  final Stream<List<UserProfile>> participantsStream;
  final Stream<List<Map<String, dynamic>>>? signaturesStream;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.participantsList)),
      body: signaturesStream != null
          ? _buildWithSignatures(context)
          : _buildSimple(context),
    );
  }

  Widget _buildSimple(BuildContext context) {
    return StreamBuilder<List<UserProfile>>(
      stream: participantsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: TriangleLoadingIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(context.l10n.error));
        }
        final participants = snapshot.data ?? [];
        if (participants.isEmpty) {
          return Center(child: Text(context.l10n.noData));
        }
        return ListView.builder(
          itemCount: participants.length,
          itemBuilder: (context, index) {
            final user = participants[index];
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(user.displayName ?? context.l10n.anonymous),
            );
          },
        );
      },
    );
  }

  Widget _buildWithSignatures(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: signaturesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: TriangleLoadingIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(context.l10n.error));
        }
        final signatures = snapshot.data ?? [];
        if (signatures.isEmpty) {
          return Center(child: Text(context.l10n.noData));
        }

        return StreamBuilder<List<UserProfile>>(
          stream: participantsStream,
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: TriangleLoadingIndicator());
            }
            final users = userSnap.data ?? [];
            final userMap = {for (var u in users) u.uid: u};

            return ListView.builder(
              itemCount: signatures.length,
              itemBuilder: (context, index) {
                final sig = signatures[index];
                final uid = sig['uid'] as String;
                final reason = sig['reason'] as String?;
                final user = userMap[uid];

                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(user?.displayName ?? context.l10n.anonymous),
                  subtitle: reason != null && reason.isNotEmpty
                      ? Text('Reason: $reason')
                      : null,
                );
              },
            );
          },
        );
      },
    );
  }
}
