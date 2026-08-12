import 'package:flag/flag.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stimmapp/app/widgets/snackbar_utils.dart';
import 'package:stimmapp/app/widgets/tag_selector.dart';
import 'package:stimmapp/app/widgets/teaching_lemm_image.dart';
import 'package:trainvent_general/trainvent_general.dart';
import 'package:stimmapp/core/constants/app_limits.dart';
import 'package:stimmapp/core/constants/country_union_memberships.dart';
import 'package:stimmapp/core/data/models/form_scope.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/generated/l10n.dart';

class BaseCreatorPage extends StatefulWidget {
  const BaseCreatorPage({
    super.key,
    required this.title,
    required this.tutorialSteps,
    required this.onSubmit,
    this.additionalTopFields,
    this.additionalMiddleFields,
    this.additionalBottomFields,
    this.profileLoader,
    this.additionalDraftClearer,
    this.onResetAdditionalFields,
  });

  final String title;
  final List<dynamic> tutorialSteps; // Can be String or PollTutorialStep
  final Future<void> Function({
    required String title,
    required String description,
    required List<String> tags,
    required FormScope scope,
    required int durationDays,
    required bool openUntilClosed,
  })
  onSubmit;
  final List<Widget>? additionalTopFields;
  final List<Widget>? additionalMiddleFields;
  final List<Widget>? additionalBottomFields;
  final Future<UserProfile?> Function()? profileLoader;
  final Future<void> Function()? additionalDraftClearer;
  final VoidCallback? onResetAdditionalFields;

  @override
  State<BaseCreatorPage> createState() => _BaseCreatorPageState();
}

class _BaseCreatorPageState extends State<BaseCreatorPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<String> _selectedTags = [];
  FormScopeType _selectedScope = FormScopeType.country;
  CountryUnion? _selectedCountryUnion;
  bool _supportsStateScope = false;
  String? _profileCountryCode;
  String? _profileStateOrRegion;
  String? _profileTown;
  bool _isLoading = false;
  int _durationDays = AppLimits.defaultFormDurationDays;
  bool _openUntilClosed = false;

  Set<CountryUnion> get _availableCountryUnions =>
      countryUnionsForCountry(_profileCountryCode);

  CountryUnion? get _firstAvailableCountryUnion =>
      _availableCountryUnions.isEmpty ? null : _availableCountryUnions.first;

  @override
  void initState() {
    super.initState();
    _loadStateScope();
    _loadDraft();
    _titleController.addListener(_saveDraft);
    _descriptionController.addListener(_saveDraft);
  }

  @override
  void dispose() {
    _titleController.removeListener(_saveDraft);
    _descriptionController.removeListener(_saveDraft);
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String get _draftKey => 'draft_${widget.title}';

  Future<void> _loadStateScope() async {
    final profileLoader = widget.profileLoader;
    final profile = profileLoader != null
        ? await profileLoader()
        : await _loadCurrentUserProfile();
    if (!mounted || profile == null) {
      return;
    }
    setState(() {
      _supportsStateScope = profile.supportsStateScope;
      _profileCountryCode =
          profile.countryCode?.toUpperCase() ??
          (profile.supportsStateScope ? 'DE' : null);
      final profileStateOrRegion = profile.state?.trim();
      _profileStateOrRegion =
          profileStateOrRegion == null || profileStateOrRegion.isEmpty
          ? null
          : profileStateOrRegion;
      final profileTown = profile.town?.trim();
      _profileTown = profileTown == null || profileTown.isEmpty
          ? null
          : profileTown;
      if (!_availableCountryUnions.contains(_selectedCountryUnion)) {
        _selectedCountryUnion = _firstAvailableCountryUnion;
      }
      if (_availableCountryUnions.isEmpty &&
          _selectedScope == FormScopeType.countryUnion) {
        _selectedScope = FormScopeType.country;
      }
      if (!_supportsStateScope &&
          _selectedScope == FormScopeType.stateOrRegion) {
        _selectedScope = FormScopeType.country;
      }
    });
    await _loadDraft();
  }

  Future<UserProfile?> _loadCurrentUserProfile() async {
    final uid = authService.currentUser?.uid;
    if (uid == null) return null;
    return UserRepository.create().getById(uid);
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draftTitle = prefs.getString('${_draftKey}_title');
    final draftDescription = prefs.getString('${_draftKey}_description');
    final draftTags = prefs.getStringList('${_draftKey}_tags');
    final draftScopeType = prefs.getString('${_draftKey}_scopeType');
    final draftScopeUnion = prefs.getString('${_draftKey}_scopeUnion');
    final draftStateDependent = prefs.getBool('${_draftKey}_stateDependent');
    final draftDuration = prefs.getInt('${_draftKey}_duration');
    final draftOpenUntilClosed = prefs.getBool('${_draftKey}_openUntilClosed');

    if (mounted) {
      setState(() {
        if (draftTitle != null) _titleController.text = draftTitle;
        if (draftDescription != null) {
          _descriptionController.text = draftDescription;
        }
        if (draftTags != null) _selectedTags = draftTags;
        if (draftScopeType != null && draftScopeType.isNotEmpty) {
          _selectedScope = parseFormScopeType(draftScopeType);
        } else if (draftStateDependent == true) {
          // Backward compatibility with old boolean draft key.
          _selectedScope = _supportsStateScope
              ? FormScopeType.stateOrRegion
              : FormScopeType.country;
        } else {
          _selectedScope = FormScopeType.country;
        }
        if (!_supportsStateScope &&
            _selectedScope == FormScopeType.stateOrRegion) {
          _selectedScope = FormScopeType.country;
        }
        _selectedCountryUnion = parseCountryUnion(draftScopeUnion);
        if (!_availableCountryUnions.contains(_selectedCountryUnion)) {
          _selectedCountryUnion = _firstAvailableCountryUnion;
        }
        if (_availableCountryUnions.isEmpty &&
            _selectedScope == FormScopeType.countryUnion) {
          _selectedScope = FormScopeType.country;
        }
        if (draftDuration != null) _durationDays = draftDuration;
        if (draftOpenUntilClosed != null) {
          _openUntilClosed = draftOpenUntilClosed;
        }
      });
    }
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_draftKey}_title', _titleController.text);
    await prefs.setString(
      '${_draftKey}_description',
      _descriptionController.text,
    );
    await prefs.setStringList('${_draftKey}_tags', _selectedTags);
    await prefs.setString(
      '${_draftKey}_scopeType',
      formScopeTypeToFirestore(_selectedScope),
    );
    final selectedCountryUnion = _selectedCountryUnion;
    if (selectedCountryUnion == null) {
      await prefs.remove('${_draftKey}_scopeUnion');
    } else {
      await prefs.setString(
        '${_draftKey}_scopeUnion',
        selectedCountryUnion.code,
      );
    }
    // City scope now always uses the town stored in the user's profile.
    // Remove previously saved free-text values so they cannot override it.
    await prefs.remove('${_draftKey}_scopeTown');
    await prefs.remove('${_draftKey}_scopeCity');
    await prefs.remove('${_draftKey}_stateDependent');
    await prefs.setInt('${_draftKey}_duration', _durationDays);
    await prefs.setBool('${_draftKey}_openUntilClosed', _openUntilClosed);
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_draftKey}_title');
    await prefs.remove('${_draftKey}_description');
    await prefs.remove('${_draftKey}_tags');
    await prefs.remove('${_draftKey}_scopeType');
    await prefs.remove('${_draftKey}_scopeUnion');
    await prefs.remove('${_draftKey}_scopeTown');
    await prefs.remove('${_draftKey}_scopeCity');
    await prefs.remove('${_draftKey}_stateDependent');
    await prefs.remove('${_draftKey}_duration');
    await prefs.remove('${_draftKey}_openUntilClosed');
    await widget.additionalDraftClearer?.call();
  }

  Future<void> _resetForm() async {
    await _clearDraft();
    setState(() {
      _titleController.clear();
      _descriptionController.clear();
      _selectedTags = [];
      _selectedScope = FormScopeType.country;
      _selectedCountryUnion = _firstAvailableCountryUnion;
      _durationDays = AppLimits.defaultFormDurationDays;
      _openUntilClosed = false;
    });
    widget.onResetAdditionalFields?.call();
  }

  Future<void> _handleSubmit() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTags.isEmpty) {
      showErrorSnackBar(context.l10n.tagsRequired);
      return;
    }

    final currentUser = authService.currentUser;
    if (currentUser == null) {
      showErrorSnackBar(context.l10n.pleaseSignInFirst);
      return;
    }
    if (_selectedScope == FormScopeType.stateOrRegion &&
        (!_supportsStateScope || _profileStateOrRegion == null)) {
      showErrorSnackBar(context.l10n.pleaseSelectState);
      return;
    }
    if (_selectedScope == FormScopeType.city && _profileTown == null) {
      showErrorSnackBar(context.l10n.pleaseSetTownInAddressFirst);
      return;
    }
    if (_selectedScope == FormScopeType.countryUnion &&
        !_availableCountryUnions.contains(_selectedCountryUnion)) {
      showErrorSnackBar(context.l10n.countryUnionScopeOnlyForMembers);
      return;
    }
    if (_selectedScope != FormScopeType.global &&
        (_profileCountryCode == null || _profileCountryCode!.isEmpty)) {
      showErrorSnackBar(context.l10n.pleaseSetCountryInAddressFirst);
      return;
    }
    final scope = _buildSelectedScope();

    setState(() => _isLoading = true);

    try {
      await widget.onSubmit(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        tags: _selectedTags,
        scope: scope,
        durationDays: _durationDays,
        openUntilClosed: _openUntilClosed,
      );
      await _clearDraft(); // Clear draft on successful submission
    } catch (e) {
      // Error handling is mostly done in the callback, but catch here just in case
      if (mounted) showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  FormScope _buildSelectedScope() {
    switch (_selectedScope) {
      case FormScopeType.global:
        return const FormScope.global();
      case FormScopeType.countryUnion:
        return FormScope.countryUnion(_selectedCountryUnion!);
      case FormScopeType.continent:
        return const FormScope.global();
      case FormScopeType.country:
        return FormScope.country(_profileCountryCode!);
      case FormScopeType.stateOrRegion:
        return FormScope.stateOrRegion(
          countryCode: _profileCountryCode!,
          stateOrRegion: _profileStateOrRegion!,
        );
      case FormScopeType.city:
        return FormScope.city(
          countryCode: _profileCountryCode!,
          stateOrRegion: _profileStateOrRegion,
          town: _profileTown!,
        );
    }
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Stack(
          children: [
            AlertDialog(
              title: Text(widget.title), // Use page title as dialog title
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.tutorialSteps.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final step = widget.tutorialSteps[index];
                          if (step is String) {
                            // Petition style (simple bullets)
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '• ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Expanded(
                                  child: Text(
                                    step,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            );
                          } else {
                            // Poll style (Title + Description object)
                            // Assuming dynamic access or we define a common interface/type
                            // For now, let's assume it has title and description properties
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    step.title,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    step.description,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(context.l10n.close),
                ),
              ],
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: IgnorePointer(child: const TeachingLemmImage()),
            ),
          ],
        );
      },
    );
  }

  String _scopeLabel(FormScopeType scope) {
    switch (scope) {
      case FormScopeType.global:
        return context.l10n.scopeGlobal;
      case FormScopeType.countryUnion:
        return context.l10n.scopeCountryUnion;
      case FormScopeType.continent:
        return context.l10n.scopeContinent;
      case FormScopeType.country:
        return context.l10n.scopeCountry;
      case FormScopeType.stateOrRegion:
        return context.l10n.scopeStateRegion;
      case FormScopeType.city:
        return context.l10n.scopeCity;
    }
  }

  List<FormScopeType> get _availableScopes => <FormScopeType>[
    FormScopeType.global,
    if (_availableCountryUnions.isNotEmpty) FormScopeType.countryUnion,
    FormScopeType.country,
    if (_supportsStateScope) FormScopeType.stateOrRegion,
    FormScopeType.city,
  ];

  Widget _scopeLeading(FormScopeType scope, {bool showResolvedValue = false}) {
    switch (scope) {
      case FormScopeType.global:
        return const Icon(Icons.language);
      case FormScopeType.countryUnion:
        return const Icon(Icons.hub_outlined);
      case FormScopeType.continent:
        return const Icon(Icons.public);
      case FormScopeType.country:
        final countryCode = _profileCountryCode;
        if (showResolvedValue &&
            countryCode != null &&
            Flag.flagsCode.contains(countryCode.toLowerCase())) {
          return Semantics(
            label: '${context.l10n.scopeCountry}: $countryCode',
            child: ExcludeSemantics(
              child: Flag.fromString(
                countryCode,
                width: 40,
                height: 28,
                borderRadius: 2,
              ),
            ),
          );
        }
        return const Icon(Icons.flag_outlined);
      case FormScopeType.stateOrRegion:
        return const Icon(Icons.map_outlined);
      case FormScopeType.city:
        return const Icon(Icons.location_city_outlined);
    }
  }

  String? _scopeValue(FormScopeType scope) {
    switch (scope) {
      case FormScopeType.global:
      case FormScopeType.continent:
        return null;
      case FormScopeType.countryUnion:
        return null;
      case FormScopeType.country:
        return _profileCountryCode;
      case FormScopeType.stateOrRegion:
        return _profileStateOrRegion;
      case FormScopeType.city:
        return _profileTown;
    }
  }

  String? _scopeMissingMessage(FormScopeType scope) {
    switch (scope) {
      case FormScopeType.global:
      case FormScopeType.countryUnion:
      case FormScopeType.continent:
        return null;
      case FormScopeType.country:
        return context.l10n.pleaseSetCountryInAddressFirst;
      case FormScopeType.stateOrRegion:
        return context.l10n.pleaseSelectState;
      case FormScopeType.city:
        return context.l10n.pleaseSetTownInAddressFirst;
    }
  }

  Widget _scopeLocationCard({
    required Widget leading,
    required String title,
    required String? value,
    required String? missingMessage,
    Widget? trailing,
  }) {
    final hasValue = value != null && value.isNotEmpty;
    final isMissing = !hasValue && missingMessage != null;
    final color = isMissing ? Theme.of(context).colorScheme.error : null;

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: leading,
        title: Text(title),
        subtitle: hasValue
            ? Text(value)
            : missingMessage == null
            ? null
            : Text(missingMessage),
        trailing: trailing,
        textColor: color,
        iconColor: color,
      ),
    );
  }

  Widget _scopeSelectorCard() {
    return PopupMenuButton<FormScopeType>(
      key: const Key('scopeSelectorCard'),
      initialValue: _selectedScope,
      tooltip: context.l10n.scope,
      onOpened: () => FocusManager.instance.primaryFocus?.unfocus(),
      onSelected: (value) {
        setState(() {
          _selectedScope = value;
          if (value == FormScopeType.countryUnion &&
              !_availableCountryUnions.contains(_selectedCountryUnion)) {
            _selectedCountryUnion = _firstAvailableCountryUnion;
          }
        });
        _saveDraft();
      },
      itemBuilder: (context) => _availableScopes
          .map(
            (scope) => PopupMenuItem<FormScopeType>(
              value: scope,
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Center(child: _scopeLeading(scope)),
                  ),
                  const SizedBox(width: 12),
                  Text(_scopeLabel(scope)),
                ],
              ),
            ),
          )
          .toList(),
      child: _scopeLocationCard(
        leading: _scopeLeading(_selectedScope, showResolvedValue: true),
        title: _scopeLabel(_selectedScope),
        value: _scopeValue(_selectedScope),
        missingMessage: _scopeMissingMessage(_selectedScope),
        trailing: const Icon(Icons.arrow_drop_down),
      ),
    );
  }

  String _countryUnionLabel(CountryUnion union) => switch (union) {
    CountryUnion.eu => context.l10n.scopeEu,
    CountryUnion.un => context.l10n.scopeUn,
  };

  FlagsCode _countryUnionFlag(CountryUnion union) => switch (union) {
    CountryUnion.eu => FlagsCode.EU,
    CountryUnion.un => FlagsCode.UN,
  };

  Widget _countryUnionSelectorCard() {
    final selected = _selectedCountryUnion;
    return PopupMenuButton<CountryUnion>(
      key: const Key('countryUnionSelectorCard'),
      initialValue: selected,
      tooltip: context.l10n.selectCountryUnion,
      onSelected: (value) {
        setState(() => _selectedCountryUnion = value);
        _saveDraft();
      },
      itemBuilder: (context) => [
        for (final union in CountryUnion.values)
          if (_availableCountryUnions.contains(union))
            PopupMenuItem<CountryUnion>(
              value: union,
              child: Row(
                children: [
                  Flag.fromCode(
                    _countryUnionFlag(union),
                    width: 32,
                    height: 22,
                    borderRadius: 2,
                  ),
                  const SizedBox(width: 12),
                  Text(_countryUnionLabel(union)),
                ],
              ),
            ),
      ],
      child: _scopeLocationCard(
        leading: selected == null
            ? const Icon(Icons.hub_outlined)
            : Flag.fromCode(
                _countryUnionFlag(selected),
                width: 40,
                height: 28,
                borderRadius: 2,
              ),
        title: context.l10n.selectCountryUnion,
        value: selected == null ? null : _countryUnionLabel(selected),
        missingMessage: selected == null
            ? context.l10n.countryUnionScopeOnlyForMembers
            : null,
        trailing: const Icon(Icons.arrow_drop_down),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(context.l10n.delete),
                  content: Text(
                    S.of(context).areYouSureYouWantToClearThisDraft,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(context.l10n.cancel),
                    ),
                    FilledButton(
                      onPressed: () {
                        _resetForm();
                        Navigator.pop(context);
                      },
                      child: Text(context.l10n.confirm),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 30),
              if (widget.additionalTopFields != null)
                ...widget.additionalTopFields!,
              TextFormField(
                controller: _titleController,
                maxLength: AppLimits.maxTitleLength,
                autovalidateMode: AutovalidateMode.onUnfocus,
                decoration: InputDecoration(
                  labelText: context.l10n.title,
                  hintText: context.l10n.enterTitle,
                  helperText: context.l10n.minimumCharacterCount(
                    AppLimits.minTitleLength,
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.l10n.titleRequired;
                  }
                  if (value.trim().length < AppLimits.minTitleLength) {
                    return context.l10n.minimumCharacterCount(
                      AppLimits.minTitleLength,
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                maxLength: AppLimits.maxDescriptionLength,
                autovalidateMode: AutovalidateMode.onUnfocus,
                decoration: InputDecoration(
                  labelText: context.l10n.description,
                  hintText: context.l10n.enterDescription,
                  helperText: context.l10n.minimumCharacterCount(
                    AppLimits.minDescriptionLength,
                  ),
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 8,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.l10n.descriptionRequired;
                  }
                  if (value.trim().length < AppLimits.minDescriptionLength) {
                    return context.l10n.minimumCharacterCount(
                      AppLimits.minDescriptionLength,
                    );
                  }
                  return null;
                },
              ),
              if (widget.additionalMiddleFields != null)
                ...widget.additionalMiddleFields!,
              const SizedBox(height: 20),
              Text(
                context.l10n.tags,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TagSelector(
                selectedTags: _selectedTags,
                onChanged: (newTags) {
                  setState(() {
                    _selectedTags = newTags;
                  });
                  _saveDraft();
                },
              ),
              const SizedBox(height: 20),
              Text(
                context.l10n.duration,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Row(
                children: [
                  Expanded(
                    child: SliderTheme(
                      key: const Key('durationSliderTheme'),
                      data: SliderTheme.of(context).copyWith(
                        thumbShape: _openUntilClosed
                            ? SliderComponentShape.noThumb
                            : SliderTheme.of(context).thumbShape,
                        overlayShape: _openUntilClosed
                            ? SliderComponentShape.noOverlay
                            : SliderTheme.of(context).overlayShape,
                        activeTrackColor: _openUntilClosed
                            ? Theme.of(context).colorScheme.outlineVariant
                            : null,
                        inactiveTrackColor: _openUntilClosed
                            ? Theme.of(context).colorScheme.outlineVariant
                            : null,
                      ),
                      child: Slider(
                        key: const Key('durationSlider'),
                        value: _durationDays.toDouble(),
                        min: 1,
                        max: AppLimits.defaultFormDurationDays.toDouble(),
                        divisions: AppLimits.defaultFormDurationDays - 1,
                        label: context.l10n.durationDays(_durationDays),
                        onChanged: (double value) {
                          setState(() {
                            _openUntilClosed = false;
                            _durationDays = value.round();
                          });
                          _saveDraft();
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('openUntilClosedButton'),
                    tooltip: context.l10n.openUntilClosedDescription,
                    style: IconButton.styleFrom(
                      backgroundColor: _openUntilClosed
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      foregroundColor: _openUntilClosed
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () {
                      setState(() => _openUntilClosed = true);
                      _saveDraft();
                    },
                    icon: const Icon(Icons.all_inclusive),
                  ),
                ],
              ),
              Row(
                children: [
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [Text('1'), Text('42')],
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Container(
                    key: ValueKey(_openUntilClosed),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _openUntilClosed
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.all_inclusive, size: 20),
                              const SizedBox(width: 7),
                              Text(context.l10n.openUntilClosed),
                            ],
                          )
                        : Text(context.l10n.durationDays(_durationDays)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _scopeSelectorCard(),
              if (_selectedScope == FormScopeType.countryUnion) ...[
                const SizedBox(height: 10),
                _countryUnionSelectorCard(),
              ],
              const SizedBox(height: 10),
              if (widget.additionalBottomFields != null)
                ...widget.additionalBottomFields!,
              Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? TriangleLoadingIndicator(
                            size: 20,
                            showFill: false,
                            strokeColor: Theme.of(
                              context,
                            ).colorScheme.onPrimary,
                          )
                        : Text(
                            widget.title,
                            style: const TextStyle(fontSize: 16),
                          ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
