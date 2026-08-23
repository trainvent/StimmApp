import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:intl/intl.dart';
import 'package:stimmapp/app/pages/main/admin/admin_dashboard_page.dart';
import 'package:stimmapp/app/pages/main/groups/groups_overview_page.dart';
import 'package:stimmapp/app/pages/main/profile/list/blocked_users_page.dart';
import 'package:stimmapp/app/pages/main/profile/list/export_profile_page.dart';
import 'package:stimmapp/app/pages/main/profile/inbox_page.dart';
import 'package:stimmapp/app/pages/main/profile/list/publications_page.dart';
import 'package:stimmapp/app/pages/main/profile/pid_verification_page.dart';
import 'package:stimmapp/app/pages/main/profile/profile_settings/change_living_address_page.dart';
import 'package:stimmapp/app/pages/main/profile/profile_settings/change_email_page.dart';
import 'package:stimmapp/app/pages/main/profile/profile_settings/change_password_page.dart';
import 'package:stimmapp/app/pages/main/profile/profile_settings/change_profile_picture_page.dart';
import 'package:stimmapp/app/pages/main/profile/profile_settings/connect_email_login_dialog.dart';
import 'package:stimmapp/app/pages/main/profile/profile_settings/synchronization_page.dart';
import 'package:stimmapp/app/pages/main/profile/profile_settings/update_profile_field_page.dart';
import 'package:stimmapp/app/pages/main/profile/list/user_history_page.dart';
import 'package:stimmapp/app/pages/main/profile/list/privacy_page.dart';
import 'package:stimmapp/app/scaffolds/app_padding_scaffold.dart';
import 'package:stimmapp/app/widgets/hero_widget.dart';
import 'package:stimmapp/app/widgets/neon_padding_widget.dart';
import 'package:stimmapp/app/widgets/pointing_list_tile.dart';
import 'package:stimmapp/app/widgets/selection_notifier_dialog.dart';
import 'package:stimmapp/app/widgets/snackbar_utils.dart';
import 'package:trainvent_general/trainvent_general.dart';
import 'package:stimmapp/core/constants/integration_test_constants.dart';
import 'package:stimmapp/core/data/models/poll_group.dart';
import 'package:stimmapp/core/data/repositories/poll_group_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/functions/google_account_links.dart';
import 'package:stimmapp/core/providers/auth_provider.dart';
import 'package:stimmapp/core/services/analytics_service.dart';
import 'package:stimmapp/core/services/purchases_service.dart';
import 'package:stimmapp/core/theme/app_text_styles.dart';
import 'package:stimmapp/generated/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../scaffolds/app_bar_scaffold.dart';
import 'list/delete_account_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({
    super.key,
    this.settingsPageBuilder,
    this.settingsRouteIsBelow = false,
  });

  final WidgetBuilder? settingsPageBuilder;
  final bool settingsRouteIsBelow;

  String _fullName(String? givenName, String? surname) {
    return [
      givenName?.trim(),
      surname?.trim(),
    ].whereType<String>().where((part) => part.isNotEmpty).join(' ');
  }

  void _openNameEditor(
    BuildContext context, {
    required String? givenName,
    required String? surname,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(context.l10n.editGivenName),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UpdateProfileFieldPage(
                      field: EditableProfileField.givenName,
                      initialValue: givenName,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: Text(context.l10n.editSurname),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UpdateProfileFieldPage(
                      field: EditableProfileField.surname,
                      initialValue: surname,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openGoogleProfile(BuildContext context, String? email) async {
    final opened = await openGoogleProfile(email);
    if (context.mounted && !opened) {
      showErrorSnackBar(context.l10n.couldNotOpenLink);
    }
  }

  Future<void> _openManageSubscriptions(BuildContext context) async {
    final managementUri = await PurchasesService.instance.getManagementUri();
    if (!context.mounted) {
      return;
    }
    if (managementUri != null) {
      final ok = await launchUrl(
        managementUri,
        mode: LaunchMode.externalApplication,
      );
      if (!ok) {
        showErrorSnackBar(S.current.error);
      }
      return;
    }

    if (kIsWeb) {
      final notifier = ValueNotifier<String?>(null);
      await showDialog(
        context: context,
        builder: (context) => SelectionNotifierDialog<String>(
          notifier: notifier,
          title: 'Select Payment Provider',
          options: const ['Google Play'],
          optionLabel: (context, option) => option,
          onConfirm: (selected) async {
            if (selected == 'Google Play') {
              final uri = Uri.parse(
                'https://play.google.com/store/account/subscriptions',
              );
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }
          },
        ),
      );
    } else {
      final Uri uri;
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        uri = Uri.parse('https://apps.apple.com/account/subscriptions');
      } else {
        uri = Uri.parse('https://play.google.com/store/account/subscriptions');
      }
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        showErrorSnackBar(S.current.error);
      }
    }
  }

  String? _providerEmail(User? user, String providerId) {
    for (final provider in user?.providerData ?? const <UserInfo>[]) {
      if (provider.providerId != providerId) continue;
      final email = provider.email?.trim();
      if (email?.isNotEmpty == true) return email;
    }
    return null;
  }

  String? _accountEmail(User? user) {
    final directEmail = user?.email?.trim();
    if (directEmail?.isNotEmpty == true) return directEmail;
    for (final provider in user?.providerData ?? const <UserInfo>[]) {
      final email = provider.email?.trim();
      if (email?.isNotEmpty == true) return email;
    }
    return null;
  }

  bool _isProviderLinked(User? user, String providerId) {
    return user?.providerData.any(
          (provider) => provider.providerId == providerId,
        ) ??
        false;
  }

  Future<void> _connectEmail(
    BuildContext context,
    WidgetRef ref,
    User? user,
  ) async {
    final email = _accountEmail(user);
    if (email == null) {
      showErrorSnackBar(context.l10n.error);
      return;
    }
    final password = await showDialog<String>(
      context: context,
      builder: (_) => ConnectEmailLoginDialog(email: email),
    );
    if (password == null || !context.mounted) return;
    await _linkProvider(
      context,
      ref,
      () => ref.read(authServiceProvider).linkEmailPassword(password: password),
    );
  }

  Future<void> _connectGoogle(BuildContext context, WidgetRef ref) {
    return _linkProvider(
      context,
      ref,
      ref.read(authServiceProvider).linkGoogleProvider,
    );
  }

  Future<void> _connectApple(BuildContext context, WidgetRef ref) {
    return _linkProvider(
      context,
      ref,
      ref.read(authServiceProvider).linkAppleProvider,
    );
  }

  Future<void> _linkProvider(
    BuildContext context,
    WidgetRef ref,
    Future<UserCredential> Function() link,
  ) async {
    try {
      await link();
      ref.invalidate(authStateProvider);
      if (context.mounted) {
        showSuccessSnackBar(context.l10n.signInMethodConnected);
      }
    } on AuthException catch (error) {
      if (const {
        'google-sign-in-cancelled',
        'apple-sign-in-cancelled',
      }.contains(error.code)) {
        return;
      }
      if (context.mounted) {
        final methodBelongsToAnotherAccount = const {
          'account-exists-with-different-credential',
          'credential-already-in-use',
          'email-already-in-use',
        }.contains(error.code);
        showErrorSnackBar(
          methodBelongsToAnotherAccount
              ? context.l10n.signInMethodAlreadyUsed
              : error.message ?? context.l10n.error,
        );
      }
    } catch (error, stackTrace) {
      await showInternalDifficultiesSnackBar(error, stackTrace);
    }
  }

  Future<void> _logout(BuildContext context) async {
    // Keep stable handles before signing out. The auth-state listener can
    // replace the authenticated widget tree while these futures are pending.
    final navigator = Navigator.of(context);
    final successMessage = S.of(context).loggedOutSuccessfully;
    FocusManager.instance.primaryFocus?.unfocus();

    try {
      await authService.signOut();
      if (navigator.mounted) {
        navigator.popUntil((route) => route.isFirst);
      }
      showSuccessSnackBar(successMessage);
    } on AuthException catch (e) {
      showErrorSnackBar(e.message);
    }
  }

  void _openSettings(BuildContext context) {
    if (settingsRouteIsBelow && Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }

    final pageBuilder = settingsPageBuilder;
    if (pageBuilder == null) {
      return;
    }

    Navigator.pushReplacement(context, MaterialPageRoute(builder: pageBuilder));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAuthService = ref.watch(authServiceProvider);
    final currentUser =
        ref.watch(currentUserProvider) ?? profileAuthService.currentUser;
    final hasPasswordProvider = _isProviderLinked(
      currentUser,
      EmailAuthProvider.PROVIDER_ID,
    );
    final hasGoogleProvider = _isProviderLinked(
      currentUser,
      GoogleAuthProvider.PROVIDER_ID,
    );
    final hasAppleProvider = _isProviderLinked(
      currentUser,
      AppleAuthProvider.PROVIDER_ID,
    );
    final emailProviderEmail = _providerEmail(
      currentUser,
      EmailAuthProvider.PROVIDER_ID,
    );
    final googleProviderEmail = _providerEmail(
      currentUser,
      GoogleAuthProvider.PROVIDER_ID,
    );
    final appleProviderEmail = _providerEmail(
      currentUser,
      AppleAuthProvider.PROVIDER_ID,
    );
    final profileState = ref.watch(userProfileProvider);

    return AppBarScaffold(
      title: context.l10n.myProfile,
      actions: [
        StreamBuilder<List<PollGroupAccessNotification>>(
          stream: currentUser == null
              ? null
              : PollGroupRepository.create().watchNotifications(
                  currentUser.uid,
                ),
          builder: (context, snapshot) {
            final pendingCount =
                (snapshot.data ?? const <PollGroupAccessNotification>[])
                    .where((item) => item.countsAsUnread)
                    .length;
            return Badge.count(
              offset: const Offset(-5, 5),
              count: pendingCount,
              isLabelVisible: pendingCount > 0,
              child: IconButton(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const InboxPage()));
                },
                icon: const Icon(Icons.notifications_none),
              ),
            );
          },
        ),
        if (settingsRouteIsBelow || settingsPageBuilder != null)
          IconButton(
            onPressed: () => _openSettings(context),
            icon: const Icon(Icons.settings),
            tooltip: context.l10n.settings,
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: AppPaddingScaffold(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10.0),
            profileState.when(
              loading: () => const Center(child: TriangleLoadingIndicator()),
              error: (error, _) {
                debugPrint('ProfilePage: failed to load user profile: $error');
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  showInternalDifficultiesSnackBar(error);
                });
                return Text(context.l10n.error);
              },
              data: (userProfile) {
                if (userProfile == null) {
                  return Text(context.l10n.userNotFound);
                }
                final dateFormat = DateFormat('yyyy-MM-dd');

                return Column(
                  children: [
                    NeonPaddingWidget(
                      isCentered: true,
                      child: Column(
                        children: [
                          Theme(
                            data: Theme.of(
                              context,
                            ).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              controlAffinity: ListTileControlAffinity.leading,
                              trailing: const SizedBox(width: 24),
                              title: HeroWidget(
                                key: keys.profilePage.heroWidget,
                                nextPage: userProfile.isGoogleSyncActive == true
                                    ? null
                                    : const ChangeProfilePicturePage(),
                              ),
                              children: [
                                if (userProfile.supportsStateScope)
                                  _buildDetailTile(
                                    context,
                                    context.l10n.state,
                                    userProfile.state,
                                  ),
                                _buildDetailTile(
                                  context,
                                  context.l10n.town,
                                  userProfile.town,
                                ),
                                _buildDetailTile(
                                  context,
                                  context.l10n.dateOfBirth,
                                  userProfile.dateOfBirth != null
                                      ? dateFormat.format(
                                          userProfile.dateOfBirth!,
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildDetailTile(
                            context,
                            context.l10n.name,
                            _fullName(
                              userProfile.givenName,
                              userProfile.surname,
                            ),
                            hideWhenEmpty: false,
                            onTap: userProfile.isGoogleSyncActive == true
                                ? null
                                : () => _openNameEditor(
                                    context,
                                    givenName: userProfile.givenName,
                                    surname: userProfile.surname,
                                  ),
                          ),
                          _buildDetailTile(
                            key: keys.profilePage.verifiedListTile,
                            context,
                            'Verified',
                            userProfile.isVerified == true ? 'Yes' : 'No',
                            leading: Icon(
                              userProfile.isVerified == true
                                  ? Icons.verified_rounded
                                  : Icons.verified_outlined,
                              color: userProfile.isVerified == true
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PidVerificationPage(
                                    reverify: userProfile.isVerified == true,
                                  ),
                                ),
                              );
                            },
                          ),
                          _buildDetailTile(
                            context,
                            context.l10n.address,
                            userProfile.address,
                            onTap: userProfile.isGoogleSyncActive == true
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ChangeLivingAddressPage(),
                                      ),
                                    );
                                  },
                          ),
                          _buildDetailTile(
                            key: keys.profilePage.changeUserNameListTile,
                            context,
                            context.l10n.nickname,
                            userProfile.displayName,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UpdateProfileFieldPage(
                                    field: EditableProfileField.username,
                                    initialValue: userProfile.displayName,
                                  ),
                                ),
                              );
                            },
                          ),

                          _buildDetailTile(
                            key: keys.profilePage.manageSubscriptionsListTile,
                            context,
                            context.l10n.proMember,
                            userProfile.isPro == true
                                ? context.l10n.yes
                                : context.l10n.no,
                            onTap: () async {
                              if (userProfile.isPro == true) {
                                await _openManageSubscriptions(context);
                                return;
                              }
                              final uid = authService.currentUser?.uid;
                              await PurchasesService.instance.syncAppUser(uid);
                              await PurchasesService.instance
                                  .refreshCustomerInfo();
                              if (!context.mounted) {
                                return;
                              }
                              await AnalyticsService.instance.logPaywallOpened(
                                'profile',
                              );
                              if (!context.mounted) {
                                return;
                              }
                              final success = await PurchasesService.instance
                                  .presentPaywall(
                                    context: context,
                                    source: 'profile',
                                  );
                              await AnalyticsService.instance.logPaywallResult(
                                source: 'profile',
                                success: success,
                              );
                              if (!success && context.mounted) {
                                showErrorSnackBar(
                                  context.l10n.couldNotOpenPaywall,
                                );
                              }
                            },
                          ),
                          //TODO: route to verificationPage once Ausweisapp Client is in place
                          if (userProfile.isAdmin) ...[
                            const SizedBox(height: 20.0),
                            PointingListTile(
                              key: keys.profilePage.adminDashboardListTile,
                              leading: const Icon(
                                Icons.admin_panel_settings,
                                color: Colors.amber,
                              ),
                              title: Text(context.l10n.adminInterface),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AdminDashboardPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                          _buildDetailTile(
                            key: keys.profilePage.changeEmailListTile,
                            context,
                            context.l10n.email,
                            hasPasswordProvider
                                ? emailProviderEmail ??
                                      _accountEmail(currentUser)
                                : context.l10n.notConnected,
                            hideWhenEmpty: false,
                            leading: const Icon(Icons.email_outlined),
                            onTap: hasPasswordProvider
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ChangeEmailPage(),
                                      ),
                                    );
                                  }
                                : () =>
                                      _connectEmail(context, ref, currentUser),
                          ),
                          _buildDetailTile(
                            context,
                            context.l10n.googleAccount,
                            hasGoogleProvider
                                ? googleProviderEmail ?? context.l10n.connected
                                : context.l10n.notConnected,
                            hideWhenEmpty: false,
                            leading: const Icon(FontAwesome5.google, size: 18),
                            onTap: hasGoogleProvider
                                ? () => _openGoogleProfile(
                                    context,
                                    googleProviderEmail,
                                  )
                                : () => _connectGoogle(context, ref),
                          ),
                          _buildDetailTile(
                            context,
                            context.l10n.appleAccount,
                            hasAppleProvider
                                ? appleProviderEmail ?? context.l10n.connected
                                : context.l10n.notConnected,
                            hideWhenEmpty: false,
                            leading: const Icon(FontAwesome5.apple, size: 19),
                            onTap: hasAppleProvider
                                ? null
                                : () => _connectApple(context, ref),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20.0),
            // avatar display: use service notifier (updates after upload)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  _buildSettingsSectionHeader(
                    context,
                    context.l10n.activityAndContent,
                    topPadding: 0,
                  ),
                  PointingListTile(
                    key: keys.profilePage.userHistoryPageListTile,
                    title: Text(context.l10n.activityHistory),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return const UserHistoryPage();
                          },
                        ),
                      );
                    },
                  ),

                  PointingListTile(
                    key: keys.profilePage.publicationsListTile,
                    title: Text(context.l10n.publications),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PublicationsPage(),
                        ),
                      );
                    },
                  ),
                  PointingListTile(
                    title: Text(context.l10n.myGroups),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GroupsOverviewPage(),
                        ),
                      );
                    },
                  ),
                  _buildSettingsSectionHeader(
                    context,
                    context.l10n.privacyAndData,
                  ),
                  PointingListTile(
                    key: keys.profilePage.blockedUsersListTile,
                    title: Text(context.l10n.blockedUsers),
                    onTap: currentUser == null
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    BlockedUsersPage(userId: currentUser.uid),
                              ),
                            );
                          },
                  ),
                  PointingListTile(
                    title: Text(context.l10n.privacy),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacyPage(),
                        ),
                      );
                    },
                  ),

                  // if (!kIsWeb)
                  //   PointingListTile(
                  //     title: const Text('Test Crash'),
                  //     onTap: () {
                  //       throw Exception('Test Crash');
                  //     },
                  //   ),
                  PointingListTile(
                    title: Text(context.l10n.exportAccountData),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ExportProfilePage(),
                        ),
                      );
                    },
                  ),
                  if (hasGoogleProvider)
                    PointingListTile(
                      key: const Key('synchronizationListTile'),
                      title: Text(context.l10n.synchronization),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SynchronizationPage(),
                          ),
                        );
                      },
                    ),
                  _buildSettingsSectionHeader(
                    context,
                    context.l10n.accountAndSecurity,
                  ),
                  if (hasPasswordProvider)
                    PointingListTile(
                      key: keys.profilePage.changePasswordListTile,
                      title: Text(context.l10n.changePassword),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return ChangePasswordPage();
                            },
                          ),
                        );
                      },
                    ),
                  PointingListTile(
                    key: keys.profilePage.logoutListTile,
                    title: Text(context.l10n.logout, style: AppTextStyles.red),
                    trailing: const SizedBox.shrink(),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) {
                          return AlertDialog(
                            title: Text(dialogContext.l10n.logout),
                            content: Text(
                              dialogContext.l10n.areYouSureYouWantToLogout,
                              style: AppTextStyles.m,
                            ),
                            actions: [
                              FilledButton(
                                key: keys.profilePage.confirmLogoutButton,
                                onPressed: () {
                                  // Pop the dialog before calling logout.
                                  Navigator.pop(dialogContext);
                                  _logout(context);
                                },
                                child: Text(dialogContext.l10n.logout),
                              ),
                              TextButton(
                                key: keys.profilePage.cancelLogoutButton,
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                },
                                child: Text(dialogContext.l10n.cancel),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),

                  PointingListTile(
                    key: keys.profilePage.deleteAccountListTile,
                    title: Text(
                      context.l10n.deleteMyAccount,
                      style: AppTextStyles.red,
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) {
                          return AlertDialog(
                            title: Text(dialogContext.l10n.deleteAccount),
                            content: Text(
                              dialogContext
                                  .l10n
                                  .areYouSureYouWantToDeleteYourAccount,
                              style: AppTextStyles.m,
                            ),
                            actions: [
                              FilledButton(
                                key: keys.profilePage.confirmDeleteButton,
                                onPressed: () {
                                  // Pop the dialog before calling logout.
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const DeleteAccountPage(),
                                    ),
                                  );
                                },
                                child: Text(dialogContext.l10n.confirm),
                              ),
                              TextButton(
                                key: keys.profilePage.cancelDeleteButton,
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                },
                                child: Text(dialogContext.l10n.cancel),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20.0),
          ],
        ),
      ),
    );
  }
}

Widget _buildSettingsSectionHeader(
  BuildContext context,
  String title, {
  double topPadding = 24,
}) {
  return Padding(
    padding: EdgeInsets.fromLTRB(16, topPadding, 16, 6),
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

Widget _buildDetailTile(
  BuildContext context,
  String label,
  String? value, {
  Key? key,
  VoidCallback? onTap,
  Widget? leading,
  Widget? trailing,
  bool hideWhenEmpty = true,
}) {
  final displayValue = value?.trim() ?? '';
  if (hideWhenEmpty && displayValue.isEmpty) {
    return const SizedBox.shrink();
  }
  return ListTile(
    key: key,
    title: Text(label, style: AppTextStyles.descriptionText),
    subtitle: Text(
      displayValue.isEmpty ? '—' : displayValue,
      style: AppTextStyles.mBold,
    ),
    dense: true,
    leading: leading,
    onTap: onTap,
    trailing:
        trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
  );
}
