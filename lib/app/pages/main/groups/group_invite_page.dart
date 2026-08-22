import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stimmapp/app/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/constants/app_limits.dart';
import 'package:stimmapp/core/data/models/poll_group.dart';
import 'package:stimmapp/core/data/repositories/poll_group_repository.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/functions/normalize_username.dart';
import 'package:trainvent_general/trainvent_general.dart';

class GroupInvitePage extends StatefulWidget {
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
  State<GroupInvitePage> createState() => _GroupInvitePageState();
}

class _GroupInvitePageState extends State<GroupInvitePage> {
  final List<_InviteMemberDraft> _memberDrafts = [];
  List<PollGroupAllowedMember> _existingAllowedMembers = const [];
  List<PollGroupAllowedDomain> _allowedDomains = const [];
  bool _isSending = false;
  bool _isDraggingCsv = false;
  int _lastImportedCsvRows = 0;
  int _lastInvalidCsvRows = 0;
  bool _isLoadingRules = true;

  PollGroupRepository get _repository =>
      widget.repository ?? PollGroupRepository.create();
  AuthService get _auth => widget.auth ?? authService;
  UserRepository get _userRepository =>
      widget.userRepository ?? UserRepository.create();
  PollGroupCsvImporter get _csvImporter =>
      widget.csvImporter ?? const DefaultPollGroupCsvImporter();

  @override
  void initState() {
    super.initState();
    _memberDrafts.add(_InviteMemberDraft());
    _loadExistingRules();
  }

  @override
  void dispose() {
    for (final draft in _memberDrafts) {
      draft.dispose();
    }
    super.dispose();
  }

  Future<void> _loadExistingRules() async {
    try {
      final allowedMembers = await _repository.getAllowedMembers(
        widget.group.id,
      );
      final allowedDomains = await _repository.getAllowedDomains(
        widget.group.id,
      );
      if (!mounted) return;
      setState(() {
        _existingAllowedMembers = allowedMembers;
        _allowedDomains = allowedDomains;
      });
    } catch (error, stackTrace) {
      if (mounted) {
        showInternalDifficultiesSnackBar(error, stackTrace);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingRules = false);
      }
    }
  }

  String _truncateToLength(String value, int maxLength) {
    if (value.length <= maxLength) return value;
    return value.substring(0, maxLength);
  }

  void _addMemberDraft({
    String email = '',
    String nickname = '',
    PollGroupRole role = PollGroupRole.user,
    bool isCommitted = false,
  }) {
    setState(() {
      _memberDrafts.add(
        _InviteMemberDraft(
          email: email,
          nickname: nickname,
          role: role,
          isCommitted: isCommitted,
        ),
      );
    });
  }

  void _removeMemberDraft(int index) {
    if (_memberDrafts.length == 1) {
      _memberDrafts[index].emailController.clear();
      _memberDrafts[index].nicknameController.clear();
      setState(() {
        _memberDrafts[index].role = PollGroupRole.user;
        _memberDrafts[index].isCommitted = false;
      });
      return;
    }
    final draft = _memberDrafts.removeAt(index);
    draft.dispose();
    setState(() {});
    _ensurePendingMemberDraft();
  }

  bool _isMemberDraftBlank(_InviteMemberDraft draft) {
    return draft.emailController.text.trim().isEmpty &&
        draft.nicknameController.text.trim().isEmpty &&
        draft.role == PollGroupRole.user;
  }

  void _ensurePendingMemberDraft() {
    if (_memberDrafts.any((draft) => !draft.isCommitted)) return;
    _addMemberDraft();
  }

  void _confirmMemberDraft(int index) {
    final draft = _memberDrafts[index];
    final identifier = draft.emailController.text.trim();
    final isEmail = _looksLikeEmail(identifier);
    final isUsername =
        !identifier.contains('@') && hasValidUsernameLength(identifier);
    if (!isEmail && !isUsername) {
      showErrorSnackBar(
        context.l10n.pleaseEnterValidEmailOrUsernameForEveryInvitedMember,
      );
      return;
    }
    setState(() {
      draft.emailController.text = isEmail
          ? identifier.toLowerCase()
          : normalizeUsername(identifier);
      draft.isCommitted = true;
    });
    _ensurePendingMemberDraft();
  }

  Future<void> _openCsvPasteDialog() async {
    final controller = TextEditingController();
    final imported = await showDialog<_CsvImportResult>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.pasteCsvMembers),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: controller,
            minLines: 8,
            maxLines: 12,
            decoration: InputDecoration(
              hintText: context.l10n.csvMembersHint,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(
              dialogContext,
            ).pop(_parseCsvMembers(controller.text)),
            child: Text(context.l10n.importLabel),
          ),
        ],
      ),
    );
    controller.dispose();
    if (imported != null) _applyCsvImport(imported);
  }

  Future<void> _pickCsvFile() async {
    final content = await _csvImporter.pickCsvText();
    if (!mounted || content == null) return;
    _applyCsvImport(_parseCsvMembers(content));
  }

  Future<void> _handleDroppedCsv(DropDoneDetails details) async {
    var importedAny = false;
    var combinedValid = 0;
    var combinedInvalid = 0;
    for (final file in details.files) {
      if (!_looksLikeCsvName(file.name)) continue;
      final result = _parseCsvMembers(utf8.decode(await file.readAsBytes()));
      if (result.members.isNotEmpty || result.invalidRows > 0) {
        importedAny = true;
        combinedValid += result.members.length;
        combinedInvalid += result.invalidRows;
        _appendImportedMembers(result.members);
      }
    }
    if (!mounted || !importedAny) return;
    setState(() {
      _lastImportedCsvRows = combinedValid;
      _lastInvalidCsvRows = combinedInvalid;
      _isDraggingCsv = false;
    });
    _showCsvFeedback(validRows: combinedValid, invalidRows: combinedInvalid);
  }

  _CsvImportResult _parseCsvMembers(String raw) {
    final normalized = raw
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .trim();
    if (normalized.isEmpty) {
      return const _CsvImportResult(members: [], invalidRows: 0);
    }
    final rows = Csv(
      fieldDelimiter: _detectDelimiter(normalized),
      lineDelimiter: '\n',
      autoDetect: false,
    ).decode(normalized);
    final members = <_ImportedMemberDraft>[];
    var invalidRows = 0;
    for (var index = 0; index < rows.length; index += 1) {
      final cells = rows[index]
          .map((cell) => cell?.toString() ?? '')
          .toList(growable: false);
      if (index == 0 && _looksLikeHeader(cells)) continue;
      final email = cells.isNotEmpty ? cells[0].trim().toLowerCase() : '';
      if (!_looksLikeEmail(email)) {
        invalidRows += 1;
        continue;
      }
      final nickname = cells.length > 1 ? cells[1].trim() : '';
      final role = _parseRoleOrNull(
        cells.length > 2 ? cells[2].trim().toLowerCase() : 'user',
      );
      if (role == null) {
        invalidRows += 1;
        continue;
      }
      members.add(
        _ImportedMemberDraft(
          email: email,
          nickname: _truncateToLength(
            nickname,
            AppLimits.maxGroupNicknameLength,
          ),
          role: role,
        ),
      );
    }
    return _CsvImportResult(members: members, invalidRows: invalidRows);
  }

  String _detectDelimiter(String raw) {
    final firstLine = raw.split(RegExp(r'\r?\n')).first;
    final candidates = <String, int>{
      '\t': '\t'.allMatches(firstLine).length,
      ';': ';'.allMatches(firstLine).length,
      ',': ','.allMatches(firstLine).length,
    };
    return candidates.entries.reduce((best, current) {
      return current.value > best.value ? current : best;
    }).key;
  }

  bool _looksLikeHeader(List<String> cells) {
    if (cells.isEmpty) return false;
    final first = cells.first.trim().toLowerCase();
    return first == 'email' || first == 'e-mail' || first == 'mail';
  }

  PollGroupRole? _parseRoleOrNull(String value) {
    switch (value) {
      case '':
      case 'user':
      case 'benutzer':
      case 'mitglied':
        return PollGroupRole.user;
      case 'manager':
        return PollGroupRole.manager;
      case 'admin':
        return PollGroupRole.admin;
      default:
        return null;
    }
  }

  void _applyCsvImport(_CsvImportResult result) {
    _appendImportedMembers(result.members);
    setState(() {
      _lastImportedCsvRows = result.members.length;
      _lastInvalidCsvRows = result.invalidRows;
    });
    _showCsvFeedback(
      validRows: result.members.length,
      invalidRows: result.invalidRows,
    );
  }

  void _appendImportedMembers(List<_ImportedMemberDraft> members) {
    if (members.isEmpty) return;
    if (_memberDrafts.length == 1 && _isMemberDraftBlank(_memberDrafts.first)) {
      _memberDrafts.removeLast().dispose();
    }
    setState(() {
      for (final member in members) {
        _memberDrafts.add(
          _InviteMemberDraft(
            email: member.email,
            nickname: member.nickname,
            role: member.role,
            isCommitted: true,
          ),
        );
      }
    });
    _ensurePendingMemberDraft();
  }

  void _showCsvFeedback({required int validRows, required int invalidRows}) {
    if (validRows == 0 && invalidRows == 0) {
      showErrorSnackBar(context.l10n.noCsvRowsImported);
    } else if (invalidRows == 0) {
      showSuccessSnackBar(context.l10n.importedCsvRows(validRows));
    } else {
      showErrorSnackBar(
        context.l10n.importedRowsSkippedMalformed(validRows, invalidRows),
      );
    }
  }

  bool _looksLikeEmail(String value) =>
      value.contains('@') && value.contains('.');

  bool _looksLikeCsvName(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.csv') || lower.endsWith('.tsv');
  }

  Future<String?> _resolveInviteEmail(String identifier) async {
    final trimmed = identifier.trim();
    if (_looksLikeEmail(trimmed)) return trimmed.toLowerCase();
    if (trimmed.contains('@') || !hasValidUsernameLength(trimmed)) {
      showErrorSnackBar(
        context.l10n.pleaseEnterValidEmailOrUsernameForEveryInvitedMember,
      );
      return null;
    }
    final profile = await _userRepository.getByUsername(trimmed);
    if (!mounted) return null;
    final email = profile?.email?.trim().toLowerCase();
    if (email == null || !_looksLikeEmail(email)) {
      showErrorSnackBar(context.l10n.userNotFound);
      return null;
    }
    return email;
  }

  Future<List<PollGroupAllowedMember>?> _buildAllowedMembers(
    String creatorUid,
  ) async {
    final now = DateTime.now();
    final members = <PollGroupAllowedMember>[];
    for (final draft in _memberDrafts) {
      if (_isMemberDraftBlank(draft)) continue;
      final email = await _resolveInviteEmail(draft.emailController.text);
      if (email == null || !mounted) return null;
      final nickname = _truncateToLength(
        draft.nicknameController.text.trim(),
        AppLimits.maxGroupNicknameLength,
      );
      members.add(
        PollGroupAllowedMember(
          email: email,
          nickname: nickname.isEmpty ? null : nickname,
          role: draft.role,
          createdAt: now,
          createdBy: creatorUid,
        ),
      );
    }
    return PollGroupRepository.normalizeAllowedMembers(members);
  }

  Future<void> _sendInvitations() async {
    final user = _auth.currentUser;
    if (user == null) {
      showErrorSnackBar(context.l10n.pleaseSignInFirst);
      return;
    }
    final newMembers = await _buildAllowedMembers(user.uid);
    if (!mounted || newMembers == null) return;
    if (newMembers.isEmpty) {
      showErrorSnackBar(context.l10n.pleaseAddMemberToInvite);
      return;
    }
    final mergedMembers = PollGroupRepository.normalizeAllowedMembers([
      ..._existingAllowedMembers,
      ...newMembers,
    ]);
    setState(() => _isSending = true);
    try {
      final invitationCount = await _repository.updateGroup(
        group: widget.group.copyWith(importedMemberCount: mergedMembers.length),
        allowedMembers: mergedMembers,
        allowedDomains: _allowedDomains,
        inviteEmails: newMembers.map((member) => member.email).toList(),
      );
      if (!mounted) return;
      for (final draft in _memberDrafts) {
        draft.dispose();
      }
      setState(() {
        _existingAllowedMembers = mergedMembers;
        _memberDrafts
          ..clear()
          ..add(_InviteMemberDraft());
        _lastImportedCsvRows = 0;
        _lastInvalidCsvRows = 0;
      });
      if (invitationCount == 0) {
        showErrorSnackBar(context.l10n.noNewInvitationsSent);
      } else {
        showSuccessSnackBar(
          context.l10n.memberInvitationsSent(invitationCount),
        );
      }
    } catch (error, stackTrace) {
      await showInternalDifficultiesSnackBar(error, stackTrace);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _roleLabel(PollGroupRole role) {
    switch (role) {
      case PollGroupRole.admin:
        return context.l10n.adminRoleLabel;
      case PollGroupRole.manager:
        return context.l10n.managerRoleLabel;
      case PollGroupRole.user:
        return context.l10n.userRoleLabel;
    }
  }

  Widget _buildRoleDropdown({
    required PollGroupRole value,
    required ValueChanged<PollGroupRole?> onChanged,
    Key? key,
  }) {
    return DropdownButtonFormField<PollGroupRole>(
      key: key,
      initialValue: value,
      decoration: InputDecoration(
        labelText: context.l10n.roleLabel,
        border: const OutlineInputBorder(),
      ),
      items: PollGroupRole.values
          .map(
            (role) => DropdownMenuItem<PollGroupRole>(
              value: role,
              child: Text(_roleLabel(role)),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildMemberEmailField(_InviteMemberDraft draft, int index) {
    return TextField(
      key: Key('member_email_$index'),
      controller: draft.emailController,
      decoration: InputDecoration(
        labelText: '${context.l10n.emailOrUsername} *',
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildMemberNicknameField(_InviteMemberDraft draft, int index) {
    return TextField(
      key: Key('member_nickname_$index'),
      controller: draft.nicknameController,
      maxLength: AppLimits.maxGroupNicknameLength,
      inputFormatters: [
        LengthLimitingTextInputFormatter(AppLimits.maxGroupNicknameLength),
      ],
      decoration: InputDecoration(
        labelText: context.l10n.nickname,
        border: const OutlineInputBorder(),
        counterText: '',
      ),
    );
  }

  Widget _buildMemberRoleField(_InviteMemberDraft draft, int index) {
    return _buildRoleDropdown(
      key: Key('member_role_$index'),
      value: draft.role,
      onChanged: (value) {
        if (value == null) {
          return;
        }
        setState(() {
          draft.role = value;
        });
      },
    );
  }

  Widget _buildMemberDraftAction(_InviteMemberDraft draft, int index) {
    if (draft.isCommitted) {
      return IconButton(
        key: Key('remove_member_row_$index'),
        onPressed: () => _removeMemberDraft(index),
        icon: const Icon(Icons.delete_outline),
        tooltip: context.l10n.removeMemberTooltip,
      );
    }

    return IconButton(
      key: Key('confirm_member_row_$index'),
      onPressed: () => _confirmMemberDraft(index),
      icon: const Icon(Icons.check_circle_outline),
      tooltip: context.l10n.addMember,
    );
  }

  Widget _buildMemberDraftRow(_InviteMemberDraft draft, int index) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useCompactLayout = constraints.maxWidth < 560;
        if (!useCompactLayout) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildMemberEmailField(draft, index)),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: _buildMemberNicknameField(draft, index)),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: _buildMemberRoleField(draft, index)),
              const SizedBox(width: 8),
              _buildMemberDraftAction(draft, index),
            ],
          );
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildMemberEmailField(draft, index)),
                  const SizedBox(width: 8),
                  _buildMemberDraftAction(draft, index),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildMemberNicknameField(draft, index)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildMemberRoleField(draft, index)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInviteMembersSection({bool showTitle = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Text(
            context.l10n.inviteMembersTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
        ],
        ...List.generate(_memberDrafts.length, (index) {
          final draft = _memberDrafts[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildMemberDraftRow(draft, index),
          );
        }),
        const SizedBox(height: 12),
        DropTarget(
          onDragEntered: (_) => setState(() => _isDraggingCsv = true),
          onDragExited: (_) => setState(() => _isDraggingCsv = false),
          onDragDone: _handleDroppedCsv,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: _isDraggingCsv
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).dividerColor,
                width: _isDraggingCsv ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: _isDraggingCsv
                  ? Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.06)
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.dropCsvHere,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.acceptedCsvFormat,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    context.l10n.csvColumnFormat,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      key: const Key('paste_csv_button'),
                      onPressed: _openCsvPasteDialog,
                      icon: const Icon(Icons.content_paste),
                      label: Text(context.l10n.pasteCsvLabel),
                    ),
                    OutlinedButton.icon(
                      key: const Key('pick_csv_button'),
                      onPressed: _pickCsvFile,
                      icon: const Icon(Icons.upload_file),
                      label: Text(context.l10n.importCsvFileLabel),
                    ),
                  ],
                ),
                if (_lastImportedCsvRows > 0 || _lastInvalidCsvRows > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.lastImportSummary(
                      _lastImportedCsvRows,
                      _lastInvalidCsvRows,
                    ),
                    key: const Key('csv_import_summary'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.inviteMembersTitle)),
      body: user == null
          ? Center(child: Text(context.l10n.pleaseSignInToManageGroups))
          : _isLoadingRules
          ? const Center(child: TriangleLoadingIndicator(showFill: false))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildInviteMembersSection(showTitle: false),
                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const Key('send_group_invitations'),
                  onPressed: _isSending ? null : _sendInvitations,
                  icon: _isSending
                      ? const SizedBox.square(
                          dimension: 18,
                          child: Center(
                            child: TriangleLoadingIndicator(
                              size: 18,
                              strokeWidth: 2,
                              showFill: false,
                            ),
                          ),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Text(
                    _isSending
                        ? context.l10n.sendingInvitations
                        : context.l10n.sendInvitations,
                  ),
                ),
              ],
            ),
    );
  }
}

class _InviteMemberDraft {
  _InviteMemberDraft({
    String email = '',
    String nickname = '',
    this.role = PollGroupRole.user,
    this.isCommitted = false,
  }) : emailController = TextEditingController(text: email),
       nicknameController = TextEditingController(text: nickname);

  final TextEditingController emailController;
  final TextEditingController nicknameController;
  PollGroupRole role;
  bool isCommitted;

  void dispose() {
    emailController.dispose();
    nicknameController.dispose();
  }
}

class _ImportedMemberDraft {
  const _ImportedMemberDraft({
    required this.email,
    required this.nickname,
    required this.role,
  });

  final String email;
  final String nickname;
  final PollGroupRole role;
}

class _CsvImportResult {
  const _CsvImportResult({required this.members, required this.invalidRows});

  final List<_ImportedMemberDraft> members;
  final int invalidRows;
}

abstract class PollGroupCsvImporter {
  const PollGroupCsvImporter();

  Future<String?> pickCsvText();
}

class DefaultPollGroupCsvImporter extends PollGroupCsvImporter {
  const DefaultPollGroupCsvImporter();

  @override
  Future<String?> pickCsvText() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'tsv'],
    );
    if (file == null) return null;
    return utf8.decode(await file.readAsBytes());
  }
}
