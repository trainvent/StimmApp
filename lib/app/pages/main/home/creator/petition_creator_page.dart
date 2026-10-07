import 'dart:typed_data';
import 'package:stimmapp/core/data/models/poll_template.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stimmapp/app/pages/main/home/creator/base_creator_page.dart';
import 'package:stimmapp/app/widgets/snackbar_utils.dart';
import 'package:trainvent_general/trainvent_general.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/constants/petition_tutorial_helper.dart';
import 'package:stimmapp/core/data/models/form_scope.dart';
import 'package:stimmapp/core/data/models/petition.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/petition_repository.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/data/services/content_moderation_service.dart';
import 'package:stimmapp/core/data/services/publishing_quota_service.dart';
import 'package:stimmapp/core/data/services/storage_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/services/analytics_service.dart';

class PetitionCreatorPage extends StatefulWidget {
  const PetitionCreatorPage({super.key, this.initialTemplate});

  final PollTemplate? initialTemplate;

  @override
  State<PetitionCreatorPage> createState() => _PetitionCreatorPageState();
}

class _PetitionCreatorPageState extends State<PetitionCreatorPage> {
  XFile? _imageFile;
  String? _templateImageUrl;
  UserProfile? _user;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _templateImageUrl = widget.initialTemplate?.imageUrl;
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
    }
  }

  Future<bool> _createPetition({
    required String title,
    required String description,
    required List<String> tags,
    required FormScope scope,
    required int durationDays,
    required bool openUntilClosed,
  }) async {
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      showErrorSnackBar(context.l10n.pleaseSignInFirst);
      return false;
    }

    if (ContentModerationService.instance.containsObjectionableContent(
      <String?>[title, description],
    )) {
      showErrorSnackBar(context.l10n.removeAbusiveLanguageBeforePublishing);
      return false;
    }

    try {
      String? imageUrl = _templateImageUrl;
      if (_imageFile != null) {
        imageUrl = await _uploadImageForUser(currentUser.uid);
        if (imageUrl == null) {
          return false;
        }
      }

      final now = DateTime.now();
      final petition = Petition(
        id: '',
        title: title,
        description: description,
        tags: tags,
        signatureCount: 0,
        createdBy: currentUser.uid,
        createdAt: now,
        expiresAt: openUntilClosed
            ? null
            : now.add(Duration(days: durationDays)),
        status: IConst.active,
        scope: scope,
        imageUrl: imageUrl,
      );

      List<Petition> matchedTitles = await PetitionRepository.create()
          .list(query: petition.title, status: "active")
          .first;
      String matchedTitle = matchedTitles.isNotEmpty
          ? matchedTitles.first.title
          : '';
      if (matchedTitle.isNotEmpty && matchedTitle == petition.title) {
        if (mounted) showErrorSnackBar(context.l10n.petitionTitleInUseAlready);
        return false;
      }

      await PublishingQuotaService.instance.ensureCanCreatePetition();

      final petitionId = await PetitionRepository.create().createPetition(
        petition,
      );
      await AnalyticsService.instance.logPetitionCreated(
        scopeType: scope.firestoreType,
        hasImage: imageUrl != null,
      );

      if (mounted) {
        showSuccessSnackBar(context.l10n.createdPetition + petitionId);
        Navigator.of(context).pop();
      }
      return true;
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
    }
    return false;
  }

  Widget _imagePreview() {
    if (_imageFile != null) {
      return FutureBuilder<Uint8List>(
        future: _imageFile!.readAsBytes(),
        builder: (context, snapshot) => snapshot.hasData
            ? Image.memory(snapshot.data!)
            : const Center(child: TriangleLoadingIndicator()),
      );
    }
    if (_templateImageUrl != null) {
      return Image.network(
        _templateImageUrl!,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : const Center(child: TriangleLoadingIndicator()),
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image_outlined),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return BaseCreatorPage(
      initialTemplate: widget.initialTemplate,
      importType: 'petition',
      title: context.l10n.createPetition,
      tutorialSteps: PetitionTutorialHelper.getSteps(context),
      onSubmit: _createPetition,
      onResetAdditionalFields: () => setState(() {
        _imageFile = null;
        _templateImageUrl = null;
      }),
      previewContentBuilder: (_) => _imagePreview(),
      additionalTopFields: [
        if (_imageFile != null || _templateImageUrl != null)
          Stack(
            children: [
              _imagePreview(),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filled(
                  tooltip: context.l10n.remove,
                  onPressed: () => setState(() {
                    _imageFile = null;
                    _templateImageUrl = null;
                  }),
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          )
        else if (_user?.isPro == true)
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.add_a_photo),
            label: Text(context.l10n.addImage),
          ),
        if (_user?.isPro == true || _templateImageUrl != null)
          const SizedBox(height: 20),
      ],
    );
  }
}
