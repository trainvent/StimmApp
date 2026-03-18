import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/pages/main/groups/group_ui.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/data/models/poll_group.dart';
import 'package:stimmapp/core/data/repositories/poll_group_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/services/purchases_service.dart';
import 'package:universal_io/io.dart' as io;

class GroupEditorPage extends StatefulWidget {
  const GroupEditorPage({
    super.key,
    this.initialGroup,
    this.repository,
    this.auth,
    this.csvImporter,
  });

  final PollGroup? initialGroup;
  final PollGroupRepository? repository;
  final AuthService? auth;
  final PollGroupCsvImporter? csvImporter;

  @override
  State<GroupEditorPage> createState() => _GroupEditorPageState();
}

class _GroupEditorPageState extends State<GroupEditorPage> {
  final _nameController = TextEditingController();
  final List<_InviteMemberDraft> _memberDrafts = [];
  final List<_AllowedDomainDraft> _domainDrafts = [];
  bool _allowSelfNamedNicknames = true;
  bool _managersCanInvite = true;
  bool _hasExpiration = false;
  DateTime? _expiresAt;
  bool _isCreating = false;
  PollGroupAccessMode _accessMode = PollGroupAccessMode.protected;
  bool _isDraggingCsv = false;
  int _lastImportedCsvRows = 0;
  int _lastInvalidCsvRows = 0;
  bool _isLoadingExistingRules = false;

  bool get _isEditing => widget.initialGroup != null;

  PollGroupRepository get _repository =>
      widget.repository ?? PollGroupRepository.create();
  AuthService get _auth => widget.auth ?? authService;
  PollGroupCsvImporter get _csvImporter =>
      widget.csvImporter ?? const DefaultPollGroupCsvImporter();

  @override
  void initState() {
    super.initState();
    _seedForm();
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final draft in _memberDrafts) {
      draft.dispose();
    }
    for (final draft in _domainDrafts) {
      draft.dispose();
    }
    super.dispose();
  }

  Future<void> _pickExpirationDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (selected == null) {
      return;
    }
    setState(() {
      _expiresAt = selected;
      _hasExpiration = true;
    });
  }

  void _seedForm() {
    final initialGroup = widget.initialGroup;
    if (initialGroup == null) {
      _addMemberDraft();
      return;
    }

    _nameController.text = initialGroup.name;
    _allowSelfNamedNicknames =
        initialGroup.nicknameMode == PollGroupNicknameMode.selfNamed;
    _managersCanInvite = initialGroup.managersCanInvite;
    _hasExpiration = initialGroup.expiresAt != null;
    _expiresAt = initialGroup.expiresAt;
    _accessMode = initialGroup.accessMode;
    _loadExistingRules(initialGroup.id);
  }

  Future<void> _loadExistingRules(String groupId) async {
    setState(() => _isLoadingExistingRules = true);
    try {
      final allowedMembers = await _repository.getAllowedMembers(groupId);
      final allowedDomains = await _repository.getAllowedDomains(groupId);
      if (!mounted) {
        return;
      }
      for (final draft in _memberDrafts) {
        draft.dispose();
      }
      for (final draft in _domainDrafts) {
        draft.dispose();
      }
      _memberDrafts
        ..clear()
        ..addAll(
          allowedMembers.isEmpty
              ? <_InviteMemberDraft>[_InviteMemberDraft()]
              : allowedMembers
                    .map(
                      (member) => _InviteMemberDraft(
                        email: member.email,
                        nickname: member.nickname ?? '',
                        role: member.role,
                      ),
                    )
                    .toList(),
        );
      _domainDrafts
        ..clear()
        ..addAll(
          allowedDomains
              .map(
                (domain) => _AllowedDomainDraft(
                  domain: domain.domain,
                  role: domain.role,
                ),
              )
              .toList(),
        );
    } catch (error, stackTrace) {
      if (mounted) {
        showInternalDifficultiesSnackBar(error, stackTrace);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingExistingRules = false);
      }
    }
  }

  void _addMemberDraft({
    String email = '',
    String nickname = '',
    PollGroupRole role = PollGroupRole.user,
  }) {
    setState(() {
      _memberDrafts.add(
        _InviteMemberDraft(email: email, nickname: nickname, role: role),
      );
    });
  }

  void _removeMemberDraft(int index) {
    if (_memberDrafts.length == 1) {
      _memberDrafts[index].emailController.clear();
      _memberDrafts[index].nicknameController.clear();
      setState(() {
        _memberDrafts[index].role = PollGroupRole.user;
      });
      return;
    }
    final draft = _memberDrafts.removeAt(index);
    draft.dispose();
    setState(() {});
  }

  void _addDomainDraft({
    String domain = '',
    PollGroupRole role = PollGroupRole.user,
  }) {
    setState(() {
      _domainDrafts.add(_AllowedDomainDraft(domain: domain, role: role));
    });
  }

  void _removeDomainDraft(int index) {
    final draft = _domainDrafts.removeAt(index);
    draft.dispose();
    setState(() {});
  }

  Future<void> _openCsvPasteDialog() async {
    final controller = TextEditingController();
    final imported = await showDialog<_CsvImportResult>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
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
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(_parseCsvMembers(controller.text));
              },
              child: Text(context.l10n.importLabel),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (imported == null) {
      return;
    }
    _applyCsvImport(imported);
  }

  Future<void> _pickCsvFile() async {
    final content = await _csvImporter.pickCsvText();
    if (!mounted || content == null) {
      return;
    }
    _applyCsvImport(_parseCsvMembers(content));
  }

  Future<void> _handleDroppedCsv(DropDoneDetails details) async {
    var importedAny = false;
    var combinedValid = 0;
    var combinedInvalid = 0;
    for (final file in details.files) {
      if (!_looksLikeCsvName(file.name)) {
        continue;
      }
      final bytes = await file.readAsBytes();
      final result = _parseCsvMembers(utf8.decode(bytes));
      if (result.members.isNotEmpty || result.invalidRows > 0) {
        importedAny = true;
        combinedValid += result.members.length;
        combinedInvalid += result.invalidRows;
        _appendImportedMembers(result.members);
      }
    }
    if (!mounted || !importedAny) {
      return;
    }
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

    final delimiter = _detectDelimiter(normalized);
    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
    ).convert(normalized, fieldDelimiter: delimiter, eol: '\n');
    if (rows.isEmpty) {
      return const _CsvImportResult(members: [], invalidRows: 0);
    }

    final members = <_ImportedMemberDraft>[];
    var invalidRows = 0;
    for (var index = 0; index < rows.length; index += 1) {
      final cells = rows[index]
          .map((cell) => cell?.toString() ?? '')
          .toList(growable: false);
      if (index == 0 && _looksLikeHeader(cells)) {
        continue;
      }
      final email = cells.isNotEmpty ? cells[0].trim().toLowerCase() : '';
      if (!_looksLikeEmail(email)) {
        invalidRows += 1;
        continue;
      }
      final nickname = cells.length > 1 ? cells[1].trim() : '';
      final roleText = cells.length > 2
          ? cells[2].trim().toLowerCase()
          : 'user';
      final role = _parseRoleOrNull(roleText);
      if (role == null) {
        invalidRows += 1;
        continue;
      }
      members.add(
        _ImportedMemberDraft(email: email, nickname: nickname, role: role),
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
    if (cells.isEmpty) {
      return false;
    }
    final first = cells.first.trim().toLowerCase();
    return first == 'email' || first == 'mail';
  }

  PollGroupRole? _parseRoleOrNull(String value) {
    switch (value) {
      case '':
      case 'user':
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
    if (members.isEmpty) {
      return;
    }
    final shouldReplaceEmptySeed =
        _memberDrafts.length == 1 &&
        _memberDrafts.first.emailController.text.trim().isEmpty &&
        _memberDrafts.first.nicknameController.text.trim().isEmpty &&
        _memberDrafts.first.role == PollGroupRole.user;
    if (shouldReplaceEmptySeed) {
      final seed = _memberDrafts.removeLast();
      seed.dispose();
    }
    setState(() {
      for (final member in members) {
        _memberDrafts.add(
          _InviteMemberDraft(
            email: member.email,
            nickname: member.nickname,
            role: member.role,
          ),
        );
      }
    });
  }

  void _showCsvFeedback({required int validRows, required int invalidRows}) {
    if (validRows == 0 && invalidRows == 0) {
      showErrorSnackBar(context.l10n.noCsvRowsImported);
      return;
    }
    if (invalidRows == 0) {
      showSuccessSnackBar(context.l10n.importedCsvRows(validRows));
      return;
    }
    showErrorSnackBar(
      context.l10n.importedRowsSkippedMalformed(validRows, invalidRows),
    );
  }

  bool _looksLikeEmail(String value) {
    return value.contains('@') && value.contains('.');
  }

  bool _looksLikeCsvName(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.csv') || lower.endsWith('.tsv');
  }

  String _buildJoinCode() {
    final now = DateTime.now().millisecondsSinceEpoch
        .toRadixString(36)
        .toUpperCase();
    return 'GRP-${now.substring(now.length - 6)}';
  }

  bool get _inviteLinkEnabled =>
      _accessMode == PollGroupAccessMode.protected ||
      _accessMode == PollGroupAccessMode.open;

  List<PollGroupAllowedMember>? _buildAllowedMembers(String creatorUid) {
    final now = DateTime.now();
    final members = <PollGroupAllowedMember>[];
    for (final draft in _memberDrafts) {
      final email = draft.emailController.text.trim().toLowerCase();
      final nickname = draft.nicknameController.text.trim();
      if (email.isEmpty &&
          nickname.isEmpty &&
          draft.role == PollGroupRole.user) {
        continue;
      }
      if (!_looksLikeEmail(email)) {
        showErrorSnackBar(
          context.l10n.pleaseEnterValidEmailForEveryInvitedMember,
        );
        return null;
      }
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

  List<PollGroupAllowedDomain>? _buildAllowedDomains(String creatorUid) {
    final now = DateTime.now();
    final domains = <PollGroupAllowedDomain>[];
    for (final draft in _domainDrafts) {
      final normalizedDomain = PollGroupRepository.normalizeDomain(
        draft.domainController.text,
      );
      final rawValue = draft.domainController.text.trim();
      if (rawValue.isEmpty) {
        continue;
      }
      if (normalizedDomain == null) {
        showErrorSnackBar(context.l10n.pleaseEnterValidEmailDomains);
        return null;
      }
      domains.add(
        PollGroupAllowedDomain(
          domain: normalizedDomain,
          role: draft.role,
          createdAt: now,
          createdBy: creatorUid,
        ),
      );
    }
    return PollGroupRepository.normalizeAllowedDomains(domains);
  }

  Future<void> _saveGroup() async {
    final user = _auth.currentUser;
    if (user == null) {
      showErrorSnackBar(context.l10n.pleaseSignInFirst);
      return;
    }
    final groupName = _nameController.text.trim();
    if (groupName.isEmpty) {
      showErrorSnackBar(context.l10n.pleaseEnterGroupName);
      return;
    }

    final allowedMembers = _buildAllowedMembers(user.uid);
    if (allowedMembers == null) {
      return;
    }
    final allowedDomains = _buildAllowedDomains(user.uid);
    if (allowedDomains == null) {
      return;
    }

    setState(() => _isCreating = true);
    try {
      late final PollGroup group;
      if (_isEditing) {
        final existingGroup = widget.initialGroup!;
        group = existingGroup.copyWith(
          name: groupName,
          expiresAt: _hasExpiration ? _expiresAt : null,
          nicknameMode: _allowSelfNamedNicknames
              ? PollGroupNicknameMode.selfNamed
              : PollGroupNicknameMode.adminAssigned,
          managersCanInvite: _managersCanInvite,
          importedMemberCount: allowedMembers.length,
          accessMode: _accessMode,
          inviteLinkEnabled: _inviteLinkEnabled,
        );
        await _repository.updateGroup(
          group: group,
          allowedMembers: allowedMembers,
          allowedDomains: allowedDomains,
        );
      } else {
        final groupId = await _repository.createGroup(
          creatorUid: user.uid,
          name: groupName,
          joinCode: _buildJoinCode(),
          nicknameMode: _allowSelfNamedNicknames
              ? PollGroupNicknameMode.selfNamed
              : PollGroupNicknameMode.adminAssigned,
          managersCanInvite: _managersCanInvite,
          accessMode: _accessMode,
          inviteLinkEnabled: _inviteLinkEnabled,
          expiresAt: _hasExpiration ? _expiresAt : null,
          allowedMembers: allowedMembers,
          allowedDomains: allowedDomains,
        );
        group = await _repository
            .watchGroupsForUser(user.uid)
            .first
            .then((groups) => groups.firstWhere((item) => item.id == groupId));
      }
      if (!mounted) {
        return;
      }
      showSuccessSnackBar(
        _isEditing ? context.l10n.groupUpdated : context.l10n.groupCreated,
      );
      Navigator.of(context).pop(group);
    } on StateError catch (error) {
      if (error.message == 'group_limit_requires_pro') {
        if (!mounted) {
          return;
        }
        final opened = await PurchasesService.instance.presentPaywall(
          context: context,
        );
        if (!opened && mounted) {
          showErrorSnackBar(context.l10n.couldNotOpenPaywall);
        }
        return;
      }
      await showInternalDifficultiesSnackBar(error, StackTrace.current);
    } catch (error, stackTrace) {
      await showInternalDifficultiesSnackBar(error, stackTrace);
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
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

  Widget _buildAccessModeDropdown() {
    return DropdownButtonFormField<PollGroupAccessMode>(
      key: const Key('access_mode_dropdown'),
      initialValue: _accessMode,
      decoration: InputDecoration(
        labelText: context.l10n.groupAccess,
        border: const OutlineInputBorder(),
      ),
      items: PollGroupAccessMode.values
          .map(
            (mode) => DropdownMenuItem<PollGroupAccessMode>(
              value: mode,
              child: Text(mode.localizedTitle(context)),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) {
          return;
        }
        setState(() => _accessMode = value);
      },
    );
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
        labelText: context.l10n.email,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildMemberNicknameField(_InviteMemberDraft draft, int index) {
    return TextField(
      key: Key('member_nickname_$index'),
      controller: draft.nicknameController,
      decoration: InputDecoration(
        labelText: context.l10n.nickname,
        border: const OutlineInputBorder(),
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
              IconButton(
                key: Key('remove_member_row_$index'),
                onPressed: () => _removeMemberDraft(index),
                icon: const Icon(Icons.delete_outline),
                tooltip: context.l10n.removeMemberTooltip,
              ),
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
                  IconButton(
                    key: Key('remove_member_row_$index'),
                    onPressed: () => _removeMemberDraft(index),
                    icon: const Icon(Icons.delete_outline),
                    tooltip: context.l10n.removeMemberTooltip,
                  ),
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

  Widget _buildInviteMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              context.l10n.inviteMembersTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            TextButton.icon(
              key: const Key('add_member_row'),
              onPressed: _addMemberDraft,
              icon: const Icon(Icons.add),
              label: Text(context.l10n.addMember),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.inviteMembersDescription,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        ...List.generate(_memberDrafts.length, (index) {
          final draft = _memberDrafts[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildMemberDraftRow(draft, index),
          );
        }),
        const SizedBox(height: 8),
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

  Widget _buildDomainSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              context.l10n.allowedMailDomains,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            TextButton.icon(
              key: const Key('add_domain_row'),
              onPressed: _addDomainDraft,
              icon: const Icon(Icons.add_business),
              label: Text(context.l10n.addDomain),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.allowedMailDomainsDescription,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        if (_domainDrafts.isEmpty)
          Text(
            context.l10n.noDomainRulesYet,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ...List.generate(_domainDrafts.length, (index) {
          final draft = _domainDrafts[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    key: Key('domain_value_$index'),
                    controller: draft.domainController,
                    decoration: InputDecoration(
                      labelText: context.l10n.domainLabel,
                      hintText: context.l10n.domainHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _buildRoleDropdown(
                    key: Key('domain_role_$index'),
                    value: draft.role,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        draft.role = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  key: Key('remove_domain_row_$index'),
                  onPressed: () => _removeDomainDraft(index),
                  icon: const Icon(Icons.delete_outline),
                  tooltip: context.l10n.removeDomainTooltip,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? context.l10n.editGroupTitle
              : context.l10n.createGroupTitle,
        ),
      ),
      body: user == null
          ? Center(child: Text(context.l10n.pleaseSignInToManageGroups))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  _isEditing
                      ? context.l10n.editGroupDescription
                      : context.l10n.createGroupDescription,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: context.l10n.groupNameLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                _buildAccessModeDropdown(),
                const SizedBox(height: 8),
                Text(
                  _accessMode.localizedDescription(context),
                  key: const Key('access_mode_description'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _allowSelfNamedNicknames,
                  title: Text(context.l10n.membersCanChooseTheirOwnNickname),
                  onChanged: (value) {
                    setState(() => _allowSelfNamedNicknames = value);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _managersCanInvite,
                  title: Text(context.l10n.managersCanPrepareAccessLists),
                  onChanged: (value) {
                    setState(() => _managersCanInvite = value);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _hasExpiration,
                  title: Text(context.l10n.setExpirationDate),
                  onChanged: (value) {
                    setState(() {
                      _hasExpiration = value;
                      if (!value) {
                        _expiresAt = null;
                      }
                    });
                    if (value) {
                      _pickExpirationDate();
                    }
                  },
                ),
                if (_hasExpiration) ...[
                  OutlinedButton.icon(
                    onPressed: _pickExpirationDate,
                    icon: const Icon(Icons.event),
                    label: Text(
                      _expiresAt == null
                          ? context.l10n.pickExpirationDate
                          : context.l10n.expiresOnShort(
                              formatPollGroupDate(_expiresAt!),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_isLoadingExistingRules) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  _buildInviteMembersSection(),
                  const SizedBox(height: 24),
                  _buildDomainSection(),
                  const SizedBox(height: 24),
                ],
                FilledButton.icon(
                  key: const Key('save_group_button'),
                  onPressed: _isCreating || _isLoadingExistingRules
                      ? null
                      : _saveGroup,
                  icon: Icon(_isEditing ? Icons.save : Icons.group_add),
                  label: Text(
                    _isCreating
                        ? (_isEditing
                              ? context.l10n.savingGroup
                              : context.l10n.creatingGroup)
                        : (_isEditing
                              ? context.l10n.saveGroupLabel
                              : context.l10n.createGroupTitle),
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
  }) : emailController = TextEditingController(text: email),
       nicknameController = TextEditingController(text: nickname);

  final TextEditingController emailController;
  final TextEditingController nicknameController;
  PollGroupRole role;

  void dispose() {
    emailController.dispose();
    nicknameController.dispose();
  }
}

class _AllowedDomainDraft {
  _AllowedDomainDraft({String domain = '', this.role = PollGroupRole.user})
    : domainController = TextEditingController(text: domain);

  final TextEditingController domainController;
  PollGroupRole role;

  void dispose() {
    domainController.dispose();
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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'tsv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.single;
    if (file.bytes != null) {
      return utf8.decode(file.bytes!);
    }
    if (file.path != null && !kIsWeb) {
      return io.File(file.path!).readAsString();
    }
    return null;
  }
}
