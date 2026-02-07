import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/app/mobile/widgets/tag_selector.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/constants/petition_tutorial_helper.dart';
import 'package:stimmapp/core/data/models/petition.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/petition_repository.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/data/services/publishing_quota_service.dart';
import 'package:stimmapp/core/data/services/storage_service.dart';
import 'package:stimmapp/generated/l10n.dart';
import 'package:url_launcher/url_launcher.dart';


class PetitionCreatorPage extends StatefulWidget {
  const PetitionCreatorPage({super.key});

  @override
  State<PetitionCreatorPage> createState() => _PetitionCreatorPageState();
}

class _PetitionCreatorPageState extends State<PetitionCreatorPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<String> _selectedTags = [];
  final _repository = PetitionRepository.create();
  bool _isLoading = false;
  bool _isStateDependent = false;
  XFile? _imageFile;
  bool _isUploading = false;
  UserProfile? _user;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    final currentUser = authService.currentUser;
    if (currentUser != null) {
      final user = await UserRepository.create()
          .watchById(currentUser.uid)
          .first;
      if (mounted) {
        setState(() {
          _user = user;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  Future<String?> _uploadImageForUser(String uid) async {
    if (_imageFile == null) {
      return null;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final storage = StorageService(FirebaseStorage.instance);
      final fileName = '${DateTime.now().toIso8601String()}.jpg';
      final bytes = await _imageFile!.readAsBytes();
      final downloadUrl = await storage.uploadUserBytes(
        uid,
        'petition_images/$fileName',
        bytes,
        contentType: 'image/jpeg',
      );
      return downloadUrl;
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context.l10n.errorUploadingImage + e.toString());
      }
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _createPetition(FormState form) async {
    if (!form.validate()) {
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

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl;
      if (_imageFile != null) {
        // upload to the authenticated user's area so storage.rules allow the write
        imageUrl = await _uploadImageForUser(currentUser.uid);
        if (imageUrl == null) {
          // Error is already shown in _uploadImageForUser
          return;
        }
      }

      String? state;
      if (_isStateDependent) {
        final userProfile = await UserRepository.create().getById(
          currentUser.uid,
        );
        state = userProfile?.state;
      }

      // Create the petition object
      final now = DateTime.now();
      final petition = Petition(
        id: '', // Will be set by Firestore
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        tags: _selectedTags,
        signatureCount: 0,
        createdBy: currentUser.uid,
        createdAt: now,
        expiresAt: now.add(const Duration(days: 28)),
        status: IConst.active,
        state: state,
        imageUrl: imageUrl,
      );

      List<Petition> matchedTitles = await _repository
          .list(query: petition.title, status: "active")
          .first;
      String matchedTitle = matchedTitles.isNotEmpty
          ? matchedTitles.first.title
          : '';
      if (matchedTitle.isNotEmpty && matchedTitle == petition.title) {
        showErrorSnackBar('petition title in use already');
        return;
      }

      // Enforce daily quota atomically
      await PublishingQuotaService.instance.incrementPetition();

      // Save to Firestore using toFirestore
      final petitionId = await _repository.createPetition(petition);

      if (mounted) {
        showSuccessSnackBar(context.l10n.createdPetition + petitionId);

        // Clear form
        _titleController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedTags = [];
          _imageFile = null;
        });
        form.reset();
        Navigator.of(context).pop();
      }
    } on StateError catch (e) {
      if (mounted) {
        if (e.message == 'petition_daily_limit_reached') {
          showErrorSnackBar(context.l10n.dailyCreateLimitReached);
        } else {
          showErrorSnackBar(context.l10n.errorCreatingPetition + e.toString());
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context.l10n.errorCreatingPetition + e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showInfoDialog() {
    final steps = PetitionTutorialHelper.getSteps(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(S.of(context).petitionGuidelines),
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
                    itemCount: steps.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(steps[index], style: Theme.of(context).textTheme.bodyMedium),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Source: ',
                          style: DefaultTextStyle.of(context).style,
                        ),
                        TextSpan(
                          text: 'https://epetitionen.bundestag.de/epet/peteinreichen.html',
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              final url = Uri.parse('https://epetitionen.bundestag.de/epet/peteinreichen.html');
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.createPetition),
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
          child: ListView(
            children: [
              const SizedBox(height: 30),
              if (_user?.isPro == true) ...[
                if (_imageFile != null)
                  FutureBuilder<List<int>>(
                    future: _imageFile!.readAsBytes().then(
                      (bytes) => List<int>.from(bytes),
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Image.memory(Uint8List.fromList(snapshot.data!));
                      }
                      return const CircularProgressIndicator();
                    },
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.add_a_photo),
                    label: Text(context.l10n.addImage),
                  ),
                const SizedBox(height: 20),
              ],
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: context.l10n.title,
                  hintText: context.l10n.enterTitle,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.l10n.titleRequired;
                  }
                  if (value.trim().length < 5) {
                    return context.l10n.titleTooShort;
                  }
                  return null;
                },
                maxLength: 100,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: context.l10n.description,
                  hintText: context.l10n.enterDescription,
                  border: OutlineInputBorder(),
                ),
                maxLines: 8,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.l10n.descriptionRequired;
                  }
                  if (value.trim().length < 20) {
                    return context.l10n.descriptionTooShort;
                  }
                  return null;
                },
                maxLength: 1000,
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
              Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: _isLoading || _isUploading
                        ? null
                        : () {
                            final form = Form.of(context);
                            _createPetition(form);
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading || _isUploading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            context.l10n.createPetition,
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
