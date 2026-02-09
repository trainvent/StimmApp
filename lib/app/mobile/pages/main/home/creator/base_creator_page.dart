import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/app/mobile/widgets/tag_selector.dart';
import 'package:stimmapp/core/constants/app_limits.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/generated/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

class BaseCreatorPage extends StatefulWidget {
  const BaseCreatorPage({
    super.key,
    required this.title,
    required this.tutorialSteps,
    required this.sourceUrl,
    required this.onSubmit,
    this.additionalTopFields,
    this.additionalBottomFields,
  });

  final String title;
  final List<dynamic> tutorialSteps; // Can be String or PollTutorialStep
  final String sourceUrl;
  final Future<void> Function({
    required String title,
    required String description,
    required List<String> tags,
    required bool isStateDependent,
  }) onSubmit;
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
      );
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
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final step = widget.tutorialSteps[index];
                          if (step is String) {
                            // Petition style (simple bullets)
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: Text(step, style: Theme.of(context).textTheme.bodyMedium),
                                ),
                              ],
                            );
                          } else {
                            // Poll style (Title + Description object)
                            // Assuming dynamic access or we define a common interface/type
                            // For now, let's assume it has title and description properties
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(step.title, style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 4),
                                  Text(step.description, style: Theme.of(context).textTheme.bodyMedium),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium,
                          children: [
                            TextSpan(
                              text: S.of(context).source,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const TextSpan(text: ': '),
                            TextSpan(
                              text: widget.sourceUrl,
                              style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () async {
                                  final url = Uri.parse(widget.sourceUrl);
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url);
                                  }
                                },
                            ),
                          ],
                        ),
                      ),
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
                  width: screenWidth / 3, // 1/3 of screen width
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
              if (widget.additionalTopFields != null) ...widget.additionalTopFields!,
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
              Text(context.l10n.tags, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TagSelector(
                selectedTags: _selectedTags,
                onChanged: (newTags) {
                  setState(() {
                    _selectedTags = newTags;
                  });
                },
              ),
              const SizedBox(height: 10),
              CheckboxListTile(
                title: Text(context.l10n.stateDependent),
                value: _isStateDependent,
                onChanged: (newValue) {
                  setState(() {
                    _isStateDependent = newValue!;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 10),
              if (widget.additionalBottomFields != null) ...widget.additionalBottomFields!,
              Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
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
