import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stimmapp/app/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/config/environment.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/data/services/profile_picture_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/providers/profile_picture_provider.dart';
import 'package:stimmapp/core/theme/app_text_styles.dart';

class ChangeProfilePicturePage extends ConsumerStatefulWidget {
  const ChangeProfilePicturePage({super.key});

  @override
  ConsumerState<ChangeProfilePicturePage> createState() =>
      _ChangeProfilePicturePageState();
}

class _ChangeProfilePicturePageState
    extends ConsumerState<ChangeProfilePicturePage> {
  XFile? _imageFile;
  bool _removeExisting = false;
  bool _uploading = false;
  double _progress = 0.0;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() {
      _imageFile = picked;
      _removeExisting = false;
    });
  }

  void _removeImage({required bool hasCurrentImage}) {
    setState(() {
      _imageFile = null;
      _removeExisting = hasCurrentImage;
    });
  }

  Future<void> _uploadAndSave() async {
    final profile = await UserRepository.currentUser();
    if (!mounted) return;
    if (profile?.isGoogleSyncActive == true) {
      showErrorSnackBar(context.l10n.googleSyncLocksPersonalData);
      return;
    }
    if (Environment.isDev) {
      showErrorSnackBar('Profile pictures are disabled in dev mode');
      return;
    }
    if (_imageFile == null && !_removeExisting) {
      showErrorSnackBar(context.l10n.noImageSelected);
      return;
    }

    final user = authService.currentUser;
    if (user == null) {
      showErrorSnackBar(context.l10n.pleaseSignInFirst);
      return;
    }

    final uid = user.uid;

    setState(() {
      _uploading = true;
      _progress = 0;
    });

    try {
      if (_removeExisting) {
        await ProfilePictureService.instance.deleteProfilePicture(uid);
        await ProfilePictureService.instance.setProfileUrl(uid, null);
        try {
          await user.updatePhotoURL(null);
          await user.reload();
        } catch (e) {
          debugPrint('[ChangeProfilePicture] error clearing user photoURL: $e');
        }
        ref.read(profilePictureUrlProvider.notifier).clear();
        if (!mounted) return;
        showSuccessSnackBar(context.l10n.profilePictureUpdated);
        Navigator.of(context).pop();
        return;
      }

      final url = await ProfilePictureService.instance.uploadProfilePicture(
        uid,
        _imageFile!,
        onProgress: (p) {
          if (!mounted) return;
          // throttle UI updates
          if ((p - _progress).abs() > 0.01) {
            setState(() => _progress = p);
          }
        },
      );
      // Publish the persisted URL immediately. Updating Firebase Auth is useful
      // as a fallback, but should not delay the visible in-app update.
      ref.read(profilePictureUrlProvider.notifier).setUrl(url);
      try {
        await user.updatePhotoURL(url);
        await user.reload();
      } catch (e) {
        debugPrint('[ChangeProfilePicture] error updating user photoURL: $e');
      }

      if (!mounted) return;
      showSuccessSnackBar(context.l10n.profilePictureUpdated);
      Navigator.of(context).pop();
    } catch (e, st) {
      debugPrint('[ChangeProfilePicture] upload failed: $e\n$st');
      if (mounted) {
        showErrorSnackBar('${context.l10n.failedToUploadImage}$e');
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUrl =
        ref.watch(profilePictureUrlProvider) ??
        authService.currentUser?.photoURL;

    Widget? preview;
    if (_imageFile != null) {
      if (kIsWeb) {
        preview = Image.network(_imageFile!.path, fit: BoxFit.cover);
      } else {
        preview = Image.file(File(_imageFile!.path), fit: BoxFit.cover);
      }
    } else if (currentUrl != null && !_removeExisting) {
      preview = Image.network(
        currentUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Center(
          child: Text(
            (authService.currentUser?.displayName ?? '').isNotEmpty
                ? authService.currentUser!.displayName![0].toUpperCase()
                : '?',
            style: AppTextStyles.xxlBold,
          ),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.changeProfilePicture)),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Hero(
                        tag: 'profile_picture',
                        child: Container(
                          width: 176,
                          height: 176,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.surfaceContainerHighest,
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child:
                              preview ??
                              Center(
                                child: Text(
                                  (authService.currentUser?.displayName ?? '')
                                          .isNotEmpty
                                      ? authService.currentUser!.displayName![0]
                                            .toUpperCase()
                                      : '?',
                                  style: AppTextStyles.xxlBold,
                                ),
                              ),
                        ),
                      ),
                      if (_uploading)
                        SizedBox.square(
                          dimension: 188,
                          child: CircularProgressIndicator(
                            value: _progress.clamp(0.0, 1.0),
                            strokeWidth: 5,
                            strokeCap: StrokeCap.round,
                            color: colorScheme.primary,
                            backgroundColor: colorScheme.primary.withValues(
                              alpha: 0.16,
                            ),
                            semanticsLabel:
                                context.l10n.uploadingProfilePicture,
                            semanticsValue: '${(_progress * 100).round()}%',
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    color: colorScheme.surfaceContainerLow,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _uploading
                                ? null
                                : () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: Text(context.l10n.selectFromGallery),
                          ),
                          if (!kIsWeb) ...[
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _uploading
                                  ? null
                                  : () => _pickImage(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt_outlined),
                              label: Text(context.l10n.selectFromCamera),
                            ),
                          ],
                          if (!_removeExisting &&
                              (_imageFile != null || currentUrl != null)) ...[
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _uploading
                                  ? null
                                  : () => _removeImage(
                                      hasCurrentImage: currentUrl != null,
                                    ),
                              icon: const Icon(Icons.delete_outline),
                              label: Text(context.l10n.remove),
                              style: TextButton.styleFrom(
                                foregroundColor: colorScheme.error,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (_imageFile != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.imagePreviewDescription,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.descriptionText.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed:
                    _uploading || (_imageFile == null && !_removeExisting)
                    ? null
                    : _uploadAndSave,
                icon: const Icon(Icons.check),
                label: Text(context.l10n.save),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
