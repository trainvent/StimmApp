import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/widgets/triangle_loading_indicator.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  final _userRepo = UserRepository.create();
  final _currentUser = authService.currentUser;

  Future<void> _toggleCrashLogs(bool value, UserProfile profile) async {
    try {
      final updatedProfile = profile.copyWith(sendCrashLogs: value);
      await _userRepo.upsert(updatedProfile);
      // TODO: Initialize/Deinitialize crash reporting SDK here if possible
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.l10n.error}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.privacySettings)),
        body: Center(child: Text(context.l10n.pleaseSignInFirst)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.privacySettings)),
      body: StreamBuilder<UserProfile?>(
        stream: _userRepo.watchById(_currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: TriangleLoadingIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${context.l10n.error}: ${snapshot.error}'));
          }
          final profile = snapshot.data;
          if (profile == null) {
            return Center(child: Text(context.l10n.userNotFound));
          }

          final sendCrashLogs = profile.sendCrashLogs ?? true; // Default to true

          return ListView(
            children: [
              SwitchListTile(
                title: Text(context.l10n.sendCrashLogs),
                subtitle: Text(context.l10n.sendCrashLogsDescription),
                value: sendCrashLogs,
                onChanged: (value) => _toggleCrashLogs(value, profile),
              ),
            ],
          );
        },
      ),
    );
  }
}
