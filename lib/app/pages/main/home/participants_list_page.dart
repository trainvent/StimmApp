import 'package:flutter/material.dart';
import 'package:stimmapp/app/pages/main/profile/public_profile_page.dart';
import 'package:trainvent_general/trainvent_general.dart';
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

  void _openProfile(BuildContext context, String uid) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PublicProfilePage(userId: uid)),
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
              onTap:
                  user.uid.isEmpty || user.hasLoadError || user.signAnonymously
                  ? null
                  : () => _openProfile(context, user.uid),
              leading: _ParticipantAvatar(user: user),
              title: Text(
                user.signAnonymously
                    ? context.l10n.anonymous
                    : user.hasLoadError
                    ? context.l10n.erroneousProfile
                    : user.displayName ?? context.l10n.anonymous,
              ),
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
            if (userSnap.hasError) {
              return Center(child: Text(context.l10n.error));
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
                  onTap:
                      uid.isEmpty ||
                          user == null ||
                          user.hasLoadError ||
                          user.signAnonymously
                      ? null
                      : () => _openProfile(context, uid),
                  leading: _ParticipantAvatar(user: user),
                  title: Text(
                    user?.signAnonymously == true
                        ? context.l10n.anonymous
                        : user?.hasLoadError == true
                        ? context.l10n.erroneousProfile
                        : user?.displayName ?? context.l10n.anonymous,
                  ),
                  subtitle:
                      user != null &&
                          !user.hasLoadError &&
                          !user.signAnonymously &&
                          reason != null &&
                          reason.isNotEmpty
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

class _ParticipantAvatar extends StatelessWidget {
  const _ParticipantAvatar({required this.user});

  final UserProfile? user;

  @override
  Widget build(BuildContext context) {
    final url = user?.hasLoadError == true || user?.signAnonymously == true
        ? null
        : user?.profilePictureUrl?.trim();
    const fallback = CircleAvatar(child: Icon(Icons.person));
    if (url == null || url.isEmpty) return fallback;

    return SizedBox.square(
      dimension: 40,
      child: ClipOval(
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
          frameBuilder: (_, child, frame, _) =>
              frame == null ? fallback : child,
        ),
      ),
    );
  }
}
