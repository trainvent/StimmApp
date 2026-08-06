import 'package:flag/flag.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stimmapp/app/widgets/snackbar_utils.dart';
import 'package:stimmapp/app/widgets/tag_selector.dart';
import 'package:stimmapp/app/widgets/teaching_lemm_image.dart';
import 'package:trainvent_general/trainvent_general.dart';
import 'package:stimmapp/core/constants/app_limits.dart';
import 'package:stimmapp/core/constants/eu_country_codes.dart';
import 'package:stimmapp/core/data/models/form_scope.dart';
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
  });

  final String title;
  final List<dynamic> tutorialSteps; // Can be String or PollTutorialStep
  final Future<void> Function({
    required String title,
    required String description,
    required List<String> tags,
    required String scopeType,
    String? scopeContinentCode,
    String? scopeCountryCode,
    String? scopeStateOrRegion,
    String? scopeTown,
    required int durationDays,
  })
  onSubmit;
  final List<Widget>? additionalTopFields;
  final List<Widget>? additionalMiddleFields;
  final List<Widget>? additionalBottomFields;

  @override
  State<BaseCreatorPage> createState() => _BaseCreatorPageState();
}

class _BaseCreatorPageState extends State<BaseCreatorPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<String> _selectedTags = [];
  FormScopeType _selectedScope = FormScopeType.country;
  bool _supportsStateScope = false;
  String? _profileCountryCode;
  String? _profileStateOrRegion;
  String? _profileTown;
  bool _isLoading = false;
  int _durationDays = 28; // Default duration

  bool get _supportsEuScope => isEuCountryCode(_profileCountryCode);

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
    final uid = authService.currentUser?.uid;
    if (uid == null) {
      return;
    }
    final profile = await UserRepository.create().getById(uid);
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
      if (!_supportsEuScope && _selectedScope == FormScopeType.eu) {
        _selectedScope = FormScopeType.country;
      }
      if (!_supportsStateScope &&
          _selectedScope == FormScopeType.stateOrRegion) {
        _selectedScope = FormScopeType.country;
      }
    });
    await _loadDraft();
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draftTitle = prefs.getString('${_draftKey}_title');
    final draftDescription = prefs.getString('${_draftKey}_description');
    final draftTags = prefs.getStringList('${_draftKey}_tags');
    final draftScopeType = prefs.getString('${_draftKey}_scopeType');
    final draftStateDependent = prefs.getBool('${_draftKey}_stateDependent');
    final draftDuration = prefs.getInt('${_draftKey}_duration');

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
        if (!_supportsEuScope && _selectedScope == FormScopeType.eu) {
          _selectedScope = FormScopeType.country;
        }
        if (draftDuration != null) _durationDays = draftDuration;
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
    // City scope now always uses the town stored in the user's profile.
    // Remove previously saved free-text values so they cannot override it.
    await prefs.remove('${_draftKey}_scopeTown');
    await prefs.remove('${_draftKey}_scopeCity');
    await prefs.remove('${_draftKey}_stateDependent');
    await prefs.setInt('${_draftKey}_duration', _durationDays);
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_draftKey}_title');
    await prefs.remove('${_draftKey}_description');
    await prefs.remove('${_draftKey}_tags');
    await prefs.remove('${_draftKey}_scopeType');
    await prefs.remove('${_draftKey}_scopeTown');
    await prefs.remove('${_draftKey}_scopeCity');
    await prefs.remove('${_draftKey}_stateDependent');
    await prefs.remove('${_draftKey}_duration');
  }

  Future<void> _resetForm() async {
    await _clearDraft();
    setState(() {
      _titleController.clear();
      _descriptionController.clear();
      _selectedTags = [];
      _selectedScope = FormScopeType.country;
      _durationDays = 28;
    });
  }

  Future<void> _handleSubmit() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_formKey.currentState!.validate()) {
      showErrorSnackBar(context.l10n.error);
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
    if (_selectedScope == FormScopeType.eu && !_supportsEuScope) {
      showErrorSnackBar(context.l10n.euScopeOnlyForEuCountries);
      return;
    }
    if (_selectedScope != FormScopeType.global &&
        (_profileCountryCode == null || _profileCountryCode!.isEmpty)) {
      showErrorSnackBar(context.l10n.pleaseSetCountryInAddressFirst);
      return;
    }
    final scopeType = formScopeTypeToFirestore(_selectedScope);
    String? scopeContinentCode;
    String? scopeCountryCode;
    String? scopeStateOrRegion;
    String? scopeTown;
    switch (_selectedScope) {
      case FormScopeType.global:
        break;
      case FormScopeType.eu:
        scopeContinentCode = 'EU';
        break;
      case FormScopeType.continent:
        break;
      case FormScopeType.country:
        scopeCountryCode = _profileCountryCode;
        break;
      case FormScopeType.stateOrRegion:
        scopeCountryCode = _profileCountryCode;
        scopeStateOrRegion = _profileStateOrRegion;
        break;
      case FormScopeType.city:
        scopeCountryCode = _profileCountryCode;
        scopeStateOrRegion = _profileStateOrRegion;
        scopeTown = _profileTown;
        break;
    }

    setState(() => _isLoading = true);

    try {
      await widget.onSubmit(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        tags: _selectedTags,
        scopeType: scopeType,
        scopeContinentCode: scopeContinentCode,
        scopeCountryCode: scopeCountryCode,
        scopeStateOrRegion: scopeStateOrRegion,
        scopeTown: scopeTown,
        durationDays: _durationDays,
      );
      await _clearDraft(); // Clear draft on successful submission
    } catch (e) {
      // Error handling is mostly done in the callback, but catch here just in case
      if (mounted) showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      case FormScopeType.eu:
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
    if (_supportsEuScope) FormScopeType.eu,
    FormScopeType.country,
    if (_supportsStateScope) FormScopeType.stateOrRegion,
    FormScopeType.city,
  ];

  Widget _scopeLeading(FormScopeType scope, {bool showResolvedValue = false}) {
    switch (scope) {
      case FormScopeType.global:
        return const Icon(Icons.language);
      case FormScopeType.eu:
        if (!showResolvedValue) {
          return const Icon(Icons.hub_outlined);
        }
        return Semantics(
          label: context.l10n.scopeEu,
          child: ExcludeSemantics(
            child: Flag.fromCode(
              FlagsCode.EU,
              width: 40,
              height: 28,
              borderRadius: 2,
            ),
          ),
        );
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
      case FormScopeType.eu:
        return context.l10n.scopeEu;
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
      case FormScopeType.eu:
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
        setState(() => _selectedScope = value);
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
                decoration: InputDecoration(
                  labelText: context.l10n.title,
                  hintText: context.l10n.enterTitle,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.l10n.titleRequired;
                  }
                  if (value.trim().length < AppLimits.minTitleLength) {
                    return context.l10n.titleTooShort;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                maxLength: AppLimits.maxDescriptionLength,
                decoration: InputDecoration(
                  labelText: context.l10n.description,
                  hintText: context.l10n.enterDescription,
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 8,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.l10n.descriptionRequired;
                  }
                  if (value.trim().length < AppLimits.minDescriptionLength) {
                    return context.l10n.descriptionTooShort;
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
                context.l10n.daysLeft,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Slider(
                value: _durationDays.toDouble(),
                min: 1,
                max: 42, // 6 weeks
                divisions: 41,
                label: '$_durationDays days',
                onChanged: (double value) {
                  setState(() {
                    _durationDays = value.toInt();
                  });
                  _saveDraft();
                },
              ),
              Center(child: Text('$_durationDays days')),
              const SizedBox(height: 10),
              _scopeSelectorCard(),
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
