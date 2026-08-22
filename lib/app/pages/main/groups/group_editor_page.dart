import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stimmapp/app/pages/main/groups/group_ui.dart';
import 'package:stimmapp/app/widgets/snackbar_utils.dart';
import 'package:trainvent_general/trainvent_general.dart';
import 'package:stimmapp/core/constants/app_limits.dart';
import 'package:stimmapp/core/data/models/poll_group.dart';
import 'package:stimmapp/core/data/repositories/poll_group_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/services/purchases_service.dart';

class GroupEditorPage extends StatefulWidget {
  const GroupEditorPage({
    super.key,
    this.initialGroup,
    this.repository,
    this.auth,
  });

  final PollGroup? initialGroup;
  final PollGroupRepository? repository;
  final AuthService? auth;

  @override
  State<GroupEditorPage> createState() => _GroupEditorPageState();
}

class _GroupEditorPageState extends State<GroupEditorPage> {
  final _nameController = TextEditingController();
  final List<_AllowedDomainDraft> _domainDrafts = [];
  List<PollGroupAllowedMember> _existingAllowedMembers = const [];
  bool _allowSelfNamedNicknames = true;
  DateTime? _expiresAt;
  bool _isCreating = false;
  PollGroupAccessMode _accessMode = PollGroupAccessMode.protected;
  bool _isLoadingExistingRules = false;

  bool get _isEditing => widget.initialGroup != null;

  PollGroupRepository get _repository =>
      widget.repository ?? PollGroupRepository.create();
  AuthService get _auth => widget.auth ?? authService;

  @override
  void initState() {
    super.initState();
    _seedForm();
  }

  @override
  void dispose() {
    _nameController.dispose();
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
    });
  }

  void _seedForm() {
    final initialGroup = widget.initialGroup;
    if (initialGroup == null) {
      return;
    }

    _nameController.text = initialGroup.name;
    _allowSelfNamedNicknames =
        initialGroup.nicknameMode == PollGroupNicknameMode.selfNamed;
    _expiresAt = initialGroup.expiresAt;
    _accessMode = initialGroup.accessMode;
    _loadExistingRules(initialGroup.id);
  }

  void _clearExpirationDate() {
    setState(() {
      _expiresAt = null;
    });
  }

  Future<void> _loadExistingRules(String groupId) async {
    setState(() => _isLoadingExistingRules = true);
    try {
      final allowedMembers = await _repository.getAllowedMembers(groupId);
      final allowedDomains = await _repository.getAllowedDomains(groupId);
      if (!mounted) {
        return;
      }
      for (final draft in _domainDrafts) {
        draft.dispose();
      }
      _existingAllowedMembers = allowedMembers;
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

  String _buildJoinCode() {
    final now = DateTime.now().millisecondsSinceEpoch
        .toRadixString(36)
        .toUpperCase();
    return 'GRP-${now.substring(now.length - 6)}';
  }

  bool get _inviteLinkEnabled =>
      _accessMode == PollGroupAccessMode.protected ||
      _accessMode == PollGroupAccessMode.open;

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
    if (groupName.length > AppLimits.maxGroupNameLength) {
      showErrorSnackBar(context.l10n.pleaseEnterGroupName);
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
          expiresAt: _expiresAt,
          nicknameMode: _allowSelfNamedNicknames
              ? PollGroupNicknameMode.selfNamed
              : PollGroupNicknameMode.adminAssigned,
          managersCanInvite: true,
          importedMemberCount: _existingAllowedMembers.length,
          accessMode: _accessMode,
          inviteLinkEnabled: _inviteLinkEnabled,
        );
        await _repository.updateGroup(
          group: group,
          allowedMembers: _existingAllowedMembers,
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
          managersCanInvite: true,
          accessMode: _accessMode,
          inviteLinkEnabled: _inviteLinkEnabled,
          expiresAt: _expiresAt,
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
        if (kDebugMode) {
          debugPrint(
            'GroupEditorPage._save: backend rejected group creation; '
            'opening paywall source=group_editor',
          );
        }
        final opened = await PurchasesService.instance.presentPaywall(
          context: context,
          source: 'group_editor',
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
            IconButton(
              key: const Key('add_domain_row'),
              onPressed: _addDomainDraft,
              icon: const Icon(Icons.add_business),
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
                    maxLength: AppLimits.maxDomainLength,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(
                        AppLimits.maxDomainLength,
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText: context.l10n.domainLabel,
                      hintText: context.l10n.domainHint,
                      border: const OutlineInputBorder(),
                      counterText: '',
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

  Widget _buildExpirationDateSection() {
    final hasExpiration = _expiresAt != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.setExpirationDate,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            hasExpiration
                ? context.l10n.expiresOnShort(formatPollGroupDate(_expiresAt!))
                : context.l10n.noExpirationDateSet,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickExpirationDate,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(
                    hasExpiration
                        ? formatPollGroupDate(_expiresAt!)
                        : context.l10n.pickExpirationDate,
                  ),
                ),
              ),
              if (hasExpiration) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _clearExpirationDate,
                  tooltip: context.l10n.remove,
                  icon: const Icon(Icons.cleaning_services_outlined),
                ),
              ],
            ],
          ),
        ],
      ),
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
                  maxLength: AppLimits.maxGroupNameLength,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(
                      AppLimits.maxGroupNameLength,
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: '${context.l10n.groupNameLabel} *',
                    border: const OutlineInputBorder(),
                    counterText: '',
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
                const SizedBox(height: 8),
                _buildExpirationDateSection(),
                if (_isLoadingExistingRules) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: TriangleLoadingIndicator(showFill: false),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
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

class _AllowedDomainDraft {
  _AllowedDomainDraft({String domain = '', this.role = PollGroupRole.user})
    : domainController = TextEditingController(text: domain);

  final TextEditingController domainController;
  PollGroupRole role;

  void dispose() {
    domainController.dispose();
  }
}
