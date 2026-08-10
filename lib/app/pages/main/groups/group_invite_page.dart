import 'package:flutter/material.dart';
import 'package:stimmapp/app/pages/main/groups/group_editor_page.dart';
import 'package:stimmapp/core/data/models/poll_group.dart';
import 'package:stimmapp/core/data/repositories/poll_group_repository.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';

class GroupInvitePage extends StatelessWidget {
  const GroupInvitePage({
    super.key,
    required this.group,
    this.repository,
    this.auth,
    this.userRepository,
    this.csvImporter,
  });

  final PollGroup group;
  final PollGroupRepository? repository;
  final AuthService? auth;
  final UserRepository? userRepository;
  final PollGroupCsvImporter? csvImporter;

  @override
  Widget build(BuildContext context) {
    return GroupEditorPage(
      initialGroup: group,
      repository: repository,
      auth: auth,
      userRepository: userRepository,
      csvImporter: csvImporter,
      inviteOnly: true,
    );
  }
}
