import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stimmapp/app/mobile/pages/main/home/creator/base_creator_page.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/app/mobile/widgets/triangle_loading_indicator.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/constants/petition_tutorial_helper.dart';
import 'package:stimmapp/core/data/models/petition.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/petition_repository.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/data/services/content_moderation_service.dart';
import 'package:stimmapp/core/data/services/publishing_quota_service.dart';
import 'package:stimmapp/core/data/services/storage_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

class PetitionCreatorPage extends StatefulWidget {
  const PetitionCreatorPage({super.key});

  @override
  State<PetitionCreatorPage> createState() => _PetitionCreatorPageState();
}

class _PetitionCreatorPageState extends State<PetitionCreatorPage> {
  XFile? _imageFile;
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

  Future<void> _createPetition({
    required String title,
    required String description,
    required List<String> tags,
    required String scopeType,
    String? scopeCountryCode,
    String? scopeStateOrRegion,
    String? scopeCity,
    required int durationDays,
  }) async {
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      showErrorSnackBar(context.l10n.pleaseSignInFirst);
      return;
    }

    if (ContentModerationService.instance.containsObjectionableContent(
      <String?>[title, description],
    )) {
      showErrorSnackBar(
        'Please remove abusive or objectionable language before publishing.',
      );
      return;
    }

    try {
      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await _uploadImageForUser(currentUser.uid);
        if (imageUrl == null) {
          return;
        }
      }

      final userProfile = await UserRepository.create().getById(
        currentUser.uid,
      );
      final resolvedCountryCode =
          scopeCountryCode?.toUpperCase() ??
          userProfile?.countryCode?.toUpperCase() ??
          (userProfile?.supportsStateScope == true ? 'DE' : null);

      final now = DateTime.now();
      final petition = Petition(
        id: '',
        title: title,
        description: description,
        tags: tags,
        signatureCount: 0,
        createdBy: currentUser.uid,
        createdAt: now,
        expiresAt: now.add(Duration(days: durationDays)),
        status: IConst.active,
        scopeType: scopeType,
        countryCode: resolvedCountryCode,
        stateOrRegion: scopeStateOrRegion,
        city: scopeCity,
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
        return;
      }

      await PublishingQuotaService.instance.incrementPetition();

      final petitionId = await PetitionRepository.create().createPetition(
        petition,
      );

      if (mounted) {
        showSuccessSnackBar(context.l10n.createdPetition + petitionId);
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseCreatorPage(
      title: context.l10n.createPetition,
      tutorialSteps: PetitionTutorialHelper.getSteps(context),
      onSubmit: _createPetition,
      additionalTopFields: [
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
                return const TriangleLoadingIndicator();
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
      ],
    );
  }
}
