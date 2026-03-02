import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/app/mobile/widgets/tag_selector.dart';
import 'package:stimmapp/app/mobile/widgets/triangle_loading_indicator.dart';
import 'package:stimmapp/core/constants/app_limits.dart';
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
    this.additionalBottomFields,
  });

  final String title;
  final List<dynamic> tutorialSteps; // Can be String or PollTutorialStep
  final Future<void> Function({
    required String title,
    required String description,
    required List<String> tags,
    required bool isStateDependent,
    required int durationDays,
  })
  onSubmit;
  final List<Widget>? additionalTopFields;
  final List<Widget>? additionalBottomFields;

  @override
  State<BaseCreatorPage> createState() => _BaseCreatorPageState();
}

class _BaseCreatorPageState extends State<BaseCreatorPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<String> _selectedTags = [];
  bool _isStateDependent = false;
  bool _isLoading = false;
  int _durationDays = 28; // Default duration

  @override
  void initState() {
    super.initState();
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

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draftTitle = prefs.getString('${_draftKey}_title');
    final draftDescription = prefs.getString('${_draftKey}_description');
    final draftTags = prefs.getStringList('${_draftKey}_tags');
    final draftStateDependent = prefs.getBool('${_draftKey}_stateDependent');
    final draftDuration = prefs.getInt('${_draftKey}_duration');

    if (mounted) {
      setState(() {
        if (draftTitle != null) _titleController.text = draftTitle;
        if (draftDescription != null) {
          _descriptionController.text = draftDescription;
        }
        if (draftTags != null) _selectedTags = draftTags;
        if (draftStateDependent != null) {
          _isStateDependent = draftStateDependent;
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
    await prefs.setBool('${_draftKey}_stateDependent', _isStateDependent);
    await prefs.setInt('${_draftKey}_duration', _durationDays);
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_draftKey}_title');
    await prefs.remove('${_draftKey}_description');
    await prefs.remove('${_draftKey}_tags');
    await prefs.remove('${_draftKey}_stateDependent');
    await prefs.remove('${_draftKey}_duration');
  }

  Future<void> _resetForm() async {
    await _clearDraft();
    setState(() {
      _titleController.clear();
      _descriptionController.clear();
      _selectedTags = [];
      _isStateDependent = false;
      _durationDays = 28;
    });
  }

  Future<void> _handleSubmit() async {
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

    setState(() => _isLoading = true);

    try {
      await widget.onSubmit(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        tags: _selectedTags,
        isStateDependent: _isStateDependent,
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
        final screenWidth = MediaQuery.of(context).size.width;
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
              child: IgnorePointer(
                child: Image.asset(
                  'assets/images/form_guy_teaching.png',
                  width: screenWidth / 4, // 1/3 of screen width
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        );
      },
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
              CheckboxListTile(
                title: Text(context.l10n.stateDependent),
                value: _isStateDependent,
                onChanged: (newValue) {
                  setState(() {
                    _isStateDependent = newValue!;
                  });
                  _saveDraft();
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
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
