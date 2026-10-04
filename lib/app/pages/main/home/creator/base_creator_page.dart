import 'package:stimmapp/core/data/services/pdf_form_import.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:stimmapp/core/data/models/form_import.dart';
import 'package:flag/flag.dart';
import 'package:stimmapp/core/data/models/poll_template.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stimmapp/app/widgets/info_dialog_button.dart';
import 'package:stimmapp/app/widgets/snackbar_utils.dart';
import 'package:stimmapp/app/widgets/tag_selector.dart';
import 'package:trainvent_general/trainvent_general.dart';
import 'package:stimmapp/core/constants/app_limits.dart';
import 'package:stimmapp/core/constants/app_tags_helper.dart';
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
    this.contentActionsBuilder,
    this.appBarActionBuilder,
    this.additionalMiddleFields,
    this.additionalBottomFields,
    this.profileLoader,
    this.additionalDraftClearer,
    this.onResetAdditionalFields,
    this.previewContentBuilder,
    this.importType,
    this.onImportQuestions,
  });

  final String? importType;
  final Future<void> Function(List<PollTemplateQuestion>)? onImportQuestions;
  final String title;
  final List<dynamic> tutorialSteps; // Can be String or PollTutorialStep
  final Future<bool> Function({
    required String title,
    required String description,
    required List<String> tags,
    required FormScope scope,
    required int durationDays,
    required bool openUntilClosed,
  })
  onSubmit;
  final List<Widget>? additionalTopFields;
  final Widget Function(
    TextEditingController title,
    TextEditingController description,
  )?
  contentActionsBuilder;
  final Widget Function(
    TextEditingController title,
    TextEditingController description,
  )?
  appBarActionBuilder;
  final List<Widget>? additionalMiddleFields;
  final List<Widget>? additionalBottomFields;
  final Future<UserProfile?> Function()? profileLoader;
  final Future<void> Function()? additionalDraftClearer;
  final VoidCallback? onResetAdditionalFields;
  final WidgetBuilder? previewContentBuilder;

  @override
  State<BaseCreatorPage> createState() => BaseCreatorPageState();
}

class BaseCreatorPageState extends State<BaseCreatorPage> {
  final _formKey = GlobalKey<FormState>();
  String? _openScopePicker;
  final _scopeAnchorKey = GlobalKey();
  final _unionAnchorKey = GlobalKey();
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
  bool _isReviewing = false;
  int _durationDays = AppLimits.defaultFormDurationDays;
  bool _openUntilClosed = false;

  /// A snapshot of settings for the template save dialog.
  PollTemplate get templateSettings => PollTemplate(
    id: '',
    name: '',
    tags: List.of(_selectedTags),
    scopeType: _selectedScope.name,
    countryUnion: _selectedCountryUnion?.code,
    durationDays: _durationDays,
    openUntilClosed: _openUntilClosed,
  );

  /// Refuse unavailable scope settings instead of silently broadening an audience.
  Future<bool> applyTemplate(PollTemplate template) async {
    final scope = template.scopeType == null
        ? null
        : parseFormScopeType(template.scopeType);
    final union = parseCountryUnion(template.countryUnion);
    if ((scope == FormScopeType.stateOrRegion && !_supportsStateScope) ||
        (scope == FormScopeType.countryUnion &&
            !_availableCountryUnions.contains(union))) {
      showErrorSnackBar(context.l10n.pollTemplateScopeUnavailable);
      return false;
    }
    setState(() {
      if (template.title != null) _titleController.text = template.title!;
      if (template.description != null) {
        _descriptionController.text = template.description!;
      }
      if (template.tags != null) _selectedTags = List.of(template.tags!);
      if (scope != null) {
        _selectedScope = scope;
        _selectedCountryUnion = union;
      }
      if (template.durationDays != null) _durationDays = template.durationDays!;
      if (template.openUntilClosed != null) {
        _openUntilClosed = template.openUntilClosed!;
      }
    });
    await _saveDraft();
    return true;
  }

  bool _isImporting = false;

  Future<void> _chooseImport() async {
    final pdf = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: Text(context.l10n.importFormPdf),
              onTap: () => Navigator.pop(context, true),
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: Text(context.l10n.importFormJson),
              onTap: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );
    if (!mounted || pdf == null) return;
    if (pdf) {
      await _importPdf();
    } else {
      await _importJson();
    }
  }

  Future<void> _importPdf() async {
    if (_isImporting) return;
    setState(() => _isImporting = true);
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (!mounted || file == null) return;
      if ((await file.length() ?? 0) > PdfFormImport.maxBytes) {
        throw const FormatException('size');
      }
      final text = await PdfFormImport.extract(await file.readAsBytes());
      if (!mounted) return;
      final controller = TextEditingController(text: text);
      PollTemplate? template;
      try {
        final route = DialogRoute<PollTemplate>(
          context: context,
          builder: (context) {
            String? error;
            return StatefulBuilder(
              builder: (context, update) => AlertDialog(
                title: Text(context.l10n.importFormPdf),
                content: SizedBox(
                  width: 600,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(context.l10n.importPdfHelp),
                        const SizedBox(height: 16),
                        TextField(
                          controller: controller,
                          minLines: 8,
                          maxLines: 16,
                          decoration: InputDecoration(
                            errorText: error,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(context.l10n.importFormConfirmation),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(context.l10n.cancel),
                  ),
                  FilledButton(
                    onPressed: () {
                      try {
                        final result = PdfFormImport.parse(
                          controller.text,
                          type: widget.importType!,
                        );
                        Navigator.pop(context, result);
                      } on FormatException {
                        update(() => error = context.l10n.importPdfInvalid);
                      }
                    },
                    child: Text(context.l10n.confirm),
                  ),
                ],
              ),
            );
          },
        );
        template = await Navigator.of(context).push(route);
        await route.completed;
      } finally {
        controller.dispose();
      }
      if (!mounted || template == null) return;
      if (!await applyTemplate(template) || !mounted) return;
      if (template.questions != null) {
        await widget.onImportQuestions!(template.questions!);
      }
      if (mounted) showSuccessSnackBar(context.l10n.importFormSuccess);
    } on FormatException catch (error) {
      if (mounted) {
        showErrorSnackBar(
          error.message == 'empty'
              ? context.l10n.importPdfNoText
              : error.message == 'size'
              ? context.l10n.importPdfTooLarge
              : context.l10n.importFormError,
        );
      }
    } catch (_) {
      if (mounted) showErrorSnackBar(context.l10n.importFormError);
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _importJson() async {
    if (_isImporting) return;
    setState(() => _isImporting = true);
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (!mounted || file == null) return;
      if ((await file.length() ?? 0) > FormImport.maxBytes) {
        throw const FormatException('file');
      }
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      final template = FormImport.parse(
        utf8.decode(bytes),
        expectedType: widget.importType!,
        allowedTags: AppTagsHelper.getTags(context).keys.toSet(),
      );
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.importFormJson),
          content: Text(
            '${template.title}\n\n${context.l10n.importFormConfirmation}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.confirm),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
      if (!await applyTemplate(template) || !mounted) return;
      if (template.questions != null) {
        await widget.onImportQuestions!(template.questions!);
      }
      if (mounted) showSuccessSnackBar(context.l10n.importFormSuccess);
    } on FormatException catch (error) {
      if (mounted) {
        showErrorSnackBar(
          '${context.l10n.importFormInvalid} (${error.message})',
        );
      }
    } catch (_) {
      if (mounted) showErrorSnackBar(context.l10n.importFormError);
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

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

  Future<void> _selectTags() async {
    FocusManager.instance.primaryFocus?.unfocus();
    var pendingTags = List<String>.of(_selectedTags);
    final selectedTags = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(context.l10n.tags),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: TagSelector(
                selectedTags: pendingTags,
                onChanged: (tags) => setDialogState(() => pendingTags = tags),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(pendingTags),
              child: Text(context.l10n.confirm),
            ),
          ],
        ),
      ),
    );
    if (!mounted || selectedTags == null) return;
    setState(() => _selectedTags = selectedTags);
    await _saveDraft();
  }

  String get _scopeSummary => [
    _scopeLabel(_selectedScope),
    if (_selectedScope == FormScopeType.countryUnion &&
        _selectedCountryUnion != null)
      _countryUnionLabel(_selectedCountryUnion!)
    else if (_scopeValue(_selectedScope) != null)
      _scopeValue(_selectedScope)!,
  ].join(' · ');

  Future<bool> _reviewPublication() async {
    setState(() => _isReviewing = true);
    final confirmed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(context.l10n.reviewPublication)),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                _titleController.text.trim(),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(_descriptionController.text.trim()),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final tag in _selectedTags)
                    Chip(
                      label: Text(AppTagsHelper.getLocalizedTag(context, tag)),
                    ),
                ],
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: Text(context.l10n.duration),
                subtitle: Text(
                  _openUntilClosed
                      ? context.l10n.openUntilClosed
                      : context.l10n.durationDays(_durationDays),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _scopeLeading(_selectedScope),
                title: Text(context.l10n.geographicalScope),
                subtitle: Text(_scopeSummary),
              ),
              if (widget.previewContentBuilder != null)
                widget.previewContentBuilder!(context),
            ],
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.all(16),
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 12,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(context.l10n.backToEditing),
                ),
                FilledButton.icon(
                  key: const Key('confirm_publication'),
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.publish),
                  label: Text(context.l10n.publishNow),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted) return false;
    setState(() => _isReviewing = false);
    return confirmed == true;
  }

  Future<void> _handleSubmit() async {
    if (_isLoading || _isReviewing) return;
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTags.isEmpty) {
      showErrorSnackBar(context.l10n.tagsRequired);
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
    if (!await _reviewPublication() || !mounted) return;

    setState(() => _isLoading = true);

    try {
      final published = await widget.onSubmit(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        tags: _selectedTags,
        scope: scope,
        durationDays: _durationDays,
        openUntilClosed: _openUntilClosed,
      );
      if (published) await _clearDraft();
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

  Widget _buildTutorialContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < widget.tutorialSteps.length; index++) ...[
          if (index > 0) const SizedBox(height: 8),
          if (widget.tutorialSteps[index] is String)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(
                    widget.tutorialSteps[index] as String,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.tutorialSteps[index].title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.tutorialSteps[index].description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: 16),
      ],
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
    Key? key,
    required Widget leading,
    required String title,
    required String? value,
    required String? missingMessage,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final hasValue = value != null && value.isNotEmpty;
    final isMissing = !hasValue && missingMessage != null;
    final color = isMissing ? Theme.of(context).colorScheme.error : null;

    return Card(
      key: key,
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
        onTap: onTap,
        textColor: color,
        iconColor: color,
      ),
    );
  }

  Future<void> _showScopePicker<T>({
    required String id,
    required GlobalKey anchorKey,
    required String title,
    required List<T> options,
    required T? selected,
    required String Function(T) label,
    required Widget Function(T) leading,
    required ValueChanged<T> onSelected,
  }) async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _openScopePicker = id);
    final overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final menuWidth = (overlay.size.width - 32).clamp(0.0, 320.0);
    final value = await showMenu<T>(
      context: context,
      semanticLabel: title,
      constraints: BoxConstraints.tightFor(width: menuWidth),
      positionBuilder: (context, constraints) {
        final anchor =
            anchorKey.currentContext!.findRenderObject() as RenderBox;
        final rect =
            anchor.localToGlobal(Offset.zero, ancestor: overlay) & anchor.size;
        final menuHeight = options.length * 56.0 + 16;
        final safePadding = MediaQuery.paddingOf(context);
        final spaceBelow =
            overlay.size.height - safePadding.bottom - rect.bottom - 8;
        final spaceAbove = rect.top - safePadding.top - 8;
        final top = spaceBelow < menuHeight && spaceAbove > spaceBelow
            ? rect.top - menuHeight - 4
            : rect.bottom + 4;
        return RelativeRect.fromRect(
          Rect.fromLTWH(rect.center.dx - menuWidth / 2, top, menuWidth, 0),
          Offset.zero & overlay.size,
        );
      },
      items: [
        for (final option in options)
          PopupMenuItem<T>(
            value: option,
            height: 56,
            child: IconTheme.merge(
              data: IconThemeData(
                color:
                    Theme.of(context).popupMenuTheme.textStyle?.color ??
                    Theme.of(context).colorScheme.onSurface,
              ),
              child: Row(
                children: [
                  SizedBox(width: 40, child: Center(child: leading(option))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label(option),
                      style: TextStyle(
                        fontFamily: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.fontFamily,
                      ),
                    ),
                  ),
                  if (option == selected) const Icon(Icons.check),
                ],
              ),
            ),
          ),
      ],
    );
    if (!mounted) return;
    setState(() => _openScopePicker = null);
    if (value != null) onSelected(value);
  }

  Widget _scopeSelectorCard() {
    void openPicker() => _showScopePicker<FormScopeType>(
      id: 'scope',
      anchorKey: _scopeAnchorKey,
      title: context.l10n.scope,
      options: _availableScopes,
      selected: _selectedScope,
      label: _scopeLabel,
      leading: (scope) => _scopeLeading(scope),
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
    );

    return KeyedSubtree(
      key: const Key('scopeSelectorCard'),
      child: _scopeLocationCard(
        key: _scopeAnchorKey,
        leading: _scopeLeading(_selectedScope, showResolvedValue: true),
        title: _scopeLabel(_selectedScope),
        value: _scopeValue(_selectedScope),
        missingMessage: _scopeMissingMessage(_selectedScope),
        onTap: openPicker,
        trailing: IconButton(
          tooltip: context.l10n.scope,
          onPressed: openPicker,
          icon: Icon(
            _openScopePicker == 'scope'
                ? Icons.arrow_left
                : Icons.arrow_drop_down,
          ),
        ),
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
    void openPicker() => _showScopePicker<CountryUnion>(
      id: 'union',
      anchorKey: _unionAnchorKey,
      title: context.l10n.selectCountryUnion,
      options: CountryUnion.values
          .where(_availableCountryUnions.contains)
          .toList(),
      selected: selected,
      label: _countryUnionLabel,
      leading: (union) => Flag.fromCode(
        _countryUnionFlag(union),
        width: 32,
        height: 22,
        borderRadius: 2,
      ),
      onSelected: (value) {
        setState(() => _selectedCountryUnion = value);
        _saveDraft();
      },
    );

    return KeyedSubtree(
      key: const Key('countryUnionSelectorCard'),
      child: _scopeLocationCard(
        key: _unionAnchorKey,
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
        onTap: openPicker,
        trailing: IconButton(
          tooltip: context.l10n.selectCountryUnion,
          onPressed: openPicker,
          icon: Icon(
            _openScopePicker == 'union'
                ? Icons.arrow_left
                : Icons.arrow_drop_down,
          ),
        ),
      ),
    );
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.delete),
        content: Text(S.of(context).areYouSureYouWantToClearThisDraft),
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
  }

  InfoDialogButton _helpButton() => InfoDialogButton(
    title: widget.title,
    content: _buildTutorialContent(),
    cornerImagePath: 'assets/images/Lemm_teaching.png',
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (widget.importType != null)
            IconButton(
              key: const Key('import_form_json'),
              tooltip: context.l10n.importFormLabel,
              icon: _isImporting
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: Center(
                        child: TriangleLoadingIndicator(
                          size: 18,
                          showFill: false,
                          strokeColor: colors.onSurface,
                        ),
                      ),
                    )
                  : const Icon(Icons.file_upload_outlined),
              onPressed: _isImporting || _isLoading || _isReviewing
                  ? null
                  : _chooseImport,
            ),
          if (widget.appBarActionBuilder != null) ...[
            widget.appBarActionBuilder!(
              _titleController,
              _descriptionController,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (action) {
                if (action == 'reset') {
                  _confirmReset();
                } else {
                  _helpButton().showInfoDialog(context);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'reset',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: colors.onPrimary),
                      const SizedBox(width: 12),
                      Text(
                        context.l10n.resetCreatorDraft,
                        style: TextStyle(color: colors.onPrimary),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'help',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: colors.onPrimary),
                      const SizedBox(width: 12),
                      Text(
                        context.l10n.creatorHelp,
                        style: TextStyle(color: colors.onPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmReset,
            ),
            _helpButton(),
          ],
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 30),
              if (widget.contentActionsBuilder != null)
                widget.contentActionsBuilder!(
                  _titleController,
                  _descriptionController,
                ),
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
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final tag in _selectedTags)
                    InputChip(
                      label: Text(AppTagsHelper.getLocalizedTag(context, tag)),
                      onDeleted: () {
                        setState(() => _selectedTags.remove(tag));
                        _saveDraft();
                      },
                    ),
                  IconButton.outlined(
                    key: const Key('select_tags_button'),
                    tooltip: context.l10n.editTags,
                    onPressed: _selectTags,
                    icon: const Icon(Icons.add),
                  ),
                ],
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
              Text(
                context.l10n.geographicalScope,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
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
                    onPressed: _isLoading || _isReviewing
                        ? null
                        : _handleSubmit,
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
                            context.l10n.reviewPublication,
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
